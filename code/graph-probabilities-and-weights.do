capture clear
capture log close
set more off
set linesize 120
cls

log using log/graph-probabilities-and-weights.log, replace

use data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, clear

*** Change scheme and font for figures
include code/settings-graph-s1-palatino.do

********************************************************************************
*** Graph probabilities
********************************************************************************

*** All

forval i = 2006(2)2010 { 

local yvar pr_`i'
local xvar pr_all

summ `yvar' `xvar' if year == `i'
summ `yvar' `xvar'[aweight = wtpannr123] if year == `i'

preserve
keep if year == `i'

    twoway ///
	   (scatter `yvar' `xvar' if attr_w23 == 0 [aweight=wtpannr123], /// 
        msymbol(o) msize(tiny) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(0 .2 .4 .6 .8 1, grid) xlabel(0 .2 .4 .6 .8 1, nogrid)) ///
	|| /* (line `xvar' `xvar' , lcolor(navy)) */ ///
	,   ///
	   title("") ytitle("`yvar'") xtitle("`xvar'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvar', replace)

	restore

}

forval i = 2006(2)2010 { 

local yvar pr_shr_`i'
local xvar pr_all

preserve
keep if year == `i'

    twoway ///
	   (scatter `yvar' `xvar' if attr_w23 == 0 [aweight=wtpannr123], /// 
        msymbol(o) msize(tiny) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(0 .2 .4 .6 .8 1, grid) xlabel(0 .2 .4 .6 .8 1, nogrid)) ///
	   || /* (line `xvar' `xvar' , lcolor(navy)) */ ///
	   ,        ///
	   title("") ytitle("`yvar'") xtitle("`xvar'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvar', replace)

	restore

}

 graph combine ///
    tmp/pr_2006_pr_all.gph          ///
	tmp/pr_2008_pr_all.gph          ///
	tmp/pr_2010_pr_all.gph          ///
	tmp/pr_shr_2006_pr_all.gph          ///
	tmp/pr_shr_2008_pr_all.gph          ///
	tmp/pr_shr_2010_pr_all.gph, cols(2) colf xcommon ycommon ///
	saving(graph/fig-1-probabilities-all.gph, replace)
	
graph export graph/fig-1-probabilities-all.pdf, replace
graph export graph/fig-1-probabilities-all-1650-by-1200.png, ///
  width(1650) height(1200) replace

*** In-scope

forval i = 2006(2)2010 { 

local yvar pr_`i'_insc
local xvar pr_all_insc

summ `yvar' `xvar' if year == `i'
summ `yvar' `xvar'[aweight = wtpannr123] if year == `i'

preserve
keep if year == `i'

    twoway ///
	   (scatter `yvar' `xvar' if attr_w23 == 0 [aweight=wtpannr123], /// 
        msymbol(o) msize(tiny) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(0 .2 .4 .6 .8 1, grid) xlabel(0 .2 .4 .6 .8 1, nogrid)) ///
	|| /* (line `xvar' `xvar' , lcolor(navy)) */ ///
	,   ///
	   title("") ytitle("`yvar'") xtitle("`xvar'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvar', replace)

	restore

}

forval i = 2006(2)2010 { 

local yvar pr_shr_`i'_insc
local xvar pr_all_insc

preserve
keep if year == `i'

    twoway ///
	   (scatter `yvar' `xvar' if attr_w23 == 0 [aweight=wtpannr123], /// 
        msymbol(o) msize(tiny) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(0 .2 .4 .6 .8 1, grid) xlabel(0 .2 .4 .6 .8 1, nogrid)) ///
	   || /* (line `xvar' `xvar' , lcolor(navy)) */ ///
	   ,        ///
	   title("") ytitle("`yvar'") xtitle("`xvar'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvar', replace)

	restore

}

 graph combine ///
    tmp/pr_2006_insc_pr_all_insc.gph          ///
	tmp/pr_2008_insc_pr_all_insc.gph          ///
	tmp/pr_2010_insc_pr_all_insc.gph          ///
	tmp/pr_shr_2006_insc_pr_all_insc.gph          ///
	tmp/pr_shr_2008_insc_pr_all_insc.gph          ///
	tmp/pr_shr_2010_insc_pr_all_insc.gph, cols(2) colf xcommon ycommon ///
	saving(graph/fig-2-probabilities-insc.gph, replace)
	
graph export graph/fig-2-probabilities-insc.pdf, replace
graph export graph/fig-2-probabilities-insc-1650-by-1200.png, ///
  width(1650) height(1200) replace

********************************************************************************
*** Graph weights
********************************************************************************

local wt_list ///
	wtpannr123 ///
	wt_no_pooling wt_pooled wt_shrunken ///
	wt_no_pooling_insc wt_pooled_insc wt_shrunken_insc

foreach var of varlist `wt_list' {

	gen l`var' = ln(`var')

}
	
local yvarlist wt_no_pooling wt_pooled wt_shrunken ///
	wt_no_pooling_insc wt_pooled_insc wt_shrunken_insc

local yvarlistl lwt_no_pooling lwt_pooled lwt_shrunken ///
	lwt_no_pooling_insc lwt_pooled_insc lwt_shrunken_insc
 
local xvar wtpannr123
local xvarl lwtpannr123 

foreach yvar of varlist `yvarlist' {
 twoway ///
	   (scatter `yvar' `xvar', /// 
        msymbol(o) msize(vsmall) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(0 4 8 12 16, grid) xlabel(1 2 3 4 5 6, grid)) ///
	   || (line `xvar' `xvar' , lcolor(navy)) ,   ///
	   title("") ytitle("`yvar'") xtitle("`xvar'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvar', replace)
}

graph combine ///
    tmp/wt_no_pooling_wtpannr123.gph          ///
	tmp/wt_pooled_wtpannr123.gph          ///
	tmp/wt_shrunken_wtpannr123.gph          ///
	tmp/wt_no_pooling_insc_wtpannr123.gph          ///
	tmp/wt_pooled_insc_wtpannr123.gph          ///
	tmp/wt_shrunken_insc_wtpannr123.gph, cols(2) colf xcommon ycommon   ///
	saving(graph/fig-3-weights.gph, replace)
	
graph export graph/fig-3-weights.pdf, replace
graph export graph/fig-3-weights-1650-by-1200.png, width(1650) height(1200) replace

foreach yvar of varlist `yvarlistl' {
 twoway ///
	   (scatter `yvar' `xvarl', /// 
        msymbol(o) msize(vsmall) mcolor(gs8) mfcolor(white) mlcolor(eltblue) ///
		ylabel(-1 0 1 2 3, grid) xlabel(-1 0 1 2, grid)) ///
	   || (line `xvarl' `xvarl' , lcolor(navy)) ,   ///
	   title("") ytitle("`yvar'") xtitle("`xvarl'") note("") legend(off) ///
	   saving(tmp/`yvar'_`xvarl', replace)
}

graph combine ///
    tmp/lwt_no_pooling_lwtpannr123.gph          ///
	tmp/lwt_pooled_lwtpannr123.gph          ///
	tmp/lwt_shrunken_lwtpannr123.gph          ///
	tmp/lwt_no_pooling_insc_lwtpannr123.gph          ///
	tmp/lwt_pooled_insc_lwtpannr123.gph          ///
	tmp/lwt_shrunken_insc_lwtpannr123.gph, cols(2) colf xcommon ycommon   ///
	saving(graph/fig-4-weights-logged.gph, replace)
	
graph export graph/fig-4-weights-logged.pdf, replace
graph export graph/fig-4-weights-logged-1650-by-1200.png, ///
  width(1650) height(1200) replace

log close
