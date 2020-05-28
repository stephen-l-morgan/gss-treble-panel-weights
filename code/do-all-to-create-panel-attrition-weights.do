********************************************************************************
*** This do file runs all component do files in the proper order.
***   The final 2 do files are optional and not necessary for the
***   estimation and construction of the weights.
***
***   NOTE:  The R code for imputation must be run separately in R.
********************************************************************************
 
do code/mk-gss-2006-2014-with-panel-fill-in.do
do code/mk-gss-2006-2014-fill-in-and-recoded.do
do code/variables-to-impute.do

*** At this point, the R script: 
***
***      code/gss-change-panel-attr-wt-imputation.R
***
*** needs to be run in R in order to generate imputed datasets (using the 
*** R package missForest to implement non-parametric missing value imputation).

do code/append-and-merge-imputed-datasets.do
do code/estimate-attrition-probabilities.do
do code/create-panel-attrition-weights.do
do code/create-and-demonstrate-usage-of-merge-file.do

*** Final steps (optional):  

*** Re-estimate models in order to paste coefficient values into excel files

do code/export-regression-estimates-to-excel.do

*** Summarize weights and probabilities

do code/summarize-probabilities-and-weights.do
do code/person-centered-view-of-weights.do
do code/graph-probabilities-and-weights.do

/* 
*** Compare panel raw data files from NORC

***   Note: Need to use the -nostop- option because the -cf- command will 
***         cause the do-file to stop

do code/compare-panel-and-merged-single-year-files.do, nostop 
*/
