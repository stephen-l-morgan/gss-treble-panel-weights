set more off
capture clear
capture log close
cls

log using log/append-and-merge-imputed-datasets.log, replace

********************************************************************************
*** Define tempfiles and list of variables for analysis
********************************************************************************

tempfile indicvars unimputed

local vars_to_keep ///
	age sex racehisp5 degree realinc marital evercitzn region ///
	wordsum intage intsex intethn intyrs lngthinv daysint mode feeused coop ///
	comprend spaneng dwelown
	
********************************************************************************
*** Combine the original unimputed data with the imputed data records from R
********************************************************************************

*** import id, weight, and follow-up status from merged file

use data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta, clear

keep if panelr==1

sort panelid panelwave
order panelid panelwave

egen w1 = total(panelwave==1) if !missing(panelid), by(panelid)
egen w2 = total(panelwave==2) if !missing(panelid), by(panelid)
egen w3 = total(panelwave==3) if !missing(panelid), by(panelid)

keep samptype panelid panstat_2 panstat_3 w2 w3 panelwave wt*

save `indicvars'	

*** data generated prior to imputation

use data/gss-panel-vars-to-impute.dta, clear

gen m = 0

save `unimputed'

*** merge id, weight and follow-up status

use data/gss-panel-vars-imputed-rf.dta, clear
rename flag m
	
append using `unimputed'
merge m:m samptype panelid panelwave using `indicvars' 
drop _merge

*** append the unimputed dataset

replace panelwave = panelwave_x if panelwave == .
drop panelwave_x panelwave_y
mi import flong, m(m) id(panelid panelwave) imputed(`vars_to_keep') clear
mi describe

********************************************************************************
*** Generate attrition outcome indicators and recode predictors for models
********************************************************************************

* broadcast panstat and attrition variables across imputed datasets

bys samptype: summ panelid panstat_2 panstat_3 w2 w3

bysort panelid (panstat_2): replace panstat_2 = panstat_2[1]
bysort panelid (panstat_3): replace panstat_3 = panstat_3[1] 
bysort panelid (w2): replace w2 = w2[1]
bysort panelid (w3): replace w3 = w3[1] 

bys samptype: summ panelid panstat_2 panstat_3 w2 w3

sort panelid panelwave

*** make indicator for attriters by 2nd or 3rd wave

gen attr_w23 = (w2==0 | w3==0) // Attriton either by 2nd or 3rd wave

*** define panel out-of-scope status

/* Note: 1 repondendent was "selected, but not eligible and not reinterviewd,"
		 and we consider this respondent to be out-of-scope */

gen outsc_w2 = ((panstat_2 >= 31 & panstat_2 <= 33) | panstat_2==3) ///
													if !missing(panstat_2) 
gen outsc_w3 = ((panstat_3 >= 31 & panstat_3 <= 33)) ///
													if !missing(panstat_3) 
gen outsc_w23 = (outsc_w2 == 1 | outsc_w3 == 1) 

bys outsc_w23: tab panstat_2 panstat_3 if m > 0, m nol

*** recoding of age and citizenship status

orthpoly age, gen(age_o*) deg(3) // orthogonal polynominal of age

gen borncitz = .
replace borncitz= 1 if born == 1
replace borncitz= 2 if born == 2 & evercitzn == 1
replace borncitz= 3 if born == 2 & evercitzn == 0
tab borncitz, m

*** assign variable and value labels

do code/variable-and-value-labels.do

order panelid _mi_id panelwave id year samptype m wtss-w3 attr_w23-borncitz
sort panelid panelwave m 

* recode missing and broadcast weights across imputed datasets

foreach var in wtss wtssnr wtpan12 wtpan123 wtpannr12 wtpannr123 {
	replace `var' = . if `var' >= .
	bysort panelid panelwave (`var'): replace `var' = `var'[1]
}

sort panelid panelwave m

********************************************************************************
*** Save data file with unimputed and imputed data records
********************************************************************************

compress
save data/gss-panel-2006-2014-imputed-recoded.dta, replace

log close
