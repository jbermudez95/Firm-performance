/*
Name:			estimates.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates fixed-effects estimates presented in tables 6, 7, 8, 
				9, 10, 11, 12, 13, and 14 included in the Appendix of the paper the paper 
				"Firm performance and tax incentives: evidence from Honduras". 
Date:			November, 2021
Modified:		November, 2022
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
clear matrix
set more off

* Insert personal directories
if "`c(username)'" == "Owner" {
	global path "C:\Users\Owner\Desktop\Firm-performance"		
	global out  "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Firm-performance"		
	global out  "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
}	

* Global settings for tables and graphs aesthetic
global tab_details "f booktabs se(2) b(3) star(* 0.10 ** 0.05 *** 0.01)"
global graphop     "legend(region(lcolor(none))) graphr(color(white))"

* Global settings for regressions
global probit_covariates "final_log_age i.final_mnc i.trader legal_attorneys ever_audited_times i.urban ib3.tamaño_ot i.activity_sector"
local outcomes1 "final_log_fixed_assets final_log_value_added final_log_employment final_log_salary tfp_y_LP tfp_y_ACF"	
local outcomes2 "final_epm final_roa final_eta final_gfsal final_turnover final_liquidity"
global controls "final_log_age final_export_share final_import_share final_capital_int final_labor_int final_log_total_sales"
global fixed_ef "ib(freq).codigo year municipality" 

* Run the do file that prepare all variables before estimations
run "$path\2. setup.do" 
xtset id year, yearly

	

*************************************************************************
*******  PROBIT ESTIMATES 
*************************************************************************

* This section conducts regressions to identify the covariates determining becoming an exonerated firm
eststo drop *

qui probit exempt_export ${probit_covariates}, vce(robust)
eststo m_export: qui margins, dydx(*)

qui probit exempt_non_export ${probit_covariates}, vce(robust)
eststo m_non_export: qui margins, dydx(*)

coefplot (m_export, label("Export Oriented") mcolor(blue%70) ciopts(lcolor(blue%70))) ///
		 (m_non_export, label("Non-Export Oriented") mcolor(orange%60) ciopts(lcolor(orange%60))), ///
		 drop(_cons exempt_export exempt_non_export i0.final_mnc i0.trader i0.legal_proxy i0.ever_audited i0.urban) ///
		 groups(*tamaño_ot* = "Firm Size" *activity_sector* = "Economic Activity", labsize(small) gap(2)) ///
		 coeflabels(final_log_age = "Age" 1.trader = "Foreign trade activity" 1.urban = "Main urban cities") ///
		 xline(0, lc(black)) label legend(region(lcolor(none))) graphr(color(white))
		 graph export "$out/probit_both.pdf", replace
		 graph close _all	
		
		
*************************************************************************
******* BASELINE ESTIMATES
*************************************************************************	

eststo drop *

* Primary outcomes
foreach var of local outcomes1 {
	eststo eq1a_`var': qui reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1a_`var'
	estadd loc muni_fe   "\cmark": eq1a_`var'
	estadd loc year_fe   "\cmark": eq1a_`var'
	estadd loc controls  "\cmark": eq1a_`var'
}

esttab eq1a_* using "$out\reg_baseline_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated") ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")

* Secondary outcomes
foreach var of local outcomes2 {
	eststo eq2a_`var': qui reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2a_`var'
	estadd loc muni_fe   "\cmark": eq2a_`var'
	estadd loc year_fe   "\cmark": eq2a_`var'
	estadd loc controls  "\cmark": eq2a_`var'
}

esttab eq2a_* using "$out\reg_baseline_secondary.tex", replace ${tab_details} ///
	   mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated") ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	  

	  
*************************************************************************
******* PRIMARY OUTCOMES AND PROFITABILITY
*************************************************************************

****** Parametric ******
eststo drop *
gen interaction1 = cit_exonerated * final_epm
gen interaction2 = cit_exonerated * final_roa

preserve
qui sum final_epm, d
drop if final_epm > r(p95)
foreach var of local outcomes1 {	
	eststo eq1_`var': qui reghdfe `var' interaction1 cit_exonerated final_epm ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1_`var'
	estadd loc muni_fe   "\cmark": eq1_`var'
	estadd loc year_fe   "\cmark": eq1_`var'
	estadd loc controls  "\xmark": eq1_`var'
}
restore

preserve
qui sum final_roa, d
drop if final_roa > r(p95)
foreach var of local outcomes1 {	
	eststo eq2_`var': qui reghdfe `var' interaction2 cit_exonerated final_roa ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2_`var'
	estadd loc muni_fe   "\cmark": eq2_`var'
	estadd loc year_fe   "\cmark": eq2_`var'
	estadd loc controls  "\xmark": eq2_`var'	
}
restore

esttab eq1_* using "$out\reg_profitability.tex", replace ${tab_details} refcat(interaction1 "\textsc{\textbf{Panel A}}", nolabel) ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") keep(interaction1 cit_exonerated final_epm) ///
	   coeflabels(interaction1 "Exonerated $\times$ EPM" cit_exonerated "Exonerated" final_epm "EPM") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	   
esttab eq2_* using "$out\reg_profitability.tex", append ${tab_details} refcat(interaction2 "\textsc{\textbf{Panel B}}", nolabel) ///
	   eqlabels(none) nomtitles nonumber keep(interaction2 cit_exonerated final_roa) ///
	   coeflabels(interaction2 "Exonerated $\times$ ROA" cit_exonerated "Exonerated" final_roa "ROA") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")	   


	   
****** Non parametric ******
eststo drop *
foreach var_ind of varlist final_epm final_roa {
	
preserve
qui sum `var_ind', d
drop if `var_ind' > r(p95)

foreach var of local outcomes1 {
	
	if "`var_ind'" == "final_epm" & "`var'" == "final_log_fixed_assets" {
	    local yx "-2 0.18"
		local title "epm_assets"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "final_log_fixed_assets" {
	    local yx "0.7 0.25"
		local title "roa_assets"
	}
	else if "`var_ind'" == "final_epm" & "`var'" == "final_log_value_added" {
	    local yx "1 0.18"
		local title "epm_value_added"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "final_log_value_added" {
	    local yx "-1.5 0.25"
		local title "roa_value_added"
	} 
	else if "`var_ind'" == "final_epm" & "`var'" == "final_log_employment" {
	    local yx "1.5 0.18"
		local title "epm_employment"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "final_log_employment" {
	    local yx "1.5 0.25"
		local title "roa_employment"
	} 
	else if "`var_ind'" == "final_epm" & "`var'" == "final_log_salary" {
	    local yx  "-0.05 0.18"
		local title "epm_salary"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "final_log_salary" {
	    local yx  "-0.05 0.25"
		local title "roa_salary"
	} 
	else if "`var_ind'" == "final_epm" & "`var'" == "tfp_y_LP" {
	    local yx "0.8 0.18"
		local title "epm_tfp_LP"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "tfp_y_LP" {
	    local yx "-1.2 0.25"
		local title "roa_tfp_LP"
	}
	else if "`var_ind'" == "final_epm" & "`var'" == "tfp_y_ACF" {
	    local yx "0.8 0.18"
		local title "epm_tfp_ACF"
	} 
	else if "`var_ind'" == "final_roa" & "`var'" == "tfp_y_ACF" {
	    local yx "-1.2 0.25"
		local title "roa_tfp_ACF"
	} 
	
	loc labvar1: var label `var_ind'
	loc labvar2: var label `var'
		
	qui reghdfe `var' cit_exonerated, a(${fixed_ef}) vce(cluster id) residuals(r_`var')
	
	qui reg r_`var' `var_ind' if cit_exonerated == 1, robust
	loc b1: di %3.2f _b[`var_ind']
	loc s1: di %3.2f _se[`var_ind']  
	   
	binscatter r_`var' `var_ind' if cit_exonerated == 1, nquantiles(100) $graphop ///
	text(`yx' "Slope = `b1'(`s1')", color(black)) yscale(titlegap(3)) mcolors(blue%20) lcolors(blue) ///
	xtitle(`"`labvar1'"') ytitle(`"Residuals for `labvar2'"') xscale(titlegap(3)) legend(off) 
	graph export "$out\resid_`title'.pdf", replace
	graph close _all
	
}
restore
}


	
*************************************************************************
******* HETEROGENEITY
*************************************************************************

* Primary outcomes
eststo drop *
foreach var of local outcomes1 {
	eststo eq1a_`var': qui reghdfe `var' cit_exonerated ${controls} if exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1a_`var'
	estadd loc muni_fe   "\cmark": eq1a_`var'
	estadd loc year_fe   "\cmark": eq1a_`var'
	estadd loc controls  "\cmark": eq1a_`var'
	
	eststo eq1b_`var': qui reghdfe `var' cit_exonerated ${controls} if non_exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1b_`var'
	estadd loc muni_fe   "\cmark": eq1b_`var'
	estadd loc year_fe   "\cmark": eq1b_`var'
	estadd loc controls  "\cmark": eq1b_`var'	
	
	eststo eq1c_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1c_`var'
	estadd loc muni_fe   "\cmark": eq1c_`var'
	estadd loc year_fe   "\cmark": eq1c_`var'
	estadd loc controls  "\cmark": eq1c_`var'
	
	eststo eq1d_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 2, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1d_`var'
	estadd loc muni_fe   "\cmark": eq1d_`var'
	estadd loc year_fe   "\cmark": eq1d_`var'
	estadd loc controls  "\cmark": eq1d_`var'
	
	eststo eq1e_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 3, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1e_`var'
	estadd loc muni_fe   "\cmark": eq1e_`var'
	estadd loc year_fe   "\cmark": eq1e_`var'
	estadd loc controls  "\cmark": eq1e_`var'
}

esttab eq1a_* using "$out\reg_hetero_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A: Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1b_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Non Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	 
	   
esttab eq1c_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Agricultural, extraction}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1d_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Industry}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	   
	   
esttab eq1e_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel E: Services}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")		
	   
	   
* Secondary outcomes
eststo drop *	   
foreach var of local outcomes2 {	
	eststo eq2a_`var': qui reghdfe `var' cit_exonerated ${controls} if exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2a_`var'
	estadd loc muni_fe   "\cmark": eq2a_`var'
	estadd loc year_fe   "\cmark": eq2a_`var'
	estadd loc controls  "\cmark": eq2a_`var'
	
	eststo eq2b_`var': qui reghdfe `var' cit_exonerated ${controls} if non_exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2b_`var'
	estadd loc muni_fe   "\cmark": eq2b_`var'
	estadd loc year_fe   "\cmark": eq2b_`var'
	estadd loc controls  "\cmark": eq2b_`var'
	
	eststo eq2c_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2c_`var'
	estadd loc muni_fe   "\cmark": eq2c_`var'
	estadd loc year_fe   "\cmark": eq2c_`var'
	estadd loc controls  "\cmark": eq2c_`var'
	
	eststo eq2d_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 2, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2d_`var'
	estadd loc muni_fe   "\cmark": eq2d_`var'
	estadd loc year_fe   "\cmark": eq2d_`var'
	estadd loc controls  "\cmark": eq2d_`var'
	
	eststo eq2e_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 3, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2e_`var'
	estadd loc muni_fe   "\cmark": eq2e_`var'
	estadd loc year_fe   "\cmark": eq2e_`var'
	estadd loc controls  "\cmark": eq2e_`var'
}

esttab eq2a_* using "$out\reg_hetero_secondary.tex", replace ${tab_details} ///
       mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A: Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2b_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Non Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2c_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Agricultural, extraction}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	
	   
esttab eq2d_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Industry}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")		   
	   
esttab eq2e_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel E: Services}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")		


	   
*************************************************************************
******* ROHBUSTNES: ALTERNATIVE SPECIFICATIONS
*************************************************************************

eststo drop *

* Primary outcomes
foreach var of local outcomes1 {
	eststo eq1a_`var': qui reghdfe `var' final_log_credits ${controls}, a(${fixed_ef}) vce(cluster id)
}	
















*************************************************************************
******* ROHBUSTNES: TAX CREDITS INSTEAD OF DUMMIES
*************************************************************************

eststo drop *

* Primary outcomes
foreach var of local outcomes1 {
	eststo eq1a_`var': qui reghdfe `var' final_log_credits ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq1a_`var'
	estadd loc muni_fe   "\cmark": eq1a_`var'
	estadd loc year_fe   "\cmark": eq1a_`var'
	estadd loc controls  "\cmark": eq1a_`var'
}

esttab eq1a_* using "$out\reg_credits_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits) coeflabels(final_log_credits "Exemption credits (logs)") ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")

* Secondary outcomes
foreach var of local outcomes2 {
	eststo eq2a_`var': qui reghdfe `var' final_log_credits ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark": eq2a_`var'
	estadd loc muni_fe   "\cmark": eq2a_`var'
	estadd loc year_fe   "\cmark": eq2a_`var'
	estadd loc controls  "\cmark": eq2a_`var'
}

esttab eq2a_* using "$out\reg_credits_secondary.tex", replace ${tab_details} ///
	   mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits) coeflabels(final_log_credits "Exemption credits (logs)") ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	   


/*************************************************************************
*******                    APPENDIX ESTIMATES                     ******* 
*************************************************************************

* Hausman test for random vs fixed effects on baseline estimates
xtset id year
foreach var of varlist final_gpm final_npm 									///
					   final_epm final_roa final_roce                       ///
					   final_eta final_gfsal final_turnover final_liquidity ///
					   final_lproductivity final_tfp_y final_tfp_va {
					   
	qui xtreg `var' cit_exonerated, fe
	estimates store fe_`var'
	qui xtreg `var' cit_exonerated, re
	estimates store re_`var'
	
	qui hausman fe_`var' re_`var'
	loc chi = r(chi2)
	loc p   = r(p)
	
	mat haus = nullmat(haus) \ (`chi', `p')
}

frmttable using "$out/haus.tex", replace statmat(hausman_table) tex vline(001) /// 
ctitle("Variable","$\chi^2$","p-value") fr basefont(tiny) sd(3,3)                         ///
rtitles(GPM\NPM\EPM\ROA\ROCE\ETA\GFSAL\Turnover\Liquidity\Labor Productivity\TFP on sales\TFP on Value Added) 
