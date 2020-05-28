qui ds 
local varlist `r(varlist)'

foreach var in `varlist' {
	qui sum `var'
		if r(N)==0 | r(Var)==0 {
			drop `var'
} 		
		else if r(N)!=0 & r(Var)!=0 {
			qui replace `var' =. if `var' >=. | `var' < 0
} 
}

