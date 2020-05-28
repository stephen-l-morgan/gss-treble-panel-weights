set more off
capture clear
capture log close
cls

log using log/create-and-demonstrate-usage-of-merge-file.log, replace

********************************************************************************
*** Create merge file with only the essential columns
********************************************************************************

*** Long form (three records for each non-attriting panel member, with id for
***   each data collection year)

use data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, clear
keep if attr_w23 == 0
keep panelid panelwave year id wt_pooled - wt_shrunken_insc
order panelid panelwave year id wt_pooled - wt_shrunken_insc
sort panelid panelwave
summ
save data/gss-treble-panel-weights-long.dta, replace
outsheet using data/gss-treble-panel-weights-long.csv, comma replace

*** Wide form (one record for each non-attriting panel member, with base 
***   year id)

keep if panelwave == 1
drop panelid panelwave
sort year id
summ
save data/gss-treble-panel-weights-wide.dta, replace
outsheet using data/gss-treble-panel-weights-wide.csv, comma replace

********************************************************************************
*** Demonstration of merge code 
********************************************************************************

* GSS 2006-2010 panel 

use ../gss-from-norc/GSS_panel06w123_R6a.dta, clear
rename *, lower
clonevar year = year_1
clonevar id = id_1
sort year id
merge m:m year id using data/gss-treble-panel-weights-wide.dta
order year - _merge
drop if _merge == 2
codebook year - wtpannr123, c

* GSS 2008-2012 panel 
use ../gss-from-norc/GSS_panel08w123_R6.dta, clear
rename *, lower
clonevar year = year_1
clonevar id = id_1
sort year id
merge m:m year id using data/gss-treble-panel-weights-wide.dta
order year - _merge
drop if _merge == 2
codebook year - wtpannr123, c

* GSS 2010-2014 panel
use ../gss-from-norc/GSS_panel2010w123_R6.dta, clear
rename *, lower
clonevar year = year_1
clonevar id = id_1
sort year id
merge m:m year id using data/gss-treble-panel-weights-wide.dta
order year - _merge
drop if _merge == 2
codebook year - wtpannr123, c

********************************************************************************
*** Demonstrate how scaling does not affect estimates
********************************************************************************

use data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta, clear
keep if panelwave==1 & outsc_w23 == 0

*** results in base year for panel in-scope, non-attriters and attriters
summ wordsum degree hisp [aweight = wtssnr]
regress wordsum b1.degree hisp [pweight = wtssnr]

*** drop attriters and construct a rescaled weight that sums to panel N
keep if attr_w23 == 0
summ wtpannr123 wt_shrunken_insc
quietly sum wt_shrunken_insc
scalar adjust = 1/`r(mean)'
display adjust
gen wt_rescaled = wt_shrunken_insc * adjust
summ wtpannr123 wt_shrunken_insc wt_rescaled

*** results for non-attriters, also using rescaled attrition adjustment weight
summ wordsum degree hisp [aweight = wtpannr123]
summ wordsum degree hisp [aweight = wt_shrunken_insc]
summ wordsum degree hisp [aweight = wt_rescaled]

regress wordsum b1.degree hisp [pweight = wtpannr123]
regress wordsum b1.degree hisp [pweight = wt_shrunken_insc]
regress wordsum b1.degree hisp [pweight = wt_rescaled]

log close
