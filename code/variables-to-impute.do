set more off
capture clear
capture log close
cls

log using log/variables-to-impute.log, replace

use data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta, clear

********************************************************************************
*** Keep only the panel respondents and fix up panel filled in variables
********************************************************************************

keep if panelr==1 // keep only panel respondents, all three waves

*** fill in values for _pl variables in 2nd and 3rd wave based on value for _pl
***   in the 1st wave

//  Note: In the current data setting, '_pl' variables are filled only for the 
//        first wave hence they are missing for the 2nd and 3rd waves. I

foreach var in age sex racehisp born parborn marital degree relig marital ///
	incom16 spdeg madeg padeg family16 reg16 uscitzn realinc realrinc ///
	wordsum dwelown {	
	
		if `var' == age {
		  sort samptype panelid panelwave
		  replace `var'_pl = `var' if !missing(`var') & panelwave >= 2
		  replace `var'_pl = `var'_pl[_n-1] + 2 if `var'_pl >= . & panelwave==2
		  replace `var'_pl = `var'_pl[_n-2] + 4 if `var'_pl >= . & panelwave==3
		  }
		  
		else if `var' != age {
		  sort samptype panelid panelwave
		  replace `var'_pl = `var' if !missing(`var') & panelwave >= 2
		  replace `var'_pl = `var'_pl[_n-1] if `var'_pl >= . & panelwave==2
		  replace `var'_pl = `var'_pl[_n-2] if `var'_pl >= . & panelwave==3
		}
}

********************************************************************************
*** Code selected variables for the analysis
********************************************************************************

*** more detailed classification of U.S born and citizenship status
gen uscitizen = .
replace uscitizen = 1 if born_pl == 1 
replace uscitizen = 2 if born_pl == 2 & (uscitzn_pl == 1 | uscitzn_pl == 3 | ///
									     uscitzn_pl == 4)
replace uscitizen = 3 if born_pl == 2 & uscitzn_pl == 2 
replace uscitizen = 4 if born_pl == 2 & uscitzn_pl >= .
 
bys uscitizen: tab born_pl uscitzn_pl if panelwave == 1, m		
		
la def USCITIZEN 1 "Born in US" 2 "Citizen born outside of US" ///
	3 "Non-citizen Born Outside" 4 "Born outside citizenship unclear"
la val uscitizen USCITIZEN

*** date of interview: convert into days from Jan 1 ****************************
clonevar daysint = dateintv
replace daysint = . if daysint >= .
cap drop  __00*  // drop any temporary variables //
tostring daysint, replace force

* extract only the days
replace daysint = substr(daysint, -2, 2) 
destring daysint, replace

replace daysint = daysint + 31 if dateintv >= 200 & dateintv <= 231
replace daysint = daysint + 59 if dateintv >= 300 & dateintv <= 331
replace daysint = daysint + 90 if dateintv >= 400 & dateintv <= 431
replace daysint = daysint + 120 if dateintv >= 500 & dateintv <= 531
replace daysint = daysint + 151 if dateintv >= 600 & dateintv <= 631
replace daysint = daysint + 181 if dateintv >= 700 & dateintv <= 731
replace daysint = daysint + 212 if dateintv >= 800 & dateintv <= 831
replace daysint = daysint + 243 if dateintv >= 900 & dateintv <= 931
replace daysint = daysint + 273 if dateintv >= 1000 & dateintv <= 1031
replace daysint = daysint + 304 if dateintv >= 1100 & dateintv <= 1131
replace daysint = daysint + 334 if dateintv >= 1200 & dateintv <= 1231

* replace ones where only the month is available (will impute to the 15th)
replace daysint = 15 if daysint==99 & dateintv == 199
replace daysint = 46 if daysint==99 & dateintv == 299
replace daysint = 74 if daysint==99 & dateintv == 399
replace daysint = 105 if daysint==99 & dateintv == 499
replace daysint = 135 if daysint==99 & dateintv == 599
replace daysint = 166 if daysint==99 & dateintv == 699

* replace for leap-day years
forval i = 2008(4)2012 {
	replace daysint= daysint + 1 if year==`i' & dateintv >=300
}

* calculate the first day of interview for all years
gen firstday = .

forval i = 2006(2)2014 {
	sum daysint if year == `i'
	replace firstday = `r(min)' if year == `i'
}

replace daysint = daysint - firstday 

tab daysint

*** log-transformation of income ***********************************************
replace realinc = ln(realinc) 
replace realrinc = ln(realrinc) 

********************************************************************************
*** Select variables to impute, treating variables differently based on whether
***   they are likely to change across waves of the panel
********************************************************************************

//  Note2: We decided to use later observations carried backward as a method for 
//         imputation of missing values when (1) the variable is time-invaraint 
//		   or (2) the variable is not invariant but the respondent is over the 
//         age of 30 (except for income).  This is the fill-in procedure 
//         deployed in prior do files.

* define lists of variables
global id_type_vars id year panelid samptype panelwave 

global interview_vars intage intsex intethn intyrs lngthinv coop comprend ///
		daysint spaneng mode feeused   

global class_vars egp10_11 spegp10_11 paegp10_11 maegp10_11

global back_vars_invariant parborn family16 reg16 incom16 

global pred_vars_invariant age sex racehisp born     

global back_vars_varying relig class spdeg madeg padeg wrkstat   

global pred_vars_varying degree uscitzn realinc realrinc region wordsum ///
		dwelown size xnorcsiz marital

*** interview-related and class variables (do not use _pl versions)

foreach var in $interview_vars $class_vars {

	gen `var'_im = `var'
}

*** time-invariant variables (use _pl version)

foreach var in $back_vars_invariant $pred_vars_invariant  {

	gen `var'_im = `var'_pl 

}

***  mixed, based on age

foreach var in $back_vars_varying $pred_vars_varying  {

	if `var' == realinc | realrinc {
	
		gen `var'_im = `var'
	
	}
		
	else if `var' != realinc | realrinc {

		gen `var'_im = `var'
		replace `var'_im = `var'_pl if age >= 30
		
		}
}

********************************************************************************
*** Recode some final variables
********************************************************************************

*** more detailed coding of race ***********************************************
clonevar racehisp5_im = racehisp_im
recode racehisp5_im 4 = 5
replace racehisp5_im = 4 if asian == 1 & racehisp5 == 5

tab racehisp_im racehisp5_im
drop racehisp racehisp_im racehisp_pl

*** recode citizen variable
bys panelid: egen evercitzn_im = total(uscitzn_pl == 1 | uscitzn_pl == 3 | ///
               uscitzn_pl == 4) 
replace evercitzn_im = 1 if evercitzn_im >= 1 | born_pl == 1

*** recode mode so that na and dk from 2010 onward are classified as missing
tab mode_im year, miss
recode mode_im  8/9 = .
tab mode_im year, miss

********************************************************************************
*** Select variables for final imputation in R; reocde missing values
********************************************************************************
							
*** keep only the variables to impute
keep $id_type_vars *_im

*** replace all missing to soft missing
preserve
keep *_im
quietly ds
local all_im  `r(varlist)'
restore
	
foreach var in `all_im' {

	replace `var' = . if `var' >=. | `var' < 0

	}	
	
sum *	
rename *_im *
bys panelwave: sum *
bys year: sum *
save data/gss-panel-vars-to-impute.dta, replace

outsheet using data/gss-panel-vars-to-impute.csv, comma nolabel replace

log close
