set more off
capture clear
capture log close
cls

log using log/mk-gss-2006-2014-fill-in-and-recoded.log, replace

********************************************************************************
*** Create temporary data files 
********************************************************************************

tempfile gss_2006_panel gss_2008_panel gss_2010_panel ///
  gss_2008_all_vars gss_2010_all_vars gss_2012_all_vars gss_2014_all_vars
  

* GSS 2006-2010 panel 
use ../gss-from-norc/GSS_panel06w123_R6a.dta, clear
rename *, lower
save `gss_2006_panel'

* GSS 2008-2012 panel 
use ../gss-from-norc/GSS_panel08w123_R6.dta, clear
gen samptype = 2008
rename *, lower
save `gss_2008_panel'

* GSS 2010-2014 panel
use ../gss-from-norc/GSS_panel2010w123_R6.dta, clear
rename *, lower
save `gss_2010_panel'

* GSS 2008 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/gss2008crosspanel_R6.dta, clear
rename *, lower
save `gss_2008_all_vars'

* GSS 2010 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/GSS2010merged_R8.dta, clear
rename *, lower
save `gss_2010_all_vars'

* GSS 2012 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/GSS2012merged_r10.dta, clear
rename *, lower
save `gss_2012_all_vars'

* GSS 2014 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/gss2014merged_r10.dta, clear
rename *, lower
save `gss_2014_all_vars'

********************************************************************************
*** Append the panel records to the cross-sectional records, yielding a long
***   dataset
********************************************************************************

*** use panel data to extract unique respondent id variable
/* Note:  Need to harmonize the unique individual id because each 
   merged cross-sectional plus panel respondent file has a unique  
   structure of id variables */
   
foreach year in 2006 2008 2010  {
	use `gss_`year'_panel', clear 
		if `year'==2006 {
			* keep id and weight as well as variables asked only in panel survey
			keep id_* wtpan* conterrr_* immaffus_* payenvir_* panstat_* 		
			label values panstat_*  .
			replace panstat_3 = . if panstat_3==0
			}
		else if `year'!=2006 {
			keep id_* wtpan* panstat_* 
			}
	gen samptype = `year'
	tempfile panel_id_`year'
	save `panel_id_`year''
}

*** subset only the follow-up panel respondents from the merged yearly files
***   of cross-sectional records and follow-up records

local vars_to_keep year id samptype ///
    dateintv lngthinv mode spaneng ///
	feeused coop comprend intage intsex intethn intyrs ///
	region size xnorcsiz ///
	age sex degree spdeg wordsum marital uscitzn born parborn relig ///
	hispanic race eth1 eth2 eth3 ethnic racecen1 racecen2 racecen3 ///	
	occ10 spocc10 realinc realrinc dwelown class ///
	wrkslf wrkstat spwrkslf spwrksta numemps   ///
	reg16 incom16 family16 padeg madeg paocc10 maocc10 pawrkslf mawrkslf 

tempfile panel_resp_in_2008 panel_resp_in_2010 panel_resp_in_2012 ///
	panel_resp_in_2014

* 2008
use `gss_2008_all_vars', clear
keep `vars_to_keep' wt*
keep if samptype==2006
rename id id_2
merge 1:m id_2 using `panel_id_2006'
gen panelid = id_1
drop if _merge==2
drop _merge id_3 id_1 
rename id_2 id
_strip_labels *
foreach var of varlist _all {
	label var `var' ""
}
drop wtpan wtnrpan /* equal wtpan12 and wtpannr12 and not in the other files */
save `panel_resp_in_2008', replace

* 2010
use `gss_2010_all_vars', clear
keep `vars_to_keep' wt*
keep if samptype==2006 | samptype==2008
rename id id_3
merge 1:m id_3 using `panel_id_2006'
gen panelid = id_1 if samptype==2006
drop if _merge==2
drop id_2 id_1 _merge 
rename id_3 id_2
merge 1:m id_2 using `panel_id_2008', update
replace panelid= id_1 if samptype==2008
drop if _merge==2
drop _merge id_1 id_3 
rename id_2 id
_strip_labels *
foreach var of varlist _all {
	label var `var' ""
}
save `panel_resp_in_2010', replace

* 2012
use `gss_2012_all_vars', clear
keep `vars_to_keep' wt*
keep if samptype==2008 | samptype==2010
rename id id_3 
merge 1:m id_3 using `panel_id_2008'
gen panelid = id_1 if samptype==2008
drop if _merge==2
drop id_2 id_1 _merge 
rename id_3 id_2
merge 1:m id_2 using `panel_id_2010', update
replace panelid= id_1 if samptype==2010
drop if _merge==2 
drop _merge id_1 id_3 
rename id_2 id
_strip_labels *
foreach var of varlist _all {
	label var `var' ""
}
save `panel_resp_in_2012', replace

* 2014
use `gss_2014_all_vars', clear
keep `vars_to_keep' wt*
keep if samptype==2010 
rename id id_3
merge 1:m id_3 using `panel_id_2010'
gen panelid = id_1  if samptype==2010
drop if _merge==2
drop id_2 id_1 _merge 
rename id_3 id
_strip_labels *
foreach var of varlist _all {
	label var `var' ""
}
save `panel_resp_in_2014', replace

*** append to the cumulative file
use data/gss-2006-2014-with-panel-fill-in.dta, clear

* indicator for sample type (panel sample named by year sampled)
replace samptype = 2008 if year==2008
replace samptype = 2010 if year==2010

* merge unique individual id varaiable for panel respondents
rename id id_1
merge m:1 id_1 samptype using `panel_id_2006'
gen panelid = id_1 if samptype==2006
drop _merge id_2 id_3 
merge m:1 id_1 samptype using `panel_id_2008', update
replace panelid = id_1 if samptype==2008
drop _merge id_2 id_3 
merge m:1 id_1 samptype using `panel_id_2010', update
replace panelid = id_1 if samptype==2010
drop _merge id_2 id_3 
rename id_1 id

append using `panel_resp_in_2008'
append using `panel_resp_in_2010'
append using `panel_resp_in_2012'
append using `panel_resp_in_2014'

tab year
bys year: tab samptype
bys samptype: tab panelid
bys samptype year: sum wtss wtssnr wtpan*

*** create variables that identify panel respondents and panel waves
gen panelr = (panelid!=.)
tab panelr samptype, miss

summ year
tab panelr samptype, miss
tab year if samptype == .

tempvar samptype_str panelid_str panelid_temp
tostring samptype, gen(samptype_str)  
tostring panelid, gen(panelid_str)
gen panelid_temp= samptype_str + panelid_str if samptype_str !="."
destring panelid_temp, replace
drop panelid
rename panelid_temp panelid
sort samptype panelid 

gen panelwave = 1
replace panelwave = 2 if year==samptype+2
replace panelwave = 3 if year==samptype+4

tab samptype panelwave, miss
bys year:  tab samptype panelwave, miss

********************************************************************************
*** Recode data, by including sections of code
********************************************************************************

*** make list of _pl stubs (from the cross-sectional file)
preserve
keep *_pl
rename *_pl *
quietly ds
local pl_stubs  `r(varlist)'
macro list _pl_stubs
restore

clonevar sex_origpl = sex_pl

*** fill-in _pl in 2nd and 3rd wave panels 
foreach var in `pl_stubs' {	
	sort samptype panelid panelwave
	replace `var'_pl = `var' if !missing(`var') & panelwave>=2
	replace `var'_pl = `var'_pl[_n-1] if `var'_pl >=. & panelwave==2
	replace `var'_pl = `var'_pl[_n-2] if `var'_pl >=. & panelwave==3
}

tab sex_origpl sex_pl , m
bys year panelwave:  tab sex_origpl sex_pl, m

drop sex_origpl wtssall-wtcombnr

*** Recode race and class variables
include code/recode-race.do
include code/recode-egp-class.do

********************************************************************************
*** Save the dataset
********************************************************************************

preserve

*** cumulative year file with only the cross-sectional records

* exclude merged panel respondents
tab year
keep if samptype >= . | year == samptype
tab year

save data/gss-2006-2014-fill-in-and-recoded.dta, replace

restore

*** cumulative year file with panel records merged 
save data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta, replace

********************************************************************************
*** Subset the panel respondents and save as a dataset
********************************************************************************

*** long form data *************************************************************

*** keep only the panel respondents
keep if panelr==1

*** drop variables that were not asked
qui ds 
local varlist `r(varlist)'

foreach var in `varlist' {
	qui sum `var'
		if r(N)==0 | r(Var)==0 {
			drop `var'
		} 
}

sort samptype panelid panelwave
order samptype panelid panelwave, first
 
save data/gss-panel-allyears-recoded-long.dta, replace

log close
