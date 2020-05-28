set more off
capture clear
capture log close
cls

log using log/summarize-probabilities-and-weights.log, replace

*** To run this file, the following line must be run once to install estout: 
***    ssc install estout, replace

use data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, clear

********************************************************************************
*** Calculate summary statistics of estimated probabilities and inverses
********************************************************************************

*** Macros

#delimit ;
local pr_list1 pr_2006 pr_shr_2006 
			   pr_2008 pr_shr_2008 
			   pr_2010 pr_shr_2010 
			   pr_2006_insc pr_shr_2006_insc
               pr_2008_insc pr_shr_2008_insc 
			   pr_2010_insc pr_shr_2010_insc ;
			   
local pr_list1 pr_2006 pr_shr_2006 pr_2008 pr_shr_2008
               pr_2010 pr_shr_2010 pr_2006_insc pr_shr_2006_insc
               pr_2008_insc pr_shr_2008_insc pr_2010_insc pr_shr_2010_insc ;
 
local pr_list2 pr_all 
			   pr_2006 pr_shr_2006 
			   pr_2008 pr_shr_2008 
			   pr_2010 pr_shr_2010 
			   pr_all_insc 
			   pr_2006_insc pr_shr_2006_insc
               pr_2008_insc pr_shr_2008_insc 
			   pr_2010_insc pr_shr_2010_insc ;

local invp_list invp_all 
				invp_2006 invp_shr_2006 
				invp_2008 invp_shr_2008 
				invp_2010 invp_shr_2010 
			    invp_all_insc 
			    invp_2006_insc invp_shr_2006_insc 
			    invp_2008_insc invp_shr_2008_insc 
			    invp_2010_insc invp_shr_2010_insc ;

#delimit cr

*** Create log inverse probabilities
foreach var of varlist `invp_list' {

	gen l`var' = ln(`var')

}

#delimit ;

local linvp_list linvp_all 
				 linvp_2006 linvp_shr_2006 
				 linvp_2008 linvp_shr_2008 
				 linvp_2010 linvp_shr_2010 
			     linvp_all_insc 
			     linvp_2006_insc linvp_shr_2006_insc 
			     linvp_2008_insc linvp_shr_2008_insc 
			     linvp_2010_insc linvp_shr_2010_insc ;

#delimit cr

** summary statistics of probabilities and inverse probabilities
estpost sum `pr_list2' [aw = wtssnr_rs] if panelwave == 1
esttab, ///
  cells("count mean sd min max") ///
  noobs label
mat pr_summ = r(coefs)

estpost sum `pr_list2' [aw = wtpannr123] if panelwave == 1 & attr_w23 == 0
esttab, ///
  cells("count mean sd min max") ///
  noobs label
mat pr_summ_pnl = r(coefs)

estpost sum `invp_list' `linvp_list' [aw = wtpannr123] if panelwave == 1 & attr_w23 == 0
esttab, ///
  cells("count mean sd min max") ///
  noobs label
mat invp_summ = r(coefs)

pwcorr `pr_list2' [aw = wtssnr_rs] if panelwave == 1, obs 
mat corrmat_pr = r(C)

pwcorr `pr_list2' [aw = wtpannr123] if panelwave == 1  & attr_w23 == 0, obs 
mat corrmat_pr_pnl = r(C)

pwcorr `invp_list' [aw = wtpannr123] if panelwave == 1  & attr_w23 == 0, obs 
mat corrmat_invp = r(C)

pwcorr `linvp_list' [aw = wtpannr123] if panelwave == 1  & attr_w23 == 0, obs 
mat corrmat_linvp = r(C)

********************************************************************************
*** Write summary statistics of estimated probabilities to excel spreadsheet
********************************************************************************

* summary statistics of the estimated probabilities
putexcel set docs/summary-of-attrition-weights.xlsx, sheet("pr-summ") replace

* assign column labels
putexcel B1 = "N" C1 = "Mean" D1= "SD" E1 = "Min" F1 = "Max"
putexcel A2 = "Non-attriters and attriters"
putexcel A18 = "Non-attriters only"

local row = 3
local rowp2 = 19

foreach var of varlist `pr_list2' {
	
	putexcel A`row' = ("`var'")
	putexcel A`rowp2' = ("`var'")

	local row = `row' + 1
	local rowp2 = `rowp2' + 1
}

* export to excel
putexcel B3 = matrix(pr_summ)
putexcel B19 = matrix(pr_summ_pnl) 

* correlation among the probabilities
putexcel set docs/summary-of-attrition-weights.xlsx, sheet("pr-corr") modify

* assign row labels
putexcel A1 = "Non-attriters and attriters"
putexcel A20 = "Non-attriters only"

local row = 3
local rowp2 = 22

foreach var of varlist `pr_list2' {
	
	putexcel A`row' = ("`var'")
	putexcel A`rowp2' = ("`var'")
	
	local back1 = `row' - 1
	local col : word `back1'  of `c(ALPHA)'
	putexcel `col'2 = ("`var'")
	putexcel `col'21 = ("`var'")

	local row = `row' + 1
	local rowp2 = `rowp2' + 1
	}

* export to excel
putexcel B3 = matrix(corrmat_pr), nformat(number_d2)
putexcel B22 = matrix(corrmat_pr_pnl), nformat(number_d2)

********************************************************************************
*** Write summary statistics of scaled inverse probs to excel spreadsheet
********************************************************************************

* summary statistics of the estimated probabilities
putexcel set docs/summary-of-attrition-weights.xlsx, sheet("invp-summ") modify

* assign column labels
putexcel B1 = "N" C1 = "Mean" D1= "SD" E1 = "Min" F1 = "Max"
putexcel A2 = "Non-attriters only"

local row = 3

foreach var of varlist `invp_list' `linvp_list' {
	
	putexcel A`row' = ("`var'")

	local row = `row' + 1
}

* export to excel
putexcel B3 = matrix(invp_summ)

* correlation among the probabilities
putexcel set docs/summary-of-attrition-weights.xlsx, sheet("invp-corr") modify

* assign row labels
putexcel A1 = "Non-attriters only"

local row = 3

foreach var of varlist `invp_list' {
	
	putexcel A`row' = ("`var'")
	
	local back1 = `row' - 1
	local col : word `back1'  of `c(ALPHA)'
	putexcel `col'2 = ("`var'")

	local row = `row' + 1
	}

local row = 3
local rowp2 = 22

foreach var of varlist `linvp_list' {
	
	putexcel A`rowp2' = ("`var'")
	
	local back1 = `row' - 1
	local col : word `back1'  of `c(ALPHA)'
	putexcel `col'21 = ("`var'")

	local row = `row' + 1
	local rowp2 = `rowp2' + 1
	}

* export to excel
putexcel B3 = matrix(corrmat_invp), nformat(number_d2)
putexcel B22 = matrix(corrmat_linvp), nformat(number_d2)

********************************************************************************
*** Calculate summary statistics of weights
********************************************************************************

local wt_list ///
	wtpannr123 ///
	wt_no_pooling wt_pooled wt_shrunken ///
	wt_no_pooling_insc wt_pooled_insc wt_shrunken_insc

foreach var of varlist `wt_list' {

	gen l`var' = ln(`var')

}

local lwt_list ///
	lwtpannr123 ///
	lwt_no_pooling lwt_pooled lwt_shrunken ///
	lwt_no_pooling_insc lwt_pooled_insc lwt_shrunken_insc

estpost sum `wt_list' `lwt_list' if panelwave==1 & attr_w23==0
esttab, ///
	cells("count mean sd min max") ///
	noobs label
mat wt_summ = r(coefs)

estpost sum `wt_list' `lwt_list' if panelwave==1 & attr_w23==0 [aw = wtpannr123]
esttab, ///
	cells("count mean sd min max") ///
	noobs label
mat wt_summ_wtd = r(coefs)

pwcorr `wt_list' `lwt_list' ///
 if panelwave==1  & attr_w23==0, obs 
mat corrmat_wt = r(C)

pwcorr `wt_list' `lwt_list' ///
  if panelwave==1  & attr_w23==0 [aw = wtpannr123], obs 
mat corrmat_wt_wtd = r(C)
				 
********************************************************************************
*** Write summary statistics of weights to excel spreadsheet
********************************************************************************

* summary statistics of the constructed weights
putexcel set docs/summary-of-attrition-weights.xlsx, ///
  sheet("weights-summ") modify

* assign row labels
putexcel A2 = "Unweighted"
putexcel A22 = "Weighted by wtpannr123"

* assign labels
putexcel C1 = "N" D1 = "Mean" E1 = "SD" F1 = "Min" G1 = "Max"
local row = 3
local rowp2 = 23

foreach var of varlist `wt_list' `lwt_list' {

	qui describe `var'
	local varlabel : var label `var'

	putexcel A`row' = ("`var'")
	putexcel A`rowp2' = ("`var'")
	putexcel B`row' = ("`varlabel'")
	putexcel B`rowp2' = ("`varlabel'")

	local row = `row' + 1
	local rowp2 = `rowp2' + 1
}

* export to excel
putexcel C3 = matrix(wt_summ) 
putexcel C23 = matrix(wt_summ_wtd)

* correlation among the constructed weights
putexcel set docs/summary-of-attrition-weights.xlsx, ///
  sheet("weights-corr") modify 

* assign labels
putexcel A1 = "Unweighted"
putexcel A24 = "Weighted by wtpannr123"

local row = 3
local rowp2 = 26

foreach var of varlist `wt_list' `lwt_list' {

	qui describe `var'
	local varlabel : var label `var'

	putexcel A`row' = ("`var'")
	putexcel A`rowp2' = ("`var'")

	local back1 = `row' - 1
	local col : word `back1'  of `c(ALPHA)'
	putexcel `col'2 = ("`var'")
	putexcel `col'13 = ("`var'")

	local row = `row' + 1
	local rowp2 = `rowp2' + 1
}

* export to excel
putexcel B3 = matrix(corrmat_wt), nformat(number_d2)
putexcel B26 = matrix(corrmat_wt_wtd), nformat(number_d2)

log close
