set more off
capture clear
capture log close
cls

log using log/estimate-attrition-probabilities.log, replace

use data/gss-panel-2006-2014-imputed-recoded.dta, clear

********************************************************************************
*** Define macros and tempfiles
********************************************************************************

#delimit ;
local vars_for_est
	c.age_o1 c.age_o2 c.age_o3
	i.sex i.racehisp5 b1.degree c.realinc i.dwelown i.marital i.borncitz
	i.region c.wordsum  c.intage i.intsex i.intethn c.intyrs c.lngthinv
	c.daysint i.mode i.feeused i.coop i.comprend i.spaneng ; 
#delimit cr
	
tempfile mi_est_all mi_est_all_insc

********************************************************************************
*** Construct weights from wtssnr for use with panels
********************************************************************************

/* Note: 	The first rescaling, (`r(N)'/`r(sum)') rescales wtssnr so that it 
			sums to panel size N, which is needed for 2006 because the panel 
			was a subsample of all cross-sectional cases.  
			
			The second rescaling, (1/3)*(6067/`r(sum)'), scales each of the 
			three panel samples so that they contribute 1/3 of the mass of the 
			pooled weight, which downweights the slightly larger panels in 2008 
			and 2010 proportionately.  */
			
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
*** Estimate attrition models (using mi commands) for multiply imputed data
*** Then, save predictions and variances of predictions
********************************************************************************

/*
Components of saved variable names

	xb:   linear prediction
	pr:   predicted probabilty
	var:  variance of prediction
	all:  all years pooled
	2006: 2006 panel respondents only
	2008: 2008 panel respondents only
	2010: 2010 panel respondents only
	insc: in scope for all waves of panel (i.e., eligible)
*/

*** Estimate models for all three panels pooled

mi set flong

mi estimate, saving(`mi_est_all', replace) post:                             ///
	logit attr_w23 `vars_for_est' if panelwave==1 [pw=pool_wt]
mi predictnl xb_all = predict(xb) using `mi_est_all' if panelwave==1,        ///
	var(xb_var_all)
mi predictnl pr_all = predict(p) using `mi_est_all' if panelwave==1,         ///
	var(pr_var_all)
	
mi estimate, saving(`mi_est_all_insc', replace) post:                        ///
	logit attr_w23 `vars_for_est' if panelwave==1 & outsc_w23==0 [pw=pool_wt]
mi predictnl xb_all_insc = predict(xb) using `mi_est_all_insc'               ///
    if panelwave==1 & outsc_w23==0, var(xb_var_all_insc)
mi predictnl pr_all_insc = predict(p) using `mi_est_all_insc'                ///
	if panelwave==1 & outsc_w23==0, var(pr_var_all_insc)

*** Estimate models for each panel separately

forval i = 2006(2)2010 {

	tempfile mi_est_`i' mi_est_`i'_insc

	mi estimate, saving(`mi_est_`i'', replace) post:                         ///
		logit attr_w23 `vars_for_est'                                        ///
		if panelwave==1 & samptype == `i' [pw=wtssnr_rs]
	mi predictnl xb_`i' = predict(xb) using `mi_est_`i''                     ///
		if panelwave==1 & samptype == `i', var(xb_var_`i')
	mi predictnl pr_`i' = predict(p) using `mi_est_`i''                      ///
		if panelwave==1 & samptype == `i', var(pr_var_`i')

	mi estimate, saving(`mi_est_`i'_insc', replace) post:                    ///
		logit attr_w23 `vars_for_est'                                        ///
		if panelwave==1 & samptype == `i' & outsc_w23==0 [pw=wtssnr_rs]
	mi predictnl xb_`i'_insc = predict(xb) using `mi_est_`i'_insc'           ///
		if panelwave==1 & samptype == `i' & outsc_w23==0,                    ///
		var(xb_var_`i'_insc)
	mi predictnl pr_`i'_insc = predict(p) using `mi_est_`i'_insc'            ///
		if panelwave==1 & samptype == `i'& outsc_w23==0,                     ///
		var(pr_var_`i'_insc)
}

********************************************************************************
*** Create predicted probabilities for each panel that are shrunken toward
***   the predicted probabilities from the pooled attrition model
********************************************************************************

forval i = 2006(2)2010 { 
		
	/* Note: Define precision as the inverse variance of the fitted value xb 
			 of each individual, which differs for the pooled model and the 
			 panel-specific model.  See note below on an alternative 
			 definition of precision. */
	
	  gen pr_shr_`i' =                                                       ///
	  ((1/xb_var_all)*pr_all + (1/(xb_var_`i')*pr_`i'))                      ///
	  / (1/xb_var_all + 1/xb_var_`i')                                        ///
	  if samptype==`i' & panelwave==1
		
	  gen pr_shr_`i'_insc =                                                  ///
	  ((1/xb_var_all_insc)*pr_all_insc + (1/(xb_var_`i'_insc)*pr_`i'_insc))  ///
	  / (1/xb_var_all_insc + 1/xb_var_`i'_insc)                              ///
	  if samptype==`i' & panelwave==1
		
	summ pr_all pr_`i' pr_shr_`i' pr_all_insc pr_`i'_insc ///
		pr_shr_`i'_insc [aw=wtssnr_rs] if samptype==`i' & panelwave==1
	
}

  /* Note:  Defining precision instead based on predicted probabilities would be
			distorted a bit by scaling.  The delta method for the s.e. of the 
			predicted probability is the fitted value (xb) muplitplied by 
			p(1-p), where p is solved by putting the fitted value through the 
			logit link. The p(1-p) term has consequences because it differs 
			between the pooled value and the panel-specific values that are 
			then precision weighted.  This could be adjusted for, but then one 
			is just back to using the fitted value xb from the linear 
			prediction.  This is the approach above taken. The alternative 
			would be a version based on this expression (but with an added
			adjustment for difference in p(1-p):
	
			gen pr_shr_`i' = ((1/pr_var_all)*pr_all + (1/(pr_var_`i')*pr_`i'))    
							 / (1/pr_var_all + 1/pr_var_`i')                  */
						  
********************************************************************************
*** Order estimated values and then broadcast across imputed datasets 
********************************************************************************

#delimit ;
local pr_vars 
 xb_all       xb_var_all       
 pr_all       pr_var_all       
 xb_all_insc  xb_var_all_insc  
 pr_all_insc  pr_var_all_insc 
 
 xb_2006      xb_var_2006      
 pr_2006      pr_var_2006 
 pr_shr_2006     
 xb_2006_insc xb_var_2006_insc 
 pr_2006_insc pr_var_2006_insc 
 pr_shr_2006_insc
 
 xb_2008      xb_var_2008      
 pr_2008      pr_var_2008 
 pr_shr_2008      
 xb_2008_insc xb_var_2008_insc 
 pr_2008_insc pr_var_2008_insc 
 pr_shr_2008_insc
 
 xb_2010      xb_var_2010      
 pr_2010      pr_var_2010 
 pr_shr_2010      
 xb_2010_insc xb_var_2010_insc 
 pr_2010_insc pr_var_2010_insc 
 pr_shr_2010_insc ;
#delimit cr

foreach var in `pr_vars' {
	quietly bysort panelid (`var'): replace `var' = `var'[1]
}

order `pr_vars', after(outsc_w23)

********************************************************************************
*** Save datasets
********************************************************************************

*** save full dataset, keeping all unimputed and imputed records, as well as
***   predictors of attrition

order panelid panelwave id year samptype m
sort panelid panelwave m
compress
save data/gss-panel-2006-2014-attrition-pr-all-im.dta, replace

*** save dataset with only one record per respondent

mi unset, asis
keep if m==1 // Keep the first set of imputation records.  This file would be
             //   the same for any other set of imputations because no 
			 //   predictor variables are saved in the file.
drop m _* m_*
keep panelid-pr_shr_2010_insc
sort panelid panelwave

save data/gss-panel-2006-2014-attrition-pr.dta, replace

log close
