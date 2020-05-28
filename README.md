# gss-treble-panel-weights

## Overview

This repository includes files that estimate probabilities of attrition for GSS base year respondents who participated in the GSS treble panel from 2006 through 2014. It then uses these estimated probabilities to construct six panel weights.  

The weights that are estimated are available in four files in the data folder of the repository:

	Stata data files:
		data/gss-treble-panel-weights-wide.dta
		data/gss-treble-panel-weights-long.dta
	
	Comma-separated value files:
		data/gss-treble-panel-weights-wide.csv
		data/gss-treble-panel-weights-long.csv

They can also be downloaded from the associated OSF project page: <https://osf.io/yhdj2/>

## roadmap-of-code-for-treble-panel-weights.txt

The content below is copied from the file, roadmap-of-code-for-treble-panel-weights.txt, which can be found in the docs folder of the repository.

### Notes

A.  The working directory in Stata should be set to the top directory (i.e., the one that includes the folders: code, data, docs, graph, log, tmp).  If using as a GitHub repository, and when stored locally in a folder "GitHub," the working directory would be set as the main repository folder for the project:

    GitHub/gss-panel-weights

preceded, as necessary, by any machine-specific location information that indicates where the GitHub folder is located.

B.  The GSS files distributed by NORC are assumed to be stored in an adjacent directory, gss-from-norc, that sits alongside the main project folder.  The do files call these files using the .. prefix to define the path for each file relative to the working directory (see above).  In order to run all do files in the project, the user needs to create such a directory with this name and place the GSS files from NORC in that folder.

C.  The do files must be run in order and can be run with the file:

    do-all-to-create-panel-attrition-weights.do

D.  The final do files, in brackets, are optional and generate additional output and file comparisons.  They are not necessary for the estimation of attrition probabilities or subsequent construction of the panel weights.

E.  The master branch of the public repositroy includes all data files internal to the repoosity (i.e., everything except the dta files in the gss-from-norc folder).  As a result, a user who only wishes to change the model specifications, etc., should be able to start from step 6 below.  


### Roadmap for the code

1. 	code/mk-gss-2006-2014-with-panel-fill-in.do, .log

Drop GSS cross-sectional data before 2006 and after 2014. Keep only the variables that will be used to impute item-specific missing values and/or construct attrition weights. Fill in missing values in the cross-sectional dataset using values from reinterviews for some variables that are plausibly constant (such as father's education).
 
	Takes in: 
		../gss-from-norc/GSS7218_R2.dta [external data] 
		../gss-from-norc/GSS_panel06w123_R6.dta [external data]
		../gss-from-norc/GSS_panel08w123_R6.dta [external data]
		../gss-from-norc/GSS_panel2010w123_R6.dta [external data]

	Yields:
		data/gss-2006-2014-with-panel-fill-in.dta

2.  code/mk-gss-2006-2014-fill-in-and-recoded.do, .log

Take the cross-sectional data with fill-in values and then merge in the single-year data files to construct three datasets with recoded variables. The datasets are: (1)  all cross-sectional respondents with variables recoded; (2) all cross-sectional respondents + panel respondents with variables recoded; (3) all panel respondents (all 3 waves, if available) in long form with variables recoded.

	Takes in:
		data/gss-2006-2014-with-panel-fill-in.dta [created in step 1]
		data/gssocc10-acsocc10-acsocc12-to-egp-crosswalk.dta [external data]

		../gss-from-norc/GSS_panel06w123_R6a.dta [external data]
		../gss-from-norc/GSS_panel08w123_R6.dta [external data]
		../gss-from-norc/GSS_panel2010w123_R6.dta [external data]

		../gss-from-norc/gss2008crosspanel_R6.dta [external data]
		../gss-from-norc/GSS2010merged_R8.dta [external data]
		../gss-from-norc/GSS2012merged_r10.dta [external data]	
		../gss-from-norc/gss2014merged_r10.dta [external data]
	
	Calls:
		code/recode-race.do
		code/recode-egp-class.do

	Yields:
		data/gss-2006-2014-fill-in-and-recoded.dta
		data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta 
		data/gss-panel-allyears-recoded-long.dta

3.  code/variables-to-impute.do, .log

Set up the data to export to R for imputation of remaining missing values.

	Takes in:
		data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta [created in step 2]

	Yields:
		data/gss-panel-vars-to-impute.dta
		data/gss-panel-vars-to-impute.csv 


#### The next step needs to be run in R:


4.  code/gss-impute-panel-missforest.R, .log

Implement random forest imputation to generate six sets of data, with imputed 
values for all missing values.

	Takes in:
		data/gss-panel-vars-to-impute.csv [created in step 3]

	Yields:
		data/gss-panel-vars-imputed-rf.dta

#### BACK to Stata:

5.  append-and-merge-imputed-datasets.do, .log

Append the imputed data to the original data, yielding 7 sets of data within one dataset.  Recode variables to set up regressors for modeling attrition probabilities.

	Takes in:
		data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta [created in step 2]
		data/gss-panel-vars-imputed-rf.dta [created in step 4]

	Calls:
		code/variable-and-value-labels.do

	Yields:
		data/gss-panel-2006-2014-imputed-recoded.dta

6.  code/estimate-attrition-probabilities.do, .log

Estimate models that predict panel attrition using Stata's multiple imputation version of logistic regression.  Save as two data sets (one that preserves all data from the original and six imputation sets along with estimated probabilities, and one that includes only the core id's, weights, panel attrition flags, and estimated probabilities). 

	Takes in:
		data/gss-panel-2006-2014-imputed-recoded.dta [created in step 5]

	Yields:
		data/gss-panel-2006-2014-attrition-pr-all-im.dta
		data/gss-panel-2006-2014-attrition-pr.dta

7.  code/create-panel-attrition-weights, .log

Create new weights and export summary statistics of the estimated attrition probabilites and subsequent weights to an excel spreadsheet.

	Takes in:
		data/gss-panel-2006-2014-attrition-pr-all-im.dta [created in step 6]
		data/gss-2006-2014-fill-in-and-recoded-panel-merged.dta [created in step 2]
		data/gss-panel-2006-2014-attrition-pr.dta [created in step 6]

	Yields:
		data/data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta

8.  code/create-and-demonstrate-usage-of-merge-file.do, .log

Write out small merge files and demonstrate code to merge with raw GSS panel data.

	Takes in:
		data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta [created in step 7]

	Yields:
		data/gss-treble-panel-weights-wide.dta
		data/gss-treble-panel-weights-wide.csv
		data/gss-treble-panel-weights-long.dta
		data/gss-treble-panel-weights-long.csv

#### Not essential to create the weights:

9.  code/export-regression-estimates-to-excel.do, .log

Export the logistic regression estimates used to calculate the attrition probabilities to excel spreadsheets.  This is not required to construct the weights, and it is placed as a separate step in this routine, using the dataset constructed in step 5, to build excel files that contain coefficient values.

	Takes in:
		data/gss-panel-2006-2014-imputed-recoded.dta [created in step 5]

	Yields: 
		docs/attr-weight-bivariate-all.xls
		docs/attr-weight-multivariate-pooled-all
		docs/attr-weight-multivariate-pooled_insc.xls
		docs/attr-weight-multivariate-p2006-all.xls
		docs/attr-weight-multivariate-p2006-insc.xls
		docs/attr-weight-multivariate-p2008-all
		docs/attr-weight-multivariate-p2008-insc.xls
		docs/attr-weight-multivariate-p2010-all.xls
		docs/attr-weight-multivariate-p2010-insc.xls

10.  code/summarize-probabilities-and-weights.do, log

Create an excel file with sheets that summarizes the estimated probabilities and constructed weights.

	Takes in:
		data/gss-panel-2006-2014-attrition-pr.dta [created in step 6]
		data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta [created in step 7]

	Yields:
		docs/summary-of-attrition-weights.xlsx

11.	code/person-centered-view-of-weights.do

Looking more closely.

	Takes in:
		data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta [created in step 7]

	Yields:
		docs/person-centered-view.csx

12.	code/graph-probabilities-and-weights.do, log

Creates Figures 1-4 for the GSS methodological report.

	Takes in:
		data/gss-panel-allyears-fill-in-and-recoded-panel-merged-wt.dta [created in step 7]

	Calls:
		code/settings-graph-s1-palatino.do

	Yields:
		graph/fig-1-probabilities-all.gph
		graph/fig-1-probabilities-all.pdf
		graph/fig-1-probabilities-all-1650-by-1200.png
		graph/fig-2-probabilities-insc.gph
		graph/fig-2-probabilities-insc.pdf
		graph/fig-2-probabilities-insc- 1650-by-1200.png
		graph/fig-3-weights.gph
		graph/fig-3-weights.pdf
		graph/fig-3-weights-1650-by-1200.png
		graph/fig-4-weights-logged.gph
		graph/fig-4-weights-logged.pdf
		graph/fig-4-weights-logged-1650-by-1200.png

13.  code/compare-panel-and-merged-single-year-files.do, .log

Compare panel datasets to the merged single year files to document differences.

	Takes in:
		../gss-from-norc/GSS7218_R1.DTA [external data] 
		../gss-from-norc/GSS_panel06w123_R6.dta [external data]
		../gss-from-norc/GSS_panel08w123_R6.dta [external data]
		../gss-from-norc/GSS_panel2010w123_R6.dta [external data]

		../gss-from-norc/gss2008crosspanel_R6.dta [external data]
		../gss-from-norc/GSS2010merged_R8.dta [external data]
		../gss-from-norc/GSS2012merged_r10.dta [external data]
		../gss-from-norc/gss2014merged_r10.dta	[external data]

	Calls:
		analysis/drop-not-aksed-and-replace-missing.do	

