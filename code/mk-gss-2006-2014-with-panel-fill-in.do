set more off
capture clear
capture log close
cls

log using log/mk-gss-2006-2014-with-panel-fill-in.log, replace

********************************************************************************
*** Set threshold to keep/drop years of the GSS cross-sectional cumulative file 
********************************************************************************

local year_from 2006
local year_until 2014

********************************************************************************
*** Create temporary data files
********************************************************************************

tempfile gss_cross_section_raw gss_2006_panel gss_2008_panel gss_2010_panel

* GSS cumulative cross-section
use ../gss-from-norc/GSS7218_R2.dta, clear
save `gss_cross_section_raw'

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

********************************************************************************
*** Define macros for lists of variables that will be used in the analysis 
********************************************************************************

*** variable list for cross-sectional data file
local vars_to_keep year id dateintv lngthinv mode spaneng ///
	feeused coop comprend intage intsex intethn intyrs ///
	region size xnorcsiz ///
	age sex degree spdeg wordsum marital uscitzn born parborn relig ///
	hispanic race eth1 eth2 eth3 ethnic racecen1 racecen2 racecen3 ///	
	occ10 spocc10 realinc realrinc dwelown class ///
	wrkslf wrkstat spwrkslf spwrksta numemps   ///
	reg16 incom16 family16 padeg madeg paocc10 maocc10 pawrkslf mawrkslf 
	 
*** variable list for panel data files
foreach var of local vars_to_keep {
		local vars_to_keep_panel `vars_to_keep_panel' ///
		     `var'_1 `var'_2 `var'_3
}

*** add weight variables to lists
local vars_to_keep wtss wtssnr `vars_to_keep' 
local vars_to_keep_panel samptype wtpan12 wtpan123 wtpannr12 wtpannr123 ///
	`vars_to_keep_panel'
	
*** set aside a list of 'at the time of interview' variables for later use 
***   to structure the fill-in procedure
local int_vars_stubs dateintv lngthinv mode spaneng feeused coop comprend ///
	intage intsex intethn intyrs region size xnorcsiz

macro list _vars_to_keep _vars_to_keep_panel _int_vars_stubs

********************************************************************************
*** Select years and prepare cross-sectional data for later merge
********************************************************************************

use `gss_cross_section_raw', clear
keep `vars_to_keep'
order `vars_to_keep'
order year id
keep if year >= `year_from' & year <= `year_until'
/* Note:  Cross-sectional data from 2012 and 2014 are not needed to estimate
          models that generate weights.  These years are included nonetheless to
		  enable comparisons of follow-up responses to responses from
		  fresh sampels and for other analysis purposes. */
		  
*** create unique id across all years in kept years
qui tostring year,  gen(year_str)
qui tostring id, gen(id_str)
gen yearid=year_str + id_str
destring yearid, replace
drop year_str id_str
order year id yearid
sort yearid

tempfile gss_cross_section_some_years
save `gss_cross_section_some_years'

********************************************************************************
*** Modify panel data, create unique yearid, and remove all labels
********************************************************************************

use `gss_2006_panel', clear
keep `vars_to_keep_panel'
order `vars_to_keep_panel'
gen year = 2006
order year
_strip_labels _all
foreach var of varlist _all {
  label var `var' ""
}
save `gss_2006_panel', replace

use `gss_2008_panel', clear
keep `vars_to_keep_panel'
order `vars_to_keep_panel'
gen year = 2008
order year
_strip_labels _all
foreach var of varlist _all {
  label var `var' ""
}
save `gss_2008_panel', replace

use `gss_2010_panel', clear
keep `vars_to_keep_panel'
order `vars_to_keep_panel'
gen year = 2010
order year
_strip_labels _all
foreach var of varlist _all {
  label var `var' ""
}
save `gss_2010_panel', replace

foreach file in `gss_2006_panel' `gss_2008_panel' `gss_2010_panel' {
  use `file', clear
  tempvar year_str id_str
  rename id_1 id
  drop id_2 id_3      /* because these ids have a different numbering scheme */
  qui tostring year, gen(`year_str')  
  qui tostring id, gen(`id_str')
  gen yearid=`year_str' + `id_str'
  destring yearid, replace
  order year id yearid
  sort yearid
  drop __00*
  save `file', replace 
}

********************************************************************************
*** Run fill in procedure for panels and then merge with cross-seciton
********************************************************************************

local stubs_for_no_fill_in year id ballot samptype wtss wtssnr wtpan12 wtpan123 ///
    wtpannr12 wtpannr123 `int_vars_stubs' 
local stubs_for_fill_in: list vars_to_keep - stubs_for_no_fill_in
macro list _stubs_for_no_fill_in _stubs_for_fill_in

foreach file in `gss_2006_panel' `gss_2008_panel' `gss_2010_panel' {

	use `file', clear

foreach stub in `stubs_for_fill_in' {

	qui clonevar `stub'_pl = `stub'_1
	qui replace `stub'_pl = `stub'_2 if `stub'_1 >= . & `stub'_2 < . 
	qui replace `stub'_pl = `stub'_3 if `stub'_1 >= . & `stub'_2 >= . & ///
	  `stub'_3 < .
	qui gen byte `stub'_fl = .
	qui replace `stub'_fl = 1 if `stub'_1 < . 
	qui replace `stub'_fl = 2 if `stub'_1 >= . & `stub'_2 < . 
	qui replace `stub'_fl = 3 if `stub'_1 >= . & `stub'_2 >= . & `stub'_3 < .

	}
	
  gen panelsamp = 1	
  save `file', replace  
  
  use `gss_cross_section_some_years', replace
  merge 1:1 yearid using `file', nogen update
  save `gss_cross_section_some_years', replace

}

*** adjust age_pl to account for survey-year differences 
replace age_pl = age_pl - 2 if age_fl == 2 
replace age_pl = age_pl - 4 if age_fl == 3

*** final coding to identify panel samples
recode panelsamp . = 0
tab year panelsamp
bys year: tab panelsamp samptype, miss nol
/*  Note:  2006 is unusual in two ways:
     1.  Four ballots, the fourth of which is an add-on with limited variables 
       with 1518 respondents (usually dropped from analysis).
     2.  2000 individuals were subsampled from the first 2992 in the first three  
       ballots to make the panel sample. */

********************************************************************************
*** Sort and keep variables; save panel filled in temporary dataset
********************************************************************************

sort year id yearid
order year id yearid samptype panelsamp wt*
tempfile before_nonpanel_fillin
save `before_nonpanel_fillin'

********************************************************************************
*** Fill in _pl variables for individuals who are not in the panel sample with
***  information from non _pl cross-section variables
***    (Note:  These variables will rarely be used, but we create them anyway.)
********************************************************************************

*** make new list of all _pl variables generated by prior fill-in procedure
use `before_nonpanel_fillin', clear
keep *_pl
rename *_pl *
quietly ds
local pl_stubs  `r(varlist)'

macro list _pl_stubs

*** Replace missing in _pl with non _pl for individuals who are not in the panel
***  sample (and replace _fl with 1 for non panel sample, with the rationale
***  that variables from 'wave 1' are used for the _pl variable, even though
***  no 'waves' exist for these resondents)

use `before_nonpanel_fillin', clear

foreach var in `pl_stubs' {
  qui replace `var'_pl = `var' if panelsamp == 0
  qui replace `var'_fl = 1 if `var' < . & panelsamp == 0
}

********************************************************************************
*** Eliminate panel data in separate vars (can be kept by commenting out)
********************************************************************************

drop *_1 *_2 *_3 

********************************************************************************
*** Save the data
********************************************************************************

compress
cap drop __00* // drop any lingering temporary variables //
save data/gss-2006-2014-with-panel-fill-in.dta, replace

log close
