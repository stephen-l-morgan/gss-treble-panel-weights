set more off
capture clear
capture log close
cls

log using log/person-centered-view-of-weights.log, replace

use data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, clear

********************************************************************************
*** Calculate indvidual values and output them to an excel spreadsheet
********************************************************************************

*** macros

#delimit ;

local first_list 
	year id wtpannr123 
	invp_no_pooling      invp_pooled      invp_shrunken 
	invp_no_pooling_insc invp_pooled_insc invp_shrunken_insc 	
	wt_no_pooling      wt_pooled      wt_shrunken 
	wt_no_pooling_insc wt_pooled_insc wt_shrunken_insc ;
	
local second_list
	age sex racehisp degree realinc dwelown marital born uscitzn
	region wordsum  intage intsex intethn intyrs lngthinv
    mode feeused coop comprend spaneng ; 
	
#delimit cr

local both `first_list' `second_list'

*** select non-attriters

keep if panelwave == 1 & attr_w23 == 0

*** combine year-specific

clonevar invp_pooled = wt_all
clonevar invp_pooled_insc = wt_all_insc

gen invp_no_pooling = .
gen invp_no_pooling_insc = .
gen invp_shrunken = .
gen invp_shrunken_insc = .

forval i = 2006(2)2010 {
	replace invp_no_pooling 		= invp_`i' if samptype == `i'
	replace invp_no_pooling_insc  = invp_`i'_insc if samptype == `i'
	replace invp_shrunken 		= invp_shr_`i' if samptype == `i'
	replace invp_shrunken_insc 	= invp_shr_`i'_insc if samptype == `i'
}

*** select individuals based on the distribtion of inverse probabilities for
***  the shrunken probs

summ invp_shrunken, d
return list 

/*
				  r(N) =  3875
              r(sum_w) =  3875
               r(mean) =  1.567818257670249
                r(Var) =  .197464011292139
                 r(sd) =  .4443692285612709
           r(skewness) =  7.060503899562557
           r(kurtosis) =  115.3165248326705
                r(sum) =  6075.295748472214
                r(min) =  1.155449032783508
                r(max) =  12.54720401763916
                 r(p1) =  1.224847555160522
                 r(p5) =  1.273510456085205
                r(p10) =  1.300930738449097
                r(p25) =  1.356502175331116
                r(p50) =  1.452073931694031
                r(p75) =  1.603521347045898
                r(p90) =  1.907183647155762
                r(p95) =  2.253139495849609
                r(p99) =  3.493884086608887
*/
gen focus = .
replace focus = 1 if invp_shrunken < 1.15545 
replace focus = 2 if invp_shrunken > 1.30093 & invp_shrunken < 1.30094 
replace focus = 3 if invp_shrunken > 1.35650 & invp_shrunken < 1.35651 
replace focus = 4 if invp_shrunken > 1.45207 & invp_shrunken < 1.45208 
replace focus = 5 if invp_shrunken > 1.60352 & invp_shrunken < 1.60353 
replace focus = 6 if invp_shrunken > 1.90718 & invp_shrunken < 1.90719  
replace focus = 7 if invp_shrunken > 2.25313 & invp_shrunken < 2.25314  
replace focus = 8 if invp_shrunken > 3.49388 & invp_shrunken < 3.49389 
replace focus = 9 if invp_shrunken > 12.5472 & invp_shrunken < .      

*** identify another 30 (approx) additional cases at random 
generate random = runiform() if focus==.
replace focus = 99 if random < 30/3886 & focus == .
la def focus 1 "min" 2 "10th ptile"	3 "25th ptile" 4 "median" ///
  5 "75th ptile" 6 "90th ptile" 7 "95th ptile" 8 "99th ptile" 9 "max" ///
  99 "random"
la val focus focus
tab focus, miss

*** order and save selected variables for csv output

keep if focus != .
sort focus invp_shrunken
keep focus xb_* pr_* `both'
order focus year id xb_* pr_* `both'

outsheet using docs/person-centered-view.csv, comma replace

log close
