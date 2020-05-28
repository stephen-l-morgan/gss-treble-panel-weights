set more off
capture clear
capture log close
cls

log using log/create-panel-attrition-weights.log, replace

use data/gss-panel-2006-2014-attrition-pr.dta, replace

********************************************************************************
*** Merge the estimated attrition probabilities with the panel respondents 
***   from the original data
********************************************************************************

use data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta, clear
keep if panelr==1
summ wt*
drop wt*

merge 1:1 panelid panelwave using data/gss-panel-2006-2014-attrition-pr.dta
drop _merge panelid_str panelr samptype_str
order samptype year panelwave panelid  
order wtss-pr_shr_2010_insc, after(panelsamp)
sort panelid panelwave

********************************************************************************
*** Check scaling of NORC weights, as well as rescaled weights created to
***   estimate attrition probabilities
********************************************************************************

*** Set up by broadcasting base year weights across all waves

local wt_vars wtss wtssnr wtssnr_rs pool_wt wtpannr123

*** Add labels

la var wtss "NORC base weight, sum to yearly N for cross-section sample" 
la var wtssnr "NORC wtss base weight with NR adjustment"
la var wtpan12 "NORC base weight, panel waves 1 and 2"
la var wtpan123 "NORC base weight, all panel waves"
la var wtpannr12 "NORC base weight, panel waves 1 and 2, NR adjustment"
la var wtpannr123 "NORC base weight, all panel waves, NR adjustment"
la var wtssnr_rs ///
  "Rescaled NORC base weight with NR, sum to base-year N for each panel"
la var pool_wt ///
  "Rescaled NORC base weight with NR, sum to base-year N for all panels"

*** Broadcast weights

summ panelid wtss-attr_w23
desc panelid wtss-attr_w23

 foreach var in  `wt_vars' {
	quietly bysort panelid (`var'): replace `var' = `var'[1]
}

sort panelid panelwave
summ panelid wtss-attr_w23

*** Examine scaling of weights

bys samptype: summ panelid wtss-attr_w23 if panelwave==1

*** Confirm that wtpannr123 sums to n for non-attriters in each year

forval i = 2006(2)2010 {
	display " "
	display "Year: `i'"
	summ wtpannr123 if samptype == `i' & panelwave == 1, detail
	display " "
	display "Number of respondents: `r(N)'"
	display "Sum of weights: `r(sum)'"
}

********************************************************************************
*** Tabulation
********************************************************************************

*** Table 1 for report

tab samptype panelwave
bys samptype: tab w3 if panelwave == 1 [aw = wtssnr]
mean w3 if panelwave == 1 [pw = wtssnr], over(samptype)

*** Table 2 for report

tab samptype panelwave if outsc_w23 == 0
bys samptype: tab w3 if panelwave == 1 & outsc_w23==0 [aw = wtssnr]
mean w3 [pw=wtssnr] if panelwave == 1  & outsc_w23 == 0, over(samptype)

********************************************************************************
*** Construct new weights
********************************************************************************

**** weights for all panels combined

*** macros
local pooled pr_all pr_all_insc 
local pooled_stem pr_all 


foreach var in `pooled_stem' {

	qui gen tmp_invp_`var' = (1/(1 - `var')) if attr_w23==0
	qui gen tmp_invp_`var'_insc = (1/(1 - `var'_insc)) if attr_w23==0
	qui gen invp_`var' = .
	qui gen invp_`var'_insc = .
	qui gen wt_`var' = .	
	qui gen wt_`var'_insc = .	

	forval i = 2006(2)2010 {

	display " "	
		display "############################"
		display "Panel Base Year: `i'"
		display "############################"
		display " "

		qui summ attr_w23 if samptype == `i' & panelwave == 1 [aw = wtssnr_rs]
		display "Panel N: `r(N)'"
		scalar panel_N = `r(N)'
		
		qui summ attr_w23 if samptype == `i' & panelwave == 1 & ///
			outsc_w23 == 0 [aw = wtssnr_rs]
		display "Panel N in scope: `r(N)'"
		scalar panel_N_insc = `r(N)'
		
		qui summ tmp_invp_`var' if samptype == `i' &  ///
			panelwave == 1 & attr_w23 == 0 [aw = wtpannr123]
		display "Unadjusted sum of inverse prob of remaining: `r(sum)'"
		scalar sum_invp = `r(sum)'

		qui summ tmp_invp_`var'_insc if samptype == `i' &  ///
			panelwave == 1 & attr_w23 == 0 & outsc_w23 == 0 [aw = wtpannr123]
		display "Unadjusted sum of inverse prob of remaining (and in scope): `r(sum)'"
		scalar sum_invp_insc = `r(sum)'

		qui replace invp_`var' = (panel_N/sum_invp)*tmp_invp_`var' ///
			if samptype == `i' & attr_w23 == 0

		qui replace invp_`var'_insc = ///
			(panel_N_insc/sum_invp_insc)*tmp_invp_`var'_insc ///
			if samptype == `i' & attr_w23 == 0 & outsc_w23 == 0

		qui replace wt_`var' = invp_`var' * wtpannr123 ///
			if samptype == `i' & attr_w23 == 0

		qui replace wt_`var'_insc = invp_`var'_insc * wtpannr123 ///
			if samptype == `i' & attr_w23 == 0 & outsc_w23 == 0
		
		display ""
		display "After adjustments to inverse probs, descriptives weighted by wtpannr:"
		display ""
		
		summ invp_`var' if samptype==`i' & attr_w23 == 0 & ///
			panelwave == 1 [aw = wtpannr123]
		display "Sum of inverse prob of remaining: `r(sum)'"

		summ invp_`var'_insc if samptype==`i' & attr_w23 == 0 & ///
			outsc_w23 == 0 & panelwave == 1  [aw = wtpannr123]
		display "Sum of inverse prob of remaining (and in scope): `r(sum)'"

	
		summ wt_`var' if samptype==`i' & attr_w23 == 0 & ///
			panelwave == 1 [aw = wtpannr123], d

		summ wt_`var'_insc if samptype==`i' & attr_w23 == 0 & ///
			outsc_w23 == 0 & panelwave == 1  [aw = wtpannr123], d
	}
	drop tmp_invp_`var' tmp_invp_`var'_insc
}

**** panel-specific weights

*** macros

local single_panels pr_2006 pr_2008 pr_2010 ///
					pr_shr_2006 pr_shr_2008 pr_shr_2010

local single_panels_insc pr_2006_insc pr_2008_insc pr_2010_insc ///
					pr_shr_2006_insc pr_shr_2008_insc pr_shr_2010_insc 

foreach var in `single_panels' {

	qui gen tmp_invp_`var' = (1/(1 - `var')) if attr_w23==0
	qui gen invp_`var' = .
	qui gen wt_`var' = .	

	display " "	
	display "##############################################"
	display "Probability:  `var'"
	display "##############################################"
	display " "

	qui summ `var' if panelwave == 1 [aw = wtssnr_rs]
	display "Panel N: `r(N)'"
	scalar panel_N = `r(N)'

	qui summ tmp_invp_`var'  ///
		if panelwave == 1 & attr_w23 == 0 [aw = wtpannr123]
	display "Unadjusted sum of inverse prob of remaining: `r(sum)'"
	scalar sum_invp = `r(sum)'

	qui replace invp_`var' = (panel_N/sum_invp)*tmp_invp_`var' ///
		if attr_w23 == 0

	qui replace wt_`var' = invp_`var' * wtpannr123 ///
		if attr_w23 == 0

	display ""
	display "After adjustments to inverse probs, descriptives weighted by wtpannr:"
	display ""
		
	summ invp_`var' if attr_w23 == 0 & ///
			panelwave == 1 [aw = wtpannr123]
	display "Sum of inverse prob of remaining: `r(sum)'"

	summ wt_`var' if attr_w23 == 0 & ///
			panelwave == 1 [aw = wtpannr123], d

	drop tmp_invp_`var'
}
				
foreach var in `single_panels_insc' {

	qui gen tmp_invp_`var' = (1/(1 - `var')) if attr_w23==0
	qui gen invp_`var' = .
	qui gen wt_`var' = .	

	display " "	
	display "##############################################"
	display "Probability:  `var'"
	display "##############################################"
	display " "
		
	qui summ `var' if panelwave == 1 & outsc_w23 == 0 [aw = wtssnr_rs]
	display "Panel N in scope: `r(N)'"
	scalar panel_N = `r(N)'
		
	qui summ tmp_invp_`var'  ///
			if panelwave == 1 & attr_w23 == 0 & outsc_w23 == 0 [aw = wtpannr123]
	display "Unadjusted sum of inverse prob of remaining (and in scope): `r(sum)'"
	scalar sum_invp = `r(sum)'

	qui replace invp_`var' = (panel_N/sum_invp)*tmp_invp_`var' ///
		if attr_w23 == 0 & outsc_w23 == 0

	qui replace wt_`var' = invp_`var' * wtpannr123 ///
		if attr_w23 == 0 & outsc_w23 == 0

	display ""
	display "After adjustments to inverse probs, descriptives weighted by wtpannr:"
	display ""

	summ invp_`var' if attr_w23 == 0 & ///
		outsc_w23 == 0 & panelwave == 1  [aw = wtpannr123]
	display "Sum of inverse prob of remaining (and in scope): `r(sum)'"

	summ wt_`var' if attr_w23 == 0 & ///
		outsc_w23 == 0 & panelwave == 1  [aw = wtpannr123], d

	drop tmp_invp_`var'
}

sort panelid panelwave

summ panelid wtss-attr_w23 wt*
bys samptype: summ panelid wtss-attr_w23 wt*

*** Rename and combine single-year panel weights

rename invp_pr_* invp_*
rename wt_pr_* wt_*

summ panelid wtss-attr_w23 invp* wt*

clonevar wt_pooled = wt_all
clonevar wt_pooled_insc = wt_all_insc

gen wt_no_pooling = .
gen wt_no_pooling_insc = .
gen wt_shrunken = .
gen wt_shrunken_insc = .

forval i = 2006(2)2010 {
	replace wt_no_pooling 		= wt_`i' if samptype == `i'
	replace wt_no_pooling_insc  = wt_`i'_insc if samptype == `i'
	replace wt_shrunken 		= wt_shr_`i' if samptype == `i'
	replace wt_shrunken_insc 	= wt_shr_`i'_insc if samptype == `i'
}

summ panelid wtss-attr_w23 wt*

*** labels *********************************************************************
la var wt_all "All panels pooled"
la var wt_all_insc "All panels pooled (in scope all waves)"
la var wt_2006 "2006 panel"
la var wt_2008 "2008 panel"
la var wt_2010 "2010 panel"
la var wt_2006_insc "2006 panel (in scope all waves)"
la var wt_2008_insc "2008 panel (in scope all waves)"
la var wt_2010_insc "2010 panel (in scope all waves)"
la var wt_shr_2006 "2006 panel (shrunk to pooled)"
la var wt_shr_2008 "2008 panel (shrunk to pooled)"
la var wt_shr_2010 "2010 panel (shrunk to pooled)"
la var wt_shr_2006_insc "2006 panel (shrunk to pooled, in scope all waves)"
la var wt_shr_2008_insc "2008 panel (shrunk to pooled, in scope all waves)"
la var wt_shr_2010_insc "2010 panel (shrunk to pooled, in scope all waves)"
la var wt_pooled "Estimated with panels pooled"
la var wt_pooled_insc "Estimated with panels pooled (in scope all waves)"
la var wt_no_pooling "Estimated separately by panel"
la var wt_no_pooling_insc "Estimated separately by panel (in scope all waves)"
la var wt_shrunken "Shrunk to pooled estimates"
la var wt_shrunken_insc "Shrunk to pooled estimates (in scope all waves)"

********************************************************************************
*** Save dataset with weights
********************************************************************************

sort panelid panelwave
compress
save data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, replace

log close
