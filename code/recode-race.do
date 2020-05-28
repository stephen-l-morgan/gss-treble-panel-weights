********************************************************************************
*** Recode race-ethnicity
********************************************************************************

********************************************************************************
*** Create hispanic dummy from census hispanic question (GSS 2000 and beyond)
********************************************************************************

recode hispanic (1 = 0) (./.z = .) (else = 1), gen(hisp)
tab hispanic hisp, m

recode hispanic_pl (1 = 0) (./.z = .) (else = 1), gen(hisp_pl)
tab hispanic hisp_pl, m

tab hisp hisp_pl, m

********************************************************************************
*** Create traditional racehisp variables with four categories
********************************************************************************

*** define label for categories

la de racehisp 1 White 2 Black 3 Hispanic 4 Other

// Note: The variable hispanic, which explicitly identifies whether R 
//       self-identifies as Hispanic, was first created for the 2000 GSS. See 
//       above.
//         
//       As an alternative way to identify Hispanics for earlier years, 
//       we use the eth1-3 vasr, which contain information on R's 
//       country of family origin.  With this variable, we can code R's who  
//       offer as countries Mexico, Puerto Rico, Spain, and other Spanish 
// 		 to be Hispanics for all GSS years.  
//
//       A tabulation of ethnic by hispanic from 2000 onward suggests that this 
//       has some error, but that it works fairly well.

*** Create racehisp (for 2000 and later) 

gen racehisp = .  
* white, non-Hispanic 
replace racehisp = 1 if race == 1 & (hisp == 0 | hisp == .)
* black is black, regardless of response to hispanic question 
replace racehisp = 2 if race == 2  
* hispanic if explicit choice of hispanic ethnicity 
replace racehisp = 3 if (race == 1 | race == 3) & hisp == 1
* other and non-Hispanic 
replace racehisp = 4 if race == 3 & (hisp == 0 | hisp == .)
* set pre-2000 years to missing
replace racehisp = . if year < 2000 

gen racehisp_pl = .  
* white, non-Hispanic 
replace racehisp_pl = 1 if race_pl == 1 & (hisp_pl == 0 | hisp_pl == .)
* black is black, regardless of response to hispanic question 
replace racehisp_pl = 2 if race_pl == 2  
* hispanic if explicit choice of hispanic ethnicity 
replace racehisp_pl = 3 if (race_pl == 1 | race_pl == 3) & hisp_pl == 1
* other and non-Hispanic 
replace racehisp_pl = 4 if race_pl == 3 & (hisp_pl == 0 | hisp_pl == .)
* set pre-2000 years to missing
replace racehisp_pl = . if year < 2000 

la val racehisp racehisp_pl racehisp
la var racehisp "4 cat race and hispanic, 2000 onward"
la var racehisp_pl "4 cat race and hispanic, 2000 onward, with panel fill-in"
tab racehisp racehisp_pl, m nol

*** Generate ethhisp var using the ethnic vars that are available for all years
***  eth1 through eth3 are countries listeed 
*** (ethnic is pnly the country closest to, which is less helpful for this task)

recode eth1 (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth1hisp)
recode eth2 (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth2hisp)
recode eth3 (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth3hisp)
recode eth1_pl (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth1hisp_pl)
recode eth2_pl (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth2hisp_pl)
recode eth3_pl (17 22 25 38 = 1) (./.z = .) (else = 0), gen(eth3hisp_pl)

gen eth_miss = (eth1 >= . & eth2 >= . & eth3 >= .)
gen eth_pl_miss = (eth1_pl >= . & eth2_pl >= . & eth3_pl >= .)

gen ethhisp = (eth1hisp == 1 | eth2hisp == 1 | eth3hisp == 1) if eth_miss == 0
gen ethhisp_pl = (eth1hisp_pl == 1 | eth2hisp_pl == 1 | eth3hisp_pl == 1) ///
                 if eth_pl_miss == 0

drop eth_miss eth_pl_miss

tab eth1 eth1hisp, m
tab eth2 eth2hisp, m
tab eth3 eth3hisp, m

tab ethnic ethhisp, m
tab ethnic_pl ethhisp_pl, m
tab ethhisp ethhisp_pl, m nol

*** Create racehisp_ay (has a consistent coding for all years)

gen racehisp_ay = .  
* white, non-Hispanic 
replace racehisp_ay = 1 if race == 1 & (ethhisp == 0 | ethhisp == .)
* black is black, regardless of response to hispanic question 
replace racehisp_ay = 2 if race == 2  
* hispanic if explicit choice of hispanic ethnicity 
replace racehisp_ay = 3 if (race == 1 | race == 3) & ethhisp == 1
* other and non-Hispanic 
replace racehisp_ay = 4 if race == 3 & (ethhisp == 0 | ethhisp == .) 

gen racehisp_ay_pl = .  
* white, non-Hispanic 
replace racehisp_ay_pl = 1 if race_pl == 1 & (ethhisp_pl == 0 | ethhisp_pl == .)
* black is black, regardless of response to hispanic question 
replace racehisp_ay_pl = 2 if race_pl == 2  
* hispanic if explicit choice of hispanic ethnicity 
replace racehisp_ay_pl = 3 if (race_pl == 1 | race_pl == 3) & ethhisp_pl == 1
* other and non-Hispanic 
replace racehisp_ay_pl = 4 if race_pl == 3 & (ethhisp_pl == 0 | ethhisp_pl == .) 

*** label and check
la val racehisp_ay racehisp_ay_pl racehisp

tab racehisp_ay ethhisp, m
tab racehisp_ay racehisp if year <= 1998, m
tab racehisp_ay racehisp if year >= 2000, m
tab ethhisp hisp if year > 2000, m  // most missing eth_hisp are not hispanic
tab ethhisp_pl hisp_pl if year > 2000, m

bys year:  tab racehisp racehisp_ay, miss cell

********************************************************************************
*** Create ACS-type summary dummies from census race questions (2000 and beyond)
********************************************************************************

*  Note:  More missing in 2000 for these vars than for other years

tab racecen1 year
tab racecen1 year, nol
tab racecen2 year
tab racecen2 year, nol
tab racecen3 year
tab racecen3 year, nol

//  Selection across each question

gen white1 = (racecen1 == 1) if racecen1 < . 
gen white2 = (racecen2 == 1) if racecen2 < .
gen white3 = (racecen3 == 1) if racecen3 < .

gen black1 = (racecen1 == 2) if racecen1 < .
gen black2 = (racecen2 == 2) if racecen2 < .
gen black3 = (racecen3 == 2) if racecen3 < .

gen aian1 = (racecen1 == 3) if racecen1 < .
gen aian2 = (racecen2 == 3) if racecen2 < .
gen aian3 = (racecen3 == 3) if racecen3 < .

gen asian1 = (racecen1 >= 4 & racecen1 <= 10) if racecen1 < .
gen asian2 = (racecen2 >= 4 & racecen2 <= 10) if racecen2 < .
gen asian3 = (racecen3 >= 4 & racecen3 <= 10) if racecen3 < .

gen nhpi1 = (racecen1 >= 11 & racecen1 <= 14) if racecen1 < .
gen nhpi2 = (racecen2 >= 11 & racecen2 <= 14) if racecen2 < .
gen nhpi3 = (racecen3 >= 11 & racecen3 <= 14) if racecen3 < .

gen othr1 = (racecen1 == 15) if racecen1 < .
gen othr2 = (racecen2 == 15) if racecen2 < .
gen othr3 = (racecen3 == 15) if racecen3 < .

gen hispr1 = (racecen1 == 16) if racecen1 < .
gen hispr2 = (racecen2 == 16) if racecen2 < .
gen hispr3 = (racecen3 == 16) if racecen3 < .

gen racecen_miss = (racecen1 >= . & racecen2 >= . & racecen3 >= .)

// Every selected race

gen white = (white1==1 | white2==1 | white3==1) if racecen_miss == 0
gen black = (black1==1 | black2==1 | black3==1) if racecen_miss == 0
gen aian  = (aian1==1  | aian2==1  | aian3==1) if racecen_miss == 0
gen asian = (asian1==1 | asian2==1 | asian3==1) if racecen_miss == 0
gen nhpi  = (nhpi1==1  | nhpi2==1  | nhpi3==1) if racecen_miss == 0
gen othr  = (othr1==1  | othr2==1  | othr3==1) if racecen_miss == 0
gen hispr = (hispr1==1  | hispr2==1  | hispr3==1) if racecen_miss == 0

//  Only selected race

gen white_o = (white==1 & black==0 & aian==0 & asian==0 & /// 
                 nhpi==0 & othr==0 & hispr==0) if racecen_miss == 0
gen black_o = (white==0 & black==1 & aian==0 & asian==0 & /// 
                 nhpi==0 & othr==0 & hispr==0) if racecen_miss == 0
gen aian_o  = (white==0 & black==0 & aian==1 & asian==0 & /// 
                 nhpi==0 & othr==0 & hispr==0) if racecen_miss == 0
gen asian_o = (white==0 & black==0 & aian==0 & asian==1 & /// 
                 nhpi==0 & othr==0 & hispr==0) if racecen_miss == 0
gen nhpi_o = (white==0 & black==0 & aian==0 & asian==0 & /// 
                 nhpi==1 & othr==0 & hispr==0) if racecen_miss == 0
gen othr_o  = (white==0 & black==0 & aian==0 & asian==0 & /// 
                 nhpi==0 & othr==1 & hispr==0) if racecen_miss == 0
gen hispr_o = (white==0 & black==0 & aian==0 & asian==0 & /// 
                 nhpi==0 & othr==0 & hispr==1) if racecen_miss == 0
				 
forval i = 1/3 {
	foreach var in white black aian nhpi othr hispr {
		drop `var'`i'
		}
}

//  Multiplied by hisp ethnicity nomination

gen white_o_nh = (white_o == 1 & hisp == 0) if racecen_miss == 0 & hisp < .
gen white_nh   = (white == 1   & hisp == 0) if racecen_miss == 0 & hisp < .
gen black_o_nh = (black_o == 1 & hisp == 0) if racecen_miss == 0 & hisp < .
gen black_nh   = (black == 1   & hisp == 0) if racecen_miss == 0 & hisp < .
gen aian_o_nh  = (aian_o == 1  & hisp == 0) if racecen_miss == 0 & hisp < .
gen aian_nh    = (aian == 1    & hisp == 0) if racecen_miss == 0 & hisp < .
gen asian_o_nh = (asian_o == 1 & hisp == 0) if racecen_miss == 0 & hisp < .
gen asian_nh   = (asian == 1   & hisp == 0) if racecen_miss == 0 & hisp < .
gen nhpi_o_nh  = (nhpi_o == 1  & hisp == 0) if racecen_miss == 0 & hisp < .
gen nhpi_nh    = (nhpi == 1    & hisp == 0) if racecen_miss == 0 & hisp < .
gen othr_o_nh  = (othr_o == 1  & hisp == 0) if racecen_miss == 0 & hisp < .
gen othr_nh    = (othr == 1    & hisp == 0) if racecen_miss == 0 & hisp < .
gen hispr_o_nh = (hispr_o == 1 & hisp == 0) if racecen_miss == 0 & hisp < .
gen hispr_nh   = (hispr == 1   & hisp == 0) if racecen_miss == 0 & hisp < .

gen white_o_h = (white_o == 1 & hisp == 1) if racecen_miss == 0 & hisp < .
gen white_h   = (white == 1   & hisp == 1) if racecen_miss == 0 & hisp < .
gen black_o_h = (black_o == 1 & hisp == 1) if racecen_miss == 0 & hisp < .
gen black_h   = (black == 1   & hisp == 1) if racecen_miss == 0 & hisp < .
gen aian_o_h  = (aian_o == 1  & hisp == 1) if racecen_miss == 0 & hisp < .
gen aian_h    = (aian == 1    & hisp == 1) if racecen_miss == 0 & hisp < .
gen asian_o_h = (asian_o == 1 & hisp == 1) if racecen_miss == 0 & hisp < .
gen asian_h   = (asian == 1   & hisp == 1) if racecen_miss == 0 & hisp < .
gen nhpi_o_h  = (nhpi_o == 1  & hisp == 1) if racecen_miss == 0 & hisp < .
gen nhpi_h    = (nhpi == 1    & hisp == 1) if racecen_miss == 0 & hisp < .
gen othr_o_h  = (othr_o == 1  & hisp == 1) if racecen_miss == 0 & hisp < .
gen othr_h    = (othr == 1    & hisp == 1) if racecen_miss == 0 & hisp < .
gen hispr_o_h = (hispr_o == 1 & hisp == 1) if racecen_miss == 0 & hisp < .
gen hispr_h   = (hispr == 1   & hisp == 1) if racecen_miss == 0 & hisp < .

drop racecen_miss

summ hisp-hispr_h if year>=2004 [aw=wtssnr]


// *** _pl version ****************************************************************
//
// tab racecen1_pl year
// tab racecen1_pl year, nol
// tab racecen2_pl year
// tab racecen2_pl year, nol
// tab racecen3_pl year
// tab racecen3_pl year, nol
//
// //  Selection across each question
//
// gen white1_pl = (racecen1_pl == 1) if racecen1_pl < . 
// gen white2_pl = (racecen2_pl == 1) if racecen2_pl < .
// gen white3_pl = (racecen3_pl == 1) if racecen3_pl < .
//
// gen black1_pl = (racecen1_pl == 2) if racecen1_pl < .
// gen black2_pl = (racecen2_pl == 2) if racecen2_pl < .
// gen black3_pl = (racecen3_pl == 2) if racecen3_pl < .
//
// gen aian1_pl = (racecen1_pl == 3) if racecen1_pl < .
// gen aian2_pl = (racecen2_pl == 3) if racecen2_pl < .
// gen aian3_pl = (racecen3_pl == 3) if racecen3_pl < .
//
// gen asian1_pl = (racecen1 >= 4 & racecen1 <= 10) if racecen1_pl < .
// gen asian2_pl = (racecen2 >= 4 & racecen2 <= 10) if racecen2_pl < .
// gen asian3_pl = (racecen3 >= 4 & racecen3 <= 10) if racecen3_pl < .
//
// gen nhpi1_pl = (racecen1_pl >= 11 & racecen1_pl <= 14) if racecen1_pl < .
// gen nhpi2_pl = (racecen2_pl >= 11 & racecen2_pl <= 14) if racecen2_pl < .
// gen nhpi3_pl = (racecen3_pl >= 11 & racecen3_pl <= 14) if racecen3_pl < .
//
// gen othr1_pl = (racecen1_pl == 15) if racecen1_pl < .
// gen othr2_pl = (racecen2_pl == 15) if racecen2_pl < .
// gen othr3_pl = (racecen3_pl == 15) if racecen3_pl < .
//
// gen hispr1_pl = (racecen1_pl == 16) if racecen1_pl < .
// gen hispr2_pl = (racecen2_pl == 16) if racecen2_pl < .
// gen hispr3_pl = (racecen3_pl == 16) if racecen3_pl < .
//
// gen racecen_miss_pl = (racecen1_pl >= . & racecen2_pl >= . & racecen3_pl >= .)
//
// // Every selected race
//
// gen white_pl = (white1_pl==1 | white2_pl==1 | white3_pl==1) if racecen_miss_pl == 0
// gen black_pl = (black1_pl==1 | black2_pl==1 | black3_pl==1) if racecen_miss_pl == 0
// gen aian_pl  = (aian1_pl==1  | aian2_pl==1  | aian3_pl==1) if racecen_miss_pl == 0
// gen asian_pl = (asian1_pl==1 | asian2_pl==1 | asian3_pl==1) if racecen_miss_pl == 0
// gen nhpi_pl  = (nhpi1_pl==1  | nhpi2_pl==1  | nhpi3_pl==1) if racecen_miss_pl == 0
// gen othr_pl  = (othr1_pl==1  | othr2_pl==1  | othr3_pl==1) if racecen_miss_pl == 0
// gen hispr_pl = (hispr1_pl==1  | hispr2_pl==1  | hispr3_pl==1) if racecen_miss_pl == 0
//
// //  Only selected race
//
// gen white_o_pl = (white_pl==1 & black_pl==0 & aian_pl==0 & asian_pl==0 & /// 
//                  nhpi_pl==0 & othr_pl==0 & hispr_pl==0) if racecen_miss_pl == 0
// gen black_o_pl = (white_pl==0 & black_pl==1 & aian_pl==0 & asian_pl==0 & /// 
//                  nhpi_pl==0 & othr_pl==0 & hispr_pl==0) if racecen_miss_pl == 0
// gen aian_o_pl  = (white_pl==0 & black_pl==0 & aian_pl==1 & asian_pl==0 & /// 
//                  nhpi_pl==0 & othr_pl==0 & hispr_pl==0) if racecen_miss_pl == 0
// gen asian_o_pl = (white_pl==0 & black_pl==0 & aian_pl==0 & asian_pl==1 & /// 
//                  nhpi_pl==0 & othr_pl==0 & hispr_pl==0) if racecen_miss_pl == 0
// gen nhpi_o_pl = (white_pl==0 & black_pl==0 & aian_pl==0 & asian_pl==0 & /// 
//                  nhpi_pl==1 & othr_pl==0 & hispr_pl==0) if racecen_miss_pl == 0
// gen othr_o_pl  = (white_pl==0 & black_pl==0 & aian_pl==0 & asian_pl==0 & /// 
//                  nhpi_pl==0 & othr_pl==1 & hispr_pl==0) if racecen_miss_pl == 0
// gen hispr_o_pl = (white_pl==0 & black_pl==0 & aian_pl==0 & asian_pl==0 & /// 
//                  nhpi_pl==0 & othr_pl==0 & hispr_pl==1) if racecen_miss_pl == 0
//				 
// forval i = 1/3 {
// 	foreach var in white black aian nhpi othr hispr {
// 		drop `var'`i'_pl
// 		}
// }
//
// //  Multiplied by hisp ethnicity nomination
//
// gen white_o_nh_pl = (white_o_pl == 1 & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen white_nh_pl   = (white_pl == 1   & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen black_o_nh_pl = (black_o_pl == 1 & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen black_nh_pl   = (black_pl == 1   & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen aian_o_nh_pl  = (aian_o_pl == 1  & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen aian_nh_pl    = (aian_pl == 1    & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen asian_o_nh_pl = (asian_o_pl == 1 & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen asian_nh_pl   = (asian_pl == 1   & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen nhpi_o_nh_pl  = (nhpi_o_pl == 1  & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen nhpi_nh_pl    = (nhpi_pl == 1    & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen othr_o_nh_pl  = (othr_o_pl == 1  & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen othr_nh_pl    = (othr_pl == 1    & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen hispr_o_nh_pl = (hispr_o_pl == 1 & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
// gen hispr_nh_pl   = (hispr_pl == 1   & hisp_pl == 0) if racecen_miss_pl == 0 & hisp_pl < .
//
// gen white_o_h_pl = (white_o_pl == 1 & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen white_h_pl   = (white_pl == 1   & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen black_o_h_pl = (black_o_pl == 1 & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen black_h_pl   = (black_pl == 1   & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen aian_o_h_pl  = (aian_o_pl == 1  & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen aian_h_pl    = (aian_pl == 1    & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen asian_o_h_pl = (asian_o_pl == 1 & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen asian_h_pl   = (asian_pl == 1   & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen nhpi_o_h_pl  = (nhpi_o_pl == 1  & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen nhpi_h_pl    = (nhpi_pl == 1    & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen othr_o_h_pl  = (othr_o_pl == 1  & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen othr_h_pl    = (othr_pl == 1    & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen hispr_o_h_pl = (hispr_o_pl == 1 & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
// gen hispr_h_pl   = (hispr_pl == 1   & hisp_pl == 1) if racecen_miss_pl == 0 & hisp_pl < .
//
// drop racecen_miss_pl
//
// summ hisp_pl-hispr_h_pl if year>=2004 [aw=wtssnr]


		 
