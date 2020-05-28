*** VARIABLE AND VALUE LABELS

la var attr_w23 "Panel Attrition Indicator"
la var outsc_w2 "Out of scope by second wave"
la var outsc_w3 "Out of scope by second or third wave"
la var outsc_w23 "Out of scope by second or third wave"
la var age_o1 "Age: first polynomial"
la var age_o2 "Age: second polynomial"
la var age_o3 "Age: thir polynomial"
la var sex "Sex"
la var racehisp5 "Race/ethnicity"
la var degree "Education"
la var realinc "Real household income"
la var marital "Marital status"
la var borncitz "Citizenship status"
la var region "Region"
la var wordsum "Vocabulary knowledge"
la var intage "Interviewer's age"
la var intsex "Interviewer's sex"
la var intethn "Interviewer's race/ethnicity"
la var lngthinv "Length of interview"
la var daysint "Date of interview"
la var mode "Interview mode"
la var feeused "Fee used to interview"
la var coop "Rs Attitude toward the interview"
la var comprend "Rs understanding of the questions"
la var spaneng "Language of interview"
la var dwelown "R owns or rents home"

la def YESNO 0 "No" 1 "Yes"
la def SEX 1 "Male" 2 "Female"
la def RACEHISP5 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other"
la def DEGREE 0 "Less than HS" 1 "HS" 2 "Junior college" 3 "BA" 4 "Graduate"
la def MARITAL 1 "Married" 2 "Widowed" 3 "Divorced" 4 "Separated" ///
			   5 "Never married"
la def BORNCITZ 1 "Born in the US" 2 "Born outside but ever-citizen" ///
				3 "Never-citizen"
la def REGION 1 "New England" 2 "Middle Atlantic" 3 "East North Central" ///
		4 "West North Central" 5 "South Atlantic"  6 "East South Central" ///
		7 "West South Central" 8 "Mountain"  9 "Pacific"
la def INTSEX 1 "Male" 2 "Female"
la def INTETHN 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Two or more races"
la def MODE 1 "In person" 2 "Over the phone"
la def FEEUSED 1 "Money" 2 "Non-monetary" 3 " No"
la def COOP 1 "Friendly/interested" 2 "Cooperative" 3 "Restless/impatient" 4 "Hostile"
la def COMPREND 1 "Good" 2 "Fair" 3 "Poor"
la def SPANENG 1 "English" 2 "Spanish"
la def DWELOWN 1 "Own or is buying" 2 "Pays rent" 3 "Other"

la val attr_w23 outsc_w2 outsc_w3 outsc_w23 YESNO
 
foreach var in sex racehisp5 degree marital borncitz region intsex intethn ///
		mode feeused coop comprend spaneng dwelown {
				local varlable=upper("`var'")
				la val `var' `varlable'
		}
