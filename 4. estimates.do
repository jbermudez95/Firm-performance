/*
Name:			estimates.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates fixed-effects estimates presented in tables 6, 7, 8, 
				9, 10, 11, 12, 13, and 14 included in the Appendix of the paper the paper 
				"Firm performance and tax incentives: evidence from Honduras". 
Date:			November, 2021
Modified:		April, 2022
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

run "$path\2. setup.do" 	// Run the do file that prepare all variables for estimations

global details   "booktabs f se(2) b(3) nonumbers star staraux"
global options   "booktabs se(2) b(3) star staraux nomtitles"
global graphop   "grid(none) legend(region(lcolor(none))) graphr(color(white))"


*************************************************************************
*******                   PROBIT ESTIMATES                        ******* 
*************************************************************************

* This section conducts regressions to identify the covariates determining becoming an exonerated firm
global probit_covariates "final_log_age i.final_mnc i.trader legal_attorneys ever_audited_times i.urban ib3.tamaño_ot i.activity_sector"

eststo drop *

probit exempt_export ${probit_covariates}, vce(robust)
eststo m_export: qui margins, dydx(*)

probit exempt_non_export ${probit_covariates}, vce(robust)
eststo m_non_export: qui margins, dydx(*)

coefplot (m_export, label("Export Oriented") mcolor(blue%70) ciopts(lcolor(blue%70))) ///
		 (m_non_export, label("Non-Export Oriented") mcolor(orange%60) ciopts(lcolor(orange%60))), ///
		 drop(_cons exempt_export exempt_non_export i0.final_mnc i0.trader i0.legal_proxy i0.ever_audited i0.urban) ///
		 groups(*tamaño_ot* = "Firm Size" *activity_sector* = "Economic Activity", labsize(small) gap(2)) ///
		 coeflabels(final_log_age = "Age" 1.trader = "Foreign trade activity" 1.urban = "Main urban cities") ///
		 xline(0, lc(black)) label legend(region(lcolor(none))) graphr(color(white))
		 graph export "$out/probit_both.pdf", replace
		 
*************************************************************************
*******                 BASELINE ESTIMATES (NEW)                  ******* 
*************************************************************************	

local outcomes1 "final_log_fixed_assets final_log_value_added final_log_employment final_log_salary tfp_y_LP tfp_y_ACF"	
local outcomes2 "final_epm final_eta final_gfsal final_turnover final_liquidity"
global controls "final_log_age final_export_share final_import_share final_capital_int final_labor_int final_log_total_sales"
global fixed_ef "ib(freq).codigo year municipality" 

eststo drop *
foreach var of local outcomes1 {
	eststo eq1_`var': qui reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var'
	estadd scalar mean1 = r(mean)
	estadd loc sector_fe   "\cmark": eq1_`var'
	estadd loc province_fe "\cmark": eq1_`var'
	estadd loc year_fe     "\cmark": eq1_`var'
	estadd loc controls    "\cmark": eq1_`var'
	
	eststo eq2_`var': qui reghdfe `var' i.final_regime ${controls}, a(${fixed_ef}) vce(cluster id)
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	qui sum `var'
	estadd scalar mean1 = r(mean)
	estadd loc sector_fe   "\cmark": eq2_`var'
	estadd loc province_fe "\cmark": eq2_`var'
	estadd loc year_fe     "\cmark": eq2_`var'
	estadd loc controls    "\cmark": eq2_`var'
}

foreach var of local outcomes2 {
	eststo eq3_`var': qui reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var'
	estadd scalar mean2 = r(mean)
	estadd loc sector_fe   "\cmark": eq3_`var'
	estadd loc province_fe "\cmark": eq3_`var'
	estadd loc year_fe     "\cmark": eq3_`var'
	estadd loc controls    "\cmark": eq3_`var'
	
	eststo eq4_`var': qui reghdfe `var' i.final_regime ${controls}, a(${fixed_ef}) vce(cluster id)
	qui test 1.final_regime == 2.final_regime
	estadd scalar test2 = r(p)
	qui sum `var'
	estadd scalar mean2 = r(mean)
	estadd loc sector_fe   "\cmark": eq4_`var'
	estadd loc province_fe "\cmark": eq4_`var'
	estadd loc year_fe     "\cmark": eq4_`var'
	estadd loc controls    "\cmark": eq4_`var'
}

esttab eq1_* using "$out\reg_performance1.tex", replace f booktabs se(2) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.3fc %9.0fc %9.3fc) ///
	   keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A}}", nolabel) ///
	   scalars("mean1 Mean Dep. Var." "N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")
	   
esttab eq2_* using "$out\reg_performance1.tex", append f booktabs se(2) b(3) nonumber star(* 0.10 ** 0.05 *** 0.01) ///
	   sfmt(%9.3fc %9.0fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") refcat(1.final_regime "\textsc{\textbf{Panel B}}", nolabel) ///
	   scalars("mean1 Mean Dep. Var." "N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")	   

esttab eq3_* using "$out\reg_financial1.tex", replace f booktabs se(2) b(3) star(* 0.10 ** 0.05 *** 0.01) ///
	   mtitle("EPM" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.3fc %9.0fc %9.3fc) ///
	   keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A}}", nolabel) ///
	   scalars("mean2 Mean Dep. Var." "N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")
	   
esttab eq4_* using "$out\reg_financial1.tex", append f booktabs se(2) b(3) nonumber star(* 0.10 ** 0.05 *** 0.01) ///
	   sfmt(%9.3fc %9.0fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") refcat(1.final_regime "\textsc{\textbf{Panel B}}", nolabel) ///
	   scalars("mean2 Mean Dep. Var." "N Observations" "r2 R-Squared" "test2 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")
	   	   


/*************************************************************************
*******                 BASELINE ESTIMATES                        ******* 
*************************************************************************

* This section produces table 7 of the Appendix.
 
* Table 7
eststo drop *
foreach var of varlist final_gpm final_npm {
	forval j = 1/3 {
	    preserve
		keep if final_industry == `j' 
		eststo eq_`var'_`j': qui reghdfe `var' cit_exonerated $controls, a(year province) cluster(id) residuals(res_2_`var'_`j')
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
		estadd loc controls    "\cmark": eq_`var'_`j'
		
		eststo eqt_`var'_`j': qui reghdfe `var' i.final_regime $controls, a(year province) cluster(id) residuals(rest_2_`var'_`j')
		qui test 1.final_regime == 2.final_regime
		estadd scalar test1 = r(p)
		estadd loc province_fe "\cmark": eqt_`var'_`j'
		estadd loc year_fe     "\cmark": eqt_`var'_`j'
		estadd loc controls    "\cmark": eqt_`var'_`j'
		restore 
	}
}

esttab eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_baseline2.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux    														///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) 		///
	   mgroups("\textsc{Primary}" "\textsc{Manufacturing}" "\textsc{Services}", pattern(1 0 1 0 1 0) 				///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(cit_exonerated)	        ///
	   scalars("N Observations" "r2 R-Squared" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")	///
	   coeflabels(cit_exonerated "Exonerated")

esttab eqt_final_gpm_1 eqt_final_npm_1 eqt_final_gpm_2 eqt_final_npm_2 eqt_final_gpm_3 eqt_final_npm_3 using "$out\reg_baseline2.tex",       ///
	   append booktabs se(2) b(3) nonumbers star staraux	     					 														 ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") alignment(D{.}{.}{-1}) page(dcolumn) 		 											 ///
	   mgroups("\textsc{Primary}" "\textsc{Manufacturing}" "\textsc{Services}", pattern(1 0 1 0 1 0) 		  		 						 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)					 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")	 ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") sfmt(%9.3fc %9.3fc %9.3fc)


*************************************************************************
*******                 ANALYSIS OF COVARIATES                    ******* 
*************************************************************************

*This section produces tables 8, 9, and 10 of the Appendix.

* Estimates for all exonerated firms (Table 8)
loc z "final_log_age mnc final_fixasset_quint final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_exo = `k' * cit_exonerated  
}

global iteration1 "final_log_age_exo i.mnc_exo i.final_fixasset_quint_exo"
global iteration2 "final_log_input_costs_exo final_log_financial_costs_exo"
global iteration3 "final_capital_int_exo final_labor_int_exo final_export_share_exo final_import_share_exo"

eststo drop *
foreach var of varlist final_gpm final_npm {
		eststo eq_`var'_0: qui reghdfe `var' cit_exonerated $controls $iteration1 $iteration2 $iteration3, a(codigo year province) cluster(id) residuals(res_3_`var'_0)
		estadd loc sector_fe   "\cmark": eq_`var'_0
		estadd loc province_fe "\cmark": eq_`var'_0
		estadd loc year_fe     "\cmark": eq_`var'_0
		estadd loc controls    "\cmark": eq_`var'_0
		
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' cit_exonerated $controls ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_3_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
		estadd loc controls    "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_0 eq_final_npm_0 eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms1.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux drop(cit_exonerated  0.mnc_exo 0.final_fixasset_quint_exo 1.final_fixasset_quint_exo $controls)	///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn)   ///
	   mgroups("\textsc{Covariates}" "\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}",  	      ///
	   pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 		 	  ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?") 	  ///
	   coeflabels(final_log_age_exo "Exonerated $\times$ Age" 1.mnc_exo "Exonerated $\times$ MNC" 2.final_fixasset_quint_exo ///
	   "Exonerated $\times$ 2 Quintile Fixed Assets" 3.final_fixasset_quint_exo "Exonerated $\times$ 3 Quintile Fixed Assets" ///
	   4.final_fixasset_quint_exo "Exonerated $\times$ 4 Quintile Fixed Assets" 5.final_fixasset_quint_exo "Exonerated $\times$ 5 Quintile Fixed Assets" ///
	   _cons "Constant" final_log_input_costs_exo "Exonerated $\times$ Input costs" 	  ///
	   final_log_financial_costs_exo "Exonerated $\times$ Financial costs" final_capital_int_exo 						  ///
	   "Exonerated $\times$ Capital intensity" final_labor_int_exo "Exonerated $\times$ Labor intensity" 				  ///
	   final_export_share_exo "Exonerated $\times$ Export share" final_import_share_exo "Exonerated $\times$ Import share") 
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons cit_exonerated) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.65(0.25)0.6) $graphop   ///
		 coeflabels(final_log_age_exo = "Age" 1.mnc_exo = "MNC" final_log_total_assets_exo = "Firm size"                 ///
		 final_log_input_costs_exo = "Input costs" final_log_financial_costs_exo = "Financial costs"     			  ///
		 final_capital_int_exo = "Capital intensity" final_labor_int_exo = "Labor intensity"  		     			  ///
	     final_export_share_exo = "Export share" final_import_share_exo = "Import share", wrap(9) labsize(small))     ///
		 groups(final_log_age_exo 1.mnc_exo final_log_total_assets_exo = "{bf:Firms traits}"                             ///
		 final_log_input_costs_exo final_log_financial_costs_exo = "{bf:Costs structure}"                             ///
		 final_capital_int_exo final_labor_int_exo final_export_share_exo final_import_share_exo = "{bf:Use of inputs}", ///
		 gap(1) labsize(small)) legend(row(1)) title("{bf:All exonerated firms}", position(12) size(small)) name(g1)        
 
* Estimates for EXPORT ORIENTED exonerated firms (Table 9)
g final_export_oriented = 0
replace final_export_oriented = 1 if final_regime == 1

loc z "final_log_age mnc final_fixasset_quint final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_export = `k' * final_export_oriented
}

global iteration1 "final_log_age_export i.mnc_export i.final_fixasset_quint_export"
global iteration2 "final_log_input_costs_export final_log_financial_costs_export"
global iteration3 "final_capital_int_export final_labor_int_export final_export_share_export final_import_share_export"

eststo drop *
foreach var of varlist final_gpm final_npm {
		eststo eq_`var'_0: qui reghdfe `var' cit_exonerated $controls $iteration1 $iteration2 $iteration3, a(codigo year province) cluster(id) residuals(res_4_`var'_0)
		estadd loc sector_fe   "\cmark": eq_`var'_0
		estadd loc province_fe "\cmark": eq_`var'_0
		estadd loc year_fe     "\cmark": eq_`var'_0
		estadd loc controls    "\cmark": eq_`var'_0
		
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' final_export_oriented $controls ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_4_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
		estadd loc controls    "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_0 eq_final_npm_0 eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms2.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux drop(final_export_oriented  0.mnc_export $controls)			  ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn)   ///
	   mgroups("\textsc{Covariates}" "\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}",         ///
	   pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 			  ///
	   coeflabels(final_log_age_export "Export-oriented $\times$ Age" 1.mnc_export "Export-oriented $\times$ MNC" 		  ///
	   final_log_total_assets_export "Export-oriented $\times$ Firm size" _cons "Constant" final_log_input_costs_export 	  ///
	   "Export-oriented $\times$ Input costs" final_log_financial_costs_export "Export-oriented $\times$ Financial costs" ///
	   final_capital_int_export "Export-oriented $\times$ Capital intensity" final_labor_int_export 					  ///
	   "Export-oriented $\times$ Labor intensity" final_export_share_export "Export-oriented $\times$ Export share" 	  ///
	   final_import_share_export "Export-oriented $\times$ Import share")												  ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons final_export_oriented) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.5(0.25)0.8) $graphop   	              ///
		 coeflabels(, nolabels) title("{bf:Export-oriented exonerations}", position(12) size(small)) yscale(off) name(g2) 

* Estimates for NON-EXPORT ORIENTED exonerated firms (Table 10)
g final_nexport_oriented = 0
replace final_nexport_oriented = 1 if final_regime == 2

loc z "final_log_age mnc final_fixasset_quint final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_noexp = `k' * final_nexport_oriented
}

global iteration1 "final_log_age_noexp i.mnc_noexp i.final_fixasset_quint_noexp"
global iteration2 "final_log_input_costs_noexp final_log_financial_costs_noexp"
global iteration3 "final_capital_int_noexp final_labor_int_noexp final_export_share_noexp final_import_share_noexp"

eststo drop *
foreach var of varlist final_gpm final_npm {
		eststo eq_`var'_0: qui reghdfe `var' cit_exonerated $controls $iteration1 $iteration2 $iteration3, a(codigo year province) cluster(id) residuals(res_5_`var'_0)
		estadd loc sector_fe   "\cmark": eq_`var'_0
		estadd loc province_fe "\cmark": eq_`var'_0
		estadd loc year_fe     "\cmark": eq_`var'_0
		estadd loc controls    "\cmark": eq_`var'_0
	
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' final_nexport_oriented $controls ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_5_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
		estadd loc controls    "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_0 eq_final_npm_0 eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms3.tex", /// 
	   replace booktabs se(2) b(3) nonumbers star staraux drop(final_nexport_oriented  0.mnc_noexp $controls)		    		 ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) 		 ///
	   mgroups("\textsc{Covariates}" "\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}",  				 ///
	   pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 					 ///
	   coeflabels(final_log_age_noexp "Non-export-oriented $\times$ Age" 1.mnc_noexp "Non-export-oriented $\times$ MNC" 		 ///
	   final_log_total_assets_noexp "Non-export-oriented $\times$ Firm size" _cons "Constant" final_log_input_costs_noexp 			 ///
	   "Non-export-oriented $\times$ Input costs" final_log_financial_costs_noexp "Non-export-oriented $\times$ Financial costs" ///
	   final_capital_int_noexp "Non-export-oriented $\times$ Capital intensity" final_labor_int_noexp 							 ///
	   "Non-export-oriented $\times$ Labor intensity" final_export_share_noexp "Non-export-oriented $\times$ Export share" 		 ///
	   final_import_share_noexp "Non-export-oriented $\times$ Import share") 													 ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?") 
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons final_nexport_oriented) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.85(0.25)0.4) $graphop    ///
		 coeflabels(, nolabels) title("{bf:Non-export-oriented exonerations}", position(12) size(small)) yscale(off) name(g3)

graph combine g1 g2 g3, col(3) imargin(small) commonscheme graphr(color(white))
graph export "$out\mechanisms.pdf", replace

graph drop _all		 

*************************************************************************
**	  ROBUSTNESS TESTS AND ALTERNATIVE MEASURES OF FIRM PERFORMANCE	   ** 
*************************************************************************

rename final_log_labor_productivity final_lproductivity
rename final_log_productivity_y     final_tfp_y
rename final_log_productivity_va	final_tfp_va

* This section produces tables 6, 12, 13, and 14 of the Appendix.
eststo drop *
foreach var of varlist final_gpm final_npm 									///
					   final_epm final_roa final_roce                       ///
					   final_eta final_gfsal final_turnover final_liquidity ///
					   final_lproductivity final_tfp_y final_tfp_va {

	eststo eq1_`var': qui reghdfe `var' cit_exonerated $controls, a(province year) cluster(id) residuals(res_6_`var')
	estadd loc sector_fe   "\xmark": eq1_`var'
	estadd loc province_fe "\cmark": eq1_`var'
	estadd loc year_fe     "\cmark": eq1_`var'
	estadd loc controls    "\cmark": eq1_`var'
	eststo eq2_`var': qui reghdfe `var' cit_exonerated $controls, a(codigo year) cluster(id) residuals(res_7_`var')
	estadd loc sector_fe   "\cmark": eq2_`var'
	estadd loc province_fe "\xmark": eq2_`var'
	estadd loc year_fe     "\cmark": eq2_`var'
	estadd loc controls    "\cmark": eq2_`var'
	eststo eq3_`var': qui reghdfe `var' cit_exonerated $controls, a(year) cluster(id) residuals(res_8_`var')
	estadd loc sector_fe   "\xmark": eq3_`var'
	estadd loc province_fe "\xmark": eq3_`var'
	estadd loc year_fe     "\cmark": eq3_`var'
	estadd loc controls    "\cmark": eq3_`var'
	eststo eq4_`var': qui reghdfe `var' cit_exonerated $controls, a(codigo province year) cluster(id) residuals(res_9_`var')
	estadd loc sector_fe   "\cmark": eq4_`var'
	estadd loc province_fe "\cmark": eq4_`var'
	estadd loc year_fe     "\cmark": eq4_`var'
	estadd loc controls    "\cmark": eq4_`var'
	
	eststo eqt1_`var': qui reghdfe `var' i.final_regime $controls, a(province year) cluster(id) residuals(rest_6_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\xmark": eqt1_`var'
	estadd loc province_fe "\cmark": eqt1_`var'
	estadd loc year_fe     "\cmark": eqt1_`var'
	estadd loc controls    "\cmark": eqt1_`var'
	eststo eqt2_`var': qui reghdfe `var' i.final_regime $controls, a(codigo year) cluster(id) residuals(rest_7_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\cmark": eqt2_`var'
	estadd loc province_fe "\xmark": eqt2_`var'
	estadd loc year_fe     "\cmark": eqt2_`var'
	estadd loc controls    "\cmark": eqt2_`var'
	eststo eqt3_`var': qui reghdfe `var' i.final_regime $controls, a(year) cluster(id) residuals(rest_8_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\xmark": eqt3_`var'
	estadd loc province_fe "\xmark": eqt3_`var'
	estadd loc year_fe     "\cmark": eqt3_`var'
	estadd loc controls    "\cmark": eqt3_`var'
	eststo eqt4_`var': qui reghdfe `var' i.final_regime $controls, a(codigo province year) cluster(id) residuals(rest_9_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\cmark": eqt4_`var'
	estadd loc province_fe "\cmark": eqt4_`var'
	estadd loc year_fe     "\cmark": eqt4_`var'
	estadd loc controls    "\cmark": eqt4_`var'
}

* Testing for different controls (Table 11)
esttab eq4_final_gpm eq1_final_gpm eq2_final_gpm eq3_final_gpm eq4_final_npm eq1_final_npm eq2_final_npm eq3_final_npm using "$out\reg_robustness1.tex", /// 
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options	 ///
	   mgroups("\textsc{Gross Profit Margins}" "\textsc{Net Profit Margins}", pattern(1 0 0 0 1 0 0 0) 				 	     ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 			 		         ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")

esttab eqt4_final_gpm eqt1_final_gpm eqt2_final_gpm eqt3_final_gpm eqt4_final_npm eqt1_final_npm eqt2_final_npm eqt3_final_npm using "$out\reg_robustness1.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options   									 	             ///
	   mgroups("\textsc{Gross Profit Margins}" "\textsc{Net Profit Margins}", pattern(1 0 0 0 1 0 0 0) 				 	 					 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)    		 		 ///   
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") 								 ///
       scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")
	   
* Alternative measures of profitability (Table 12)
esttab eq4_final_epm eq1_final_epm eq2_final_epm eq3_final_epm ///
       eq4_final_roa eq1_final_roa eq2_final_roa eq3_final_roa ///
	   eq4_final_roce eq1_final_roce eq2_final_roce eq3_final_roce using "$out\reg_robustness2.tex", ///
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options ///
	   mgroups("\textsc{EPM}" "\textsc{ROA}" "\textsc{ROCE}", pattern(1 0 0 0 1 0 0 0 1 0 0 0) 							 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					     ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")

esttab eqt4_final_epm eqt1_final_epm eqt2_final_epm eqt3_final_epm ///
       eqt4_final_roa eqt1_final_roa eqt2_final_roa eqt3_final_roa ///
	   eqt4_final_roce eqt1_final_roce eqt2_final_roce eqt3_final_roce using "$out\reg_robustness2.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options 									 					 ///
	   mgroups("\textsc{EPM}" "\textsc{ROA}" "\textsc{ROCE}", pattern(1 0 0 0 1 0 0 0 1 0 0 0)  						    				 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)           			 ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") 								 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")

	   
* Alternative measures of firm performance (Table 13)
esttab eq4_final_eta eq1_final_eta eq2_final_eta eq3_final_eta 					   ///
       eq4_final_gfsal eq1_final_gfsal eq2_final_gfsal eq3_final_gfsal 			   ///
	   eq4_final_turnover eq1_final_turnover eq2_final_turnover eq3_final_turnover ///
	   eq4_final_liquidity eq1_final_liquidity eq2_final_liquidity eq3_final_liquidity using "$out\reg_robustness3.tex", replace $options  ///
	   sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") 			         			   ///
	   mgroups("\textsc{ETA}" "\textsc{GFSAL}" "\textsc{Turnover}" "\textsc{Liquidity}", pattern(1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0)    	   ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					                       ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")

esttab eqt4_final_eta eqt1_final_eta eqt2_final_eta eqt3_final_eta 					   ///
       eqt4_final_gfsal eqt1_final_gfsal eqt2_final_gfsal eqt3_final_gfsal             ///
	   eqt4_final_turnover eqt1_final_turnover eqt2_final_turnover eqt3_final_turnover ///
	   eqt4_final_liquidity eqt1_final_liquidity eqt2_final_liquidity eqt3_final_liquidity using "$out\reg_robustness3.tex", append $options ///
	   sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn)   									 		        				 ///
	   mgroups("\textsc{ETA}" "\textsc{GFSAL}" "\textsc{Turnover}" "\textsc{Liquidity}", pattern(1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0)  			 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)    				 ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)")								 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?") 

	   
* Alternative measures of firm performance - Productivity (Table 14)  
esttab eq4_final_lproductivity eq1_final_lproductivity eq2_final_lproductivity eq3_final_lproductivity 		 ///
	   eq4_final_tfp_y eq1_final_tfp_y eq2_final_tfp_y eq3_final_tfp_y   							         ///
	   eq4_final_tfp_va eq1_final_tfp_va eq2_final_tfp_va eq3_final_tfp_va using "$out\reg_robustness4.tex", ///
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options		     ///
	   mgroups("\textsc{Labor Productivity}" "\textsc{TFP on Sales}" "\textsc{TFP on Value Added}", pattern(1 0 0 0 1 0 0 0 1 0 0 0) ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					 			     ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?")

esttab eqt4_final_lproductivity eqt1_final_lproductivity eqt2_final_lproductivity eqt3_final_lproductivity 		 ///
	   eqt4_final_tfp_y eqt1_final_tfp_y eqt2_final_tfp_y eqt3_final_tfp_y   							         ///
	   eqt4_final_tfp_va eqt1_final_tfp_va eqt2_final_tfp_va eqt3_final_tfp_va using "$out\reg_robustness4.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options  									 	      ///
	   mgroups("\textsc{Labor Productivity}" "\textsc{TFP on Sales}" "\textsc{TFP on Value Added}", pattern(1 0 0 0 1 0 0 0 1 0 0 0)  ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)  		      ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") 						  ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?" "controls Controls?") 
	   

*************************************************************************
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
