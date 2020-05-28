set more off
capture clear
capture log close
cls

log using log/export-regression-estimates-to-excel.log, replace

use data/gss-panel-2006-2014-imputed-recoded.dta, clear

// RUN THIS LINE TO INSTALL 'OUTREG2' PROGRAM USED TO EXPORT SUMMARY STATISTICS 
// TO EXCEL AS SPREADSHEETS:
//	  
// ssc install outreg2, replace	 			


********************************************************************************
*** Construct weights from wtssnr for use with panels
********************************************************************************

/* Note: 
			The first rescaling, (`r(N)'/`r(sum)') rescales wtssnr so that it 
			sums to panel size N, which is needed for 2006 because the panel 
			was a subsample of all cross-sectional cases.  
			
			The second rescaling, (1/3)*(6067/`r(sum)'), scales each of the 
			three panel samples so that they contribute 1/3 of the mass of the 
			pooled weight, which downweights the larger panels in 2008 and 
			2010 proportionately. 
			*/
			
gen wtssnr_rs = .
gen pool_wt = .

forval i = 2006(2)2010 {
  gen wtssnr_rs_`i' = .
  gen pool_wt_`i' = .
  qui summ wtssnr if samptype==`i' & panelwave==1 & m==1 
  replace wtssnr_rs_`i' = (`r(N)'/`r(sum)') * wtssnr ///
     if samptype==`i' & panelwave==1 & m==1
  qui summ wtssnr_rs_`i' if samptype==`i' & panelwave==1 & m==1 
  replace pool_wt_`i' = (1/3)*(6067/`r(sum)')* wtssnr_rs_`i' ///
     if samptype==`i' & panelwave==1 & m==1 
  summ wtssnr wtssnr_rs_`i' pool_wt_`i' ///
    if samptype == `i' & panelwave == 1 & m == 1 	
  replace wtssnr_rs = wtssnr_rs_`i' if samptype == `i'
  replace pool_wt = pool_wt_`i' if samptype == `i'
  drop wtssnr_rs_`i' pool_wt_`i'
}

* broadcast weights across imputed datasets and then summarize and reorder
bys samptype: summ wtssnr wtssnr_rs pool_wt
bysort panelid (wtssnr_rs): replace wtssnr_rs = wtssnr_rs[1] if panelwave == 1
bysort panelid (pool_wt): replace pool_wt = pool_wt[1] if panelwave == 1

summ wtssnr wtssnr_rs pool_wt if m == 1
summ wtssnr wtssnr_rs pool_wt

order wtssnr_rs pool_wt, after(wtssnr)
sort panelid panelwave m

********************************************************************************
*** Export regression output to excel (including regression output not used to
***   estimate the probabilities for the weights, such as bivariate models)
********************************************************************************

*** rescale variables to produce coefficients with fewer leading 0's in decimals
summ  lngthinv daysint
replace lngthinv = lngthinv/60
replace daysint = daysint/10
summ intyrs lngthinv daysint

*** Macros
local age_o_vars c.age_o1 c.age_o2 c.age_o3

local vars_for_est  ///
	i.sex i.racehisp5 b1.degree c.realinc i.dwelown i.marital i.borncitz ///
	i.region c.wordsum  c.intage i.intsex i.intethn c.intyrs c.lngthinv ///
	c.daysint i.mode i.feeused i.coop i.comprend i.spaneng 
	
local sample_all "panelwave==1"
local sample_insc "panelwave==1 & outsc_w23==0"
local sample_2006_all "panelwave==1 & samptype==2006"
local sample_2006_insc "panelwave==1 & samptype==2006 & outsc_w23==0"
local sample_2008_all "panelwave==1 & samptype==2008"
local sample_2008_insc "panelwave==1 & samptype==2008 & outsc_w23==0"
local sample_2010_all "panelwave==1 & samptype==2010"
local sample_2010_insc "panelwave==1 & samptype==2010 & outsc_w23==0"

local weight "[pw=wtssnr_rs]"
local pool_weight "[pw=pool_wt]"

local outreg_opt ///
  "noaster adds("Model chi-square", e(chi2), "Degrees of freedom", e(df_m)) stat(coef se) dec(3) paren(se) drop(attr_w23) excel label"

local outreg_opt_mi ///
 "noaster stat(coef se) dec(3) paren(se) drop(attr_w23) excel label"
 

*** Bivariate associations [with margins] **************************************
gen blank = 0
    /*  For j if/elseif control to work properly, need to add a an unused var
        to the list so that it can be skipped over when j=1.  The  variable
		blank is just filled with 0's */
	
* All respondents
local j = 0
foreach var in blank `vars_for_est' {
	local ++j
		if `j' == 1 {
			mi estimate, post: logit attr_w23 `age_o_vars' if `sample_all' ///
				`pool_weight'
			outreg2 using docs/attr-weight-bivariate-all.xls, replace ///
				`outreg_opt_mi'
				forval k = 1/6 {
					logit attr_w23 `age_o_vars' ///
											if `sample_all'  & m ==`k' `weight'
					outreg2 using docs/attr-weight-bivariate-all.xls, ///
									append `outreg_opt' cttop("pooled_all_`k'")
					predict yhat if e(sample)
					margins, dydx(*) post
					outreg2 using docs/attr-weight-bivariate-all.xls, ///
					append `outreg_opt_mi' cttop("AME_pooled_all_`k'")	
					mean yhat `weight'
					mean yhat `weight', over(attr_w23)
					drop yhat
					}
			}

		else if `j' != 1 {
			outreg2: mi estimate, post: logit attr_w23 `var' if `sample_all' ///
				`pool_weight'
				forval k = 1/6 {
					logit attr_w23 `var' ///
											if `sample_all'  & m ==`k' `weight'
					outreg2 using docs/attr-weight-bivariate-all.xls, ///
									append `outreg_opt' cttop("pooled_all_`k'")
					predict yhat if e(sample)
					margins, dydx(*) post
					outreg2 using docs/attr-weight-bivariate-all.xls, ///
					append `outreg_opt_mi' cttop("AME_pooled_all_`k'")	
					mean yhat `weight'
					mean yhat `weight', over(attr_w23)
					drop yhat
					}
			}
}

* Excluding out-of-scope
local j = 0
foreach var in blank `vars_for_est' {
	local ++j
		if `j' == 1 {
			mi estimate, post: logit attr_w23 `age_o_vars' if `sample_insc' ///
				`pool_weight'
			outreg2 using docs/attr-weight-bivariate-insc.xls, replace ///
				`outreg_opt_mi'
				forval k = 1/6 {
					logit attr_w23 `age_o_vars' ///
											if `sample_insc'  & m ==`k' `weight'
					outreg2 using docs/attr-weight-bivariate-insc.xls, ///
									append `outreg_opt' cttop("pooled_insc_`k'")
					predict yhat if e(sample)
					margins, dydx(*) post
					outreg2 using docs/attr-weight-bivariate-insc.xls, ///
					append `outreg_opt_mi' cttop("AME_pooled_insc_`k'")	
					mean yhat `weight'
					mean yhat `weight', over(attr_w23)
					drop yhat
					}
			}

		else if `j' != 1 {
			outreg2: mi estimate, post: logit attr_w23 `var' if `sample_insc' ///
				`pool_weight'
				forval k = 1/6 {
					logit attr_w23 `var' ///
											if `sample_insc'  & m ==`k' `weight'
					outreg2 using docs/attr-weight-bivariate-insc.xls, ///
									append `outreg_opt' cttop("pooled_insc_`k'")
					predict yhat if e(sample)
					margins, dydx(*) post
					outreg2 using docs/attr-weight-bivariate-insc.xls, ///
					append `outreg_opt_mi' cttop("AME_pooled_insc_`k'")	
					mean yhat `weight'
					mean yhat `weight', over(attr_w23)
					drop yhat
					}
			}
}

**** Multivariate association: All panels pooled *******************************
* All respondents
forval i = 1/6 {
	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
												if `sample_all' `pool_weight'														
		outreg2 using docs/attr-weight-multivariate-pooled-all.xls, ///
					replace `outreg_opt_mi' cttop("pooled_all_mi") 
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_all'  & m ==`i' `pool_weight'
		outreg2 using docs/attr-weight-multivariate-pooled-all.xls, ///
									append `outreg_opt' cttop("pooled_all_`i'")										
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-pooled-all.xls, ///
		append `outreg_opt_mi' cttop("AME_pooled_all_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}

	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_all'  & m ==`i' `pool_weight'
		est store pooled_all_`i'
		outreg2 using docs/attr-weight-multivariate-pooled-all.xls, ///
									append `outreg_opt' cttop("pooled_all_`i'")									
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-pooled-all.xls, ///
		append `outreg_opt_mi' cttop("AME_pooled_all_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 } 
 
* Excluding out-of-scope
forval i = 1/6 {
	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
											if `sample_insc' `pool_weight'
		outreg2 using docs/attr-weight-multivariate-pooled-insc.xls, ///
								replace `outreg_opt_mi' cttop("pooled_insc_mi")
		
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_insc'  & m ==`i' `pool_weight'
		outreg2 using docs/attr-weight-multivariate-pooled-insc.xls, ///
									append `outreg_opt' cttop("pooled_insc_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-pooled-insc.xls, ///
		append `outreg_opt_mi' cttop("AME_pooled_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}

	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
										if `sample_insc'  & m ==`i' `pool_weight'
		outreg2 using docs/attr-weight-multivariate-pooled-insc.xls, ///
								append `outreg_opt'  cttop("pooled_insc_`i'")
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-pooled-insc.xls, ///
		append `outreg_opt_mi' cttop("AME_pooled_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 }
 
**** Multivariate association: Single panels ***********************************
* 2006 Panel: All respondents
forval i = 1/6 {
 
 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
												if `sample_2006_all' `weight'
		outreg2  using docs/attr-weight-multivariate-p2006-all.xls,  ///
		replace `outreg_opt_mi' cttop("p2006_all_mi")
	
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2006_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2006-all.xls, ///
								append `outreg_opt' cttop("p2006_all_`i'")
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2006-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2006_all_`i'")							
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
		
	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2006_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2006-all.xls, ///
								append `outreg_opt' cttop("p2006_all_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2006-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2006_all_`i'")							
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 } 

* 2006 Panel: Excluding out-of-scope
forval i = 1/6 {

 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
												if `sample_2006_insc' `weight'
		outreg2  using docs/attr-weight-multivariate-p2006-insc.xls,  ///
								replace `outreg_opt_mi' cttop("p2006_insc_mi")
								
		logit attr_w23 `age_o_vars' `vars_for_est' ///
								if `sample_2006_insc' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2006-insc.xls, ///
								append `outreg_opt' cttop("p2006_insc_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2006-insc.xls, ///
							append `outreg_opt_mi' cttop("AME_p2006_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 
	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
								if `sample_2006_insc' & m ==`i' `weight'
			outreg2 using docs/attr-weight-multivariate-p2006-insc.xls, ///
								append `outreg_opt' cttop("p2006_insc_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2006-insc.xls, ///
							append `outreg_opt_mi' cttop("AME_p2006_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
} 

* 2008 Panel: All respondents
forval i = 1/6 {
 
 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
								if `sample_2008_all' `weight'
		outreg2  using docs/attr-weight-multivariate-p2008-all.xls,  ///
								replace `outreg_opt_mi' cttop("p2008_all_mi")	
		logit attr_w23 `age_o_vars' `vars_for_est' ///
								if `sample_2008_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2008-all.xls, ///
								append `outreg_opt' cttop("p2008_all_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2008-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2008_all_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 
	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
								if `sample_2008_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2008-all.xls, ///
								append `outreg_opt' cttop("p2008_all_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2008-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2008_all_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 } 

* 2008 Panel: Excluding out-of-scope
forval i = 1/6 {

 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2008_insc' `weight'
		outreg2  using docs/attr-weight-multivariate-p2008-insc.xls,  ///
						replace `outreg_opt_mi' cttop("p2008_insc_mi")
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2008_insc' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2008-insc.xls, ///
								append `outreg_opt' cttop("p2008_insc_`i'")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2008-insc.xls, ///
						append `outreg_opt_mi' cttop("AME_p2008_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 
	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2008_insc' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2008-insc.xls, ///
									append `outreg_opt' cttop("coef.")								
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2008-insc.xls, ///
						append `outreg_opt_mi' cttop("AME_p2008_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 } 

* 2010 Panel: All respondents
forval i = 1/6 {
 
 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2010_all' `weight'
		outreg2  using docs/attr-weight-multivariate-p2010-all.xls,  ///
								replace `outreg_opt_mi' cttop("p2010_all_mi")
	
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2010_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2010-all.xls, ///
									append `outreg_opt' cttop("p2010_all_`i'")									
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2010-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2010_all_`i'")				
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 
	else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2010_all' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2010-all.xls, ///
							append `outreg_opt' cttop("p2010_all_`i'")
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2010-all.xls, ///
							append `outreg_opt_mi' cttop("AME_p2010_all_`i'")	
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 } 
 
* 2010 Panel: Excluding out-of-scope
forval i = 1/6 {
 
 	if `i' == 1 {
		mi estimate, post: logit attr_w23 `age_o_vars' `vars_for_est' ///
						if `sample_2010_insc' `weight'
		outreg2  using docs/attr-weight-multivariate-p2010-insc.xls,  ///
						replace `outreg_opt_mi' cttop("p2010_insc_mi")	
		logit attr_w23 `age_o_vars' `vars_for_est' ///
						if `sample_2010_insc' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2010-insc.xls, ///
						append `outreg_opt' cttop("p2010_insc_`i'")					
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2010-insc.xls, ///
						append `outreg_opt_mi' cttop("AME_p2010_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 
	 else if `i' != 1 {
		logit attr_w23 `age_o_vars' `vars_for_est' ///
									if `sample_2010_insc' & m ==`i' `weight'
		outreg2 using docs/attr-weight-multivariate-p2010-insc.xls, ///
									append `outreg_opt' cttop("p2010_insc_`i'")									
		predict yhat if e(sample)
		margins, dydx(*) post
		outreg2 using docs/attr-weight-multivariate-p2010-insc.xls, ///
							append `outreg_opt_mi' cttop("AME_p2010_insc_`i'")
		mean yhat `weight'
		mean yhat `weight', over(attr_w23)
		drop yhat
		}
 }

log close
