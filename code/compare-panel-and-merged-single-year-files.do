capture log close
set more off
cls
 
log using log/compare-panel-and-merged-single-year-files.log, replace

/* 

NOTE 1:
This file attempts to demonstrate the equivalance of the panel data releases and 
the single year merged files for the panel responses by comparing the values 
in the two data files.

NOTE 2:
The -cf- command is designed to stop the do file from running after it finds 
any discrepencies between the two data sets in comparison.  As a result, 
this do-file will not run through to the end if it is run from teh do-file 
editor.  (It will stop after the first use of -cf-, wehere a difference is
found.)

In order to get the file run all the way to the end, you must run this file 
within the  master do-file ("do-all-to-create-panel-attrition-weights) 
which specifies the -nostop- option. 
*/

********************************************************************************
*** Macros and tempfiles + Recoding missing cases for consistency
********************************************************************************

/* NOTE:
The two types of files have an inconsistent treatment of missing cases for some 
variables.  To not consider such inconsistency as a discrepancy between the 
datasets, we recode the inconsistent missing values in advance.
*/

tempfile gss_2006_panel gss_2008_panel gss_2010_panel ///
		gss_2008_all_vars gss_2010_all_vars gss_2012_all_vars ///
		gss_2014_all_vars gss_7218
tempfile panel2006_ind  ///
	panel_2006_w1_panel panel_2006_w2_panel panel_2006_w3_panel ///
	panel_2008_w1_panel panel_2008_w2_panel panel_2008_w3_panel ///
	panel_2010_w1_panel panel_2010_w2_panel panel_2010_w3_panel ///
	p2006_w1_in_cross_section p2008_w1_in_cross_section ///
	p2010_w1_in_cross_section ///
	p2006_w2_in_all_vars_file p2006_w3_in_all_vars_file ///
	p2008_w1_in_all_vars_file p2008_w2_in_all_vars_file p2008_w3_in_all_vars_file ///
	p2010_w1_in_all_vars_file p2010_w2_in_all_vars_file p2010_w3_in_all_vars_file

* GSS 2006-2010 panel 
use ../gss-from-norc/GSS_panel06w123_R6a.dta, clear
rename *, lower
recode exptext_1 9=. // 9 is "No Answer to Closed ended Question"
recode exptext_3 9=. // 9 is "No Answer to Closed ended Question"
recode scinews3_3 9 98/99 =. // 9 undefined and 98/99 is "DK" or "NA
save `gss_2006_panel'

* GSS 2008-2012 panel 
use ../gss-from-norc/GSS_panel08w123_R6.dta, clear
gen samptype = 2008
rename *, lower
recode mode_2 9 = . // 9 is "NA"
recode mode_3 8/9 = . // 8/9 is "DK" or "NA"
recode exptext_2 9 =. // 9 is "No Answer to Closed ended Question"
recode exptext_3 9 =. // 9 is "No Answer to Closed ended Question"
recode scinews3_3 98/99 =. // 98/99 is "DK" or "NA"
recode jew16_1 99 =. // 99 is undefined
save `gss_2008_panel'

* GSS 2010-2014 panel
use ../gss-from-norc/GSS_panel2010w123_R6.dta, clear
rename *, lower
recode indus80_1 999=. // 999 is "NA"
recode mode_1 8/9 = . // 8/9 is "NA"
recode mode_2 9 = . // 9 is "NA"
recode waypaid_1 98/99 =. // 98/99 is "DK" or "NA"
recode exptext_1 9 =. // 9 is "No Answer to Closed ended Question"
recode exptext_2 9 =. // 9 is "No Answer to Closed ended Question"
recode exptext_3 9 =. // 9 is "No Answer to Closed ended Question"
recode scinews3_1 98/99 =. // 98/99 is "DK" or "NA"
recode scinews3_2 98/99 =. // 98/99 is "DK" or "NA"
recode scinews3_3 98/99 =. // 98/99 is "DK" or "NA"
save `gss_2010_panel'

* GSS 2008 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/gss2008crosspanel_R6.dta, clear
rename *, lower
recode income 13 = . // 13 is "refused"
recode income06 26 = . // 26 is "refused"
recode rincom06 26 = . // 26 is "refused"
recode rincome 13 = . // 13 is "refused"
recode jew16 99 =. // 99 is undefined
save `gss_2008_all_vars'

* GSS 2010 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/GSS2010merged_R8.dta, clear
rename *, lower
recode exptext 9 = . // 9 is "NA"
recode scinews3 9 =. // 9 likely an error for 98/99 which is "DK" or "NA"
save `gss_2010_all_vars'

* GSS 2012 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/GSS2012merged_r10.dta, clear
rename *, lower
recode exptext 99 = . // 99 is "Blanck"
recode refhage 98/99 =. // 98/99 is "NA" or "DK"
recode gotthngs 9 = . // 9 is "NA"
save `gss_2012_all_vars'

* GSS 2014 all variables and cases (cross-section and panel reinterviews) 
use ../gss-from-norc/gss2014merged_r10.dta, clear
rename *, lower
recode scinews3 98/99 =. // 98/99 is "NA" or "DK"
save `gss_2014_all_vars'

* GSS 1972-2018 cross-section only
use ../gss-from-norc/GSS7218_R1.dta, clear
recode exptext 9 =. // 9 is "no answer"
recode indus80 999 =. // 999 is missing
recode mode 8/9 = . // 8/9 is "NA"
recode scinews3 98/99 = . // 98/99 is "NA" or "DK"
save `gss_7218'


********************************************************************************
*** GSS Panel 2006
********************************************************************************

*** First interview ************************************************************

*** extract an indicator for panel respondents from the panel data
use `gss_2006_panel', clear
keep id_1 
rename id_1 id
save `panel2006_ind'

*** merge the indicator to the respondents in 2006 in the cross-sectional data
use `gss_7218', clear
keep if year==2006
merge 1:1 id using `panel2006_ind'
keep if _merge==3
drop _merge
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2006_w1_in_cross_section', replace

*** extract only the first interview responses in the panel data
use `gss_2006_panel', clear
keep  *_1
rename *_1 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2006_w1_panel', replace

*** compare cross-section to panel
cf _all using `p2006_w1_in_cross_section',  verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to cross-section
// use `p2006_w1_in_cross_section', clear
// cf _all using `panel_2006_w1_panel',  verbose


*** Re-interview 1 *************************************************************

*** extract the 2nd wave interview from the merged single year file
use `gss_2008_all_vars', clear
keep if samptype==2006
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2006_w2_in_all_vars_file', replace

*** extract only the second interview responses in the panel data
use `gss_2006_panel', clear
keep if panstat_2==1
keep  *_2
rename *_2 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2006_w2_panel', replace

*** compare single year merged file to panel
cf _all using `p2006_w2_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `p2006_w2_in_all_vars_file', clear
// cf _all using `panel_2006_w2_panel',  verbose


*** Re-interview 2 *************************************************************

*** extract the 3nd wave interview from the merged single year file
use `gss_2010_all_vars', clear
keep if samptype==2006
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2006_w3_in_all_vars_file', replace

*** extract only the their interview responses in the panel data
use `gss_2006_panel', clear
keep if panstat_3==1
keep  *_3
rename *_3 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2006_w3_panel', replace

*** compare single year merged file to panel
cf _all using `p2006_w3_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `p2006_w3_in_all_vars_file', clear
// cf _all using `panel_2006_w3_panel',  verbose


********************************************************************************
*** GSS Panel 2008
********************************************************************************

*** First interview ************************************************************

*** extract the first interview from the the cumulative cross-section file
use `gss_7218', clear
keep if year==2008
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2008_w1_in_cross_section', replace

*** extract the first interview from the merged single year file
use `gss_2008_all_vars', clear
keep if samptype==2008
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2008_w1_in_all_vars_file', replace

*** extract only the first interview responses in the panel data
use `gss_2008_panel', clear
keep  *_1
drop vetyear2 /* vetyear vars already included */
rename *_1 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2008_w1_panel', replace

*** compare cross-section to panel
cf _all using `p2008_w1_in_cross_section',  verbose
*** compare merged single year file to panel
cf _all using `p2008_w1_in_all_vars_file',  verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to merged single year file
// use `p2008_w1_in_all_vars_file', clear
// cf _all using `panel_2008_w1_panel',  verbose


*** Re-interview 1 *************************************************************

*** extract the 2nd wave interview from the all variable and cases file
use `gss_2010_all_vars', clear
keep if samptype==2008
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2008_w2_in_all_vars_file', replace

*** extract only the second interview responses in the panel data
use `gss_2008_panel', clear
keep if panstat_2==1
keep  *_2
rename *_2 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2008_w2_panel', replace

*** compare merged single year file to panel
cf _all using `p2008_w2_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `p2008_w2_in_all_vars_file', clear
// cf _all using `panel_2008_w2_panel',  verbose


*** Re-interview 2 *************************************************************

*** extract the 3nd wave interview from the merged single year file
use `gss_2012_all_vars', clear
keep if samptype==2008
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2008_w3_in_all_vars_file', replace

*** extract only the third interview responses in the panel data
use `gss_2008_panel', clear
keep if panstat_3==1
keep  *_3
rename *_3 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2008_w3_panel', replace

*** compare merged single year file to panel
cf _all using `p2008_w3_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `panel_2008_w3_panel', clear
// cf _all using `p2008_w3_in_all_vars_file',  verbose


********************************************************************************
*** GSS Panel 2010
********************************************************************************

*** First interview ************************************************************

*** extract the first interview from the the cumulative cross-section file
use `gss_7218', clear
keep if year==2010
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2010_w1_in_cross_section', replace

*** extract the first interview from the merged single year file
use `gss_2010_all_vars', clear
keep if samptype==2010
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2010_w1_in_all_vars_file', replace

*** extract only the first interview responses in the panel data
use `gss_2010_panel', clear
keep  *_1
rename *_1 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2010_w1_panel', replace

*** compare cross-section to panel
cf _all using `p2010_w1_in_cross_section',  verbose
*** compare merged single year file to panel
cf _all using `p2010_w1_in_all_vars_file',  verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to merged single year file
// use `p2010_w1_in_all_vars_file', clear
// cf _all using `panel_2010_w1_panel',  verbose


*** Re-interview 1 *************************************************************

*** extract the 2nd wave interview from the merged single year file
use `gss_2012_all_vars', clear
keep if samptype==2010
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2010_w2_in_all_vars_file', replace

*** extract only the second interview responses in the panel data
use `gss_2010_panel', clear
keep if panstat_2==1
keep  *_2
rename *_2 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2010_w2_panel', replace

*** compare merged single year file to panel
cf _all using `p2010_w2_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `panel_2010_w2_panel', clear
// cf _all using `p2010_w2_in_all_vars_file',  verbose

*** Re-interview 2 *************************************************************

*** extract the 3nd wave interview from the merged single year file
use `gss_2014_all_vars', clear
keep if samptype==2010
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `p2010_w3_in_all_vars_file', replace

*** extract only the third interview responses in the panel data
use `gss_2010_panel', clear
keep if panstat_3==1
keep  *_3
rename *_3 *
do analysis/drop-not-aksed-and-replace-missing.do
sort id
save `panel_2010_w3_panel', replace

*** compare merged single year file to panel
cf _all using `p2010_w3_in_all_vars_file', verbose

// Note: Run these commmands to ensure that the order of comparions
//          does not make a difference 
// *** compare panel to single year merged file
// use `panel_2010_w3_panel', clear
// cf _all using `p2010_w3_in_all_vars_file',  verbose

log close
