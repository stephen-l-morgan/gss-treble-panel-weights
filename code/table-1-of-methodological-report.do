set more off
capture clear
capture log close
cls

log using log/table-1-of-methodological-report.log, replace

********************************************************************************
***  Data pre-processing
********************************************************************************

use data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta, clear
keep if panelr==1 // keep only panel respondents

*** Indicator variables for attrition, out-of-scope ****************************
*** indicators for panel attrition
egen w1 = total(panelwave==1) if !missing(panelid), by(panelid)
egen w2 = total(panelwave==2) if !missing(panelid), by(panelid)
egen w3 = total(panelwave==3) if !missing(panelid), by(panelid)

*** indicator var for attrition 
gen w23_r = (w2==0 | w3==0)

*** panel out-of-scope status
g outscope_w2 =.
replace outscope_w2 = 1 if ((panstat_2 >=31 & panstat_2 <=33) | panstat_2==3) ///

replace outscope_w2 = 0 if (panstat_2 ==1 | panstat_2==2) 
tab outscope_w2 panstat_2, m
// 1 repondendent was "Selected, but not eligible and not reinterviewd"
// I consider this respondent to be out-of-scope

g outscope_w3 =.
replace outscope_w3 = 1 if panstat_3 >=31 & panstat_3 <=33 
replace outscope_w3 = 0 if (panstat_3 ==1 | panstat_3==2) 
tab outscope_w3 panstat_3, m

gen outscope23 = (outscope_w2==1 | outscope_w3==1) if   panelr==1
bys outscope23: tab panstat_2 panstat_3 if  panelr==1, m nol


********************************************************************************
*** Tabulation
********************************************************************************
*** Panel A
tab samptype panelwave
bys samptype: tab w3 if panelwave==1 
mean w3 if panelwave==1 [pw=wtssnr], over(samptype)

*** Panel B
tab samptype panelwave if outscope23==0
bys samptype: tab w3 if panelwave==1 & outscope23==0 [aw=wtssnr]
mean w3 [pw=wtssnr] if panelwave==1  & outscope23==0, over(samptype)
