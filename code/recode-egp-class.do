********************************************************************************
*** Descriptions of the EGP Class Schema (10, 11, and 12 class versions)
********************************************************************************

/*
EGP 12-Class Version:

  I        1:  Higher-grade professionals, administrators, managers, 
               and officials
		
  II       2:  Lower-grade professionals, administrators, managers, 
               and officials

  IIIa     3:  Routine non-manual and service employees, higher-grade

  IIIb     4:  Routine non-manual and service employees, lower-grade

  IVa      5:  Non-professional self-employed workers with employees

  IVb      6:  Non-professional self-employed workers without employees

  IVc      7:  Owners and managers of agricultural establishments

  V        8:  Higher-grade technicians and repairers, public safety workers, 
               performers, and supervisors of manual workers

  VI       9:  Skilled manual workers, lower-grade technicians, installers, 
               and repairers

  VIIa     10: Semiskilled and unskilled manual workers, not in agriculture

  VIIb     11: Agricultural workers and their first-line supervisors; other 
               workers in primary production 
		   
  Military 12: All military occupations

           *** Note: Because a measure of employees for self-employed workers 
			         is needed to differentiate class IVa from class IVb, the 
					 full 12-class version of EGP is only possible for the 
					 2004 GSS and later.  (The 12-class version is never possible
					 for spouses, fathers, or mothers.)
		  
EGP 11-Class Version:

   Combines IVa and IVb into IVab.  Values 5 and 6 are both set equal to 5 so 
   that
   
   IVab    5:  Non-professional self-employed workers

EGP 10-Class Version:

	Self-employed individuals remain in their occupations and are not moved to
	IVa and IVb.  Values 5 and 6 are not present.
*/

********************************************************************************
*** Merge GSS data with occupation-based EGP from ACS coding of occupations
********************************************************************************

*** Preserve GSS data already loaded in memory

preserve

********************************************************************************
*** Set up temporary merge files from the crosswalk file
********************************************************************************

*** Keep the only two variables in the crosswalk needed for the merge

tempfile crosswalk_vars_file
use data/gssocc10-acsocc10-acsocc12-to-egp-crosswalk.dta, replace
keep gssocc10 egp
save `crosswalk_vars_file'

*** R's occupation

tempfile occ10_crosswalk
use `crosswalk_vars_file', replace
rename (gssocc10 egp) (occ10_pl egp10_10)
save `occ10_crosswalk'

*** Spouse's occupation

tempfile spocc10_crosswalk
use `crosswalk_vars_file', replace
rename (gssocc10 egp) (spocc10_pl spegp10_10)
save `spocc10_crosswalk'

*** Father's occupation

tempfile paocc10_crosswalk
use `crosswalk_vars_file', replace
rename (gssocc10 egp) (paocc10_pl paegp10_10)
save `paocc10_crosswalk'

*** Mother's occupation

tempfile maocc10_crosswalk
use `crosswalk_vars_file', replace
rename (gssocc10 egp) (maocc10_pl maegp10_10)
save `maocc10_crosswalk'


********************************************************************************
*** Merge
********************************************************************************

*** Restore data in memory

restore

*** Merge using temporary files

merge m:1 occ10_pl using `occ10_crosswalk'

tab _merge
drop if _merge==2
drop _merge

merge m:1 spocc10_pl using `spocc10_crosswalk'

tab _merge
drop if _merge==2
drop _merge

merge m:1 paocc10_pl using `paocc10_crosswalk'

tab _merge
drop if _merge==2
drop _merge

merge m:1 maocc10_pl using `maocc10_crosswalk'

tab _merge
drop if _merge==2
drop _merge



********************************************************************************
*** Create 11-class version (with combined class IVab)
********************************************************************************

label define egproman11 1 "I" 2 "II" 3 "IIIa" 4 "IIIb" 5 "IVab" ///
  7 "IVc" 8 "V" 9 "VI" 10 "VIIa" 11 "VIIb" 12 "Military"
  
tab egp10_10, miss
tab numemps wrkslf, miss

gen egp10_11 = egp10_10
replace egp10_11 = 5 if egp10_10 != 1 & egp10_10 != 2 & egp10_10 != 7 ///
        & egp10_10 != 12 & egp10_10 != . & wrkslf_pl == 1 
label values egp10_11 egproman11
tab egp10_10 egp10_11, m
tab egp10_11 wrkslf, m
tab egp10_11 numemps, m
tab egp10_11 wrkstat, m
tab egp10_11 year, m

********************************************************************************
*** Create 12-class version (with classes IVa and IVb) [GSS 2004 and later only]
********************************************************************************

label define egproman12 1 "I" 2 "II" 3 "IIIa" 4 "IIIb" 5 "IVa" 6 "IVb" ///
  7 "IVc" 8 "V" 9 "VI" 10 "VIIa" 11 "VIIb" 12 "Military"

gen egp10_12 = egp10_10
replace egp10_12 = 5 if egp10_10 != 1 & egp10_10 != 2 & egp10_10 != 7 ///
 & egp10_10 != 12 & egp10_10 != . & wrkslf_pl == 1 & numemps_pl > 0 & numemps_pl < .
replace egp10_12 = 6 if egp10_10 != 1 & egp10_10 != 2 & egp10_10 != 7 ///
 & egp10_10 != 12 & egp10_10 != . & wrkslf_pl == 1 & numemps_pl==0
replace egp10_12 = . if year < 2004

label values egp10_12 egproman12
tab egp10_10 egp10_12, m
tab egp10_12 wrkslf_pl, m
tab egp10_12 numemps_pl, m
tab egp10_12 wrkstat, m
tab egp10_12 year, m

********************************************************************************
*** Create 11 class version (with IVab) for spouses, mothers, and fathers
********************************************************************************

foreach stub in sp pa ma {
	tab `stub'egp10_10, miss

	gen `stub'egp10_11 = `stub'egp10_10
	replace `stub'egp10_11 = 5 if `stub'egp10_10 != 1 & `stub'egp10_10 != 2 ///
	 & `stub'egp10_10 != 7 & `stub'egp10_10 != 12 & `stub'egp10_10 != . ///
	 & `stub'wrkslf_pl == 1 

	label values `stub'egp10_11 egproman11
	tab `stub'egp10_10 `stub'egp10_11, m
	tab `stub'egp10_11 `stub'wrkslf_pl, m
}


