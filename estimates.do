/*
Name:			estimates.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates fixed-effects estimates presented in tables 5, 6, 7, 8, 
				9, 10, 11, 12, 13, and 14 included in the Appendix of the paper the paper 
				"Firm performance and tax incentives: evidence from Honduras". 
Date:			November, 2021
Modified:		January, 2021
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
clear matrix
set more off
set varabbrev off
set matsize 2000
set seed 2000

* Antes de correr este do file debe cambiar los directorios
global path "C:\Users\Owner\OneDrive - SAR\Firm performance and tax incentives"		// cambiar directorio
global out  "C:\Users\Owner\OneDrive - SAR\Profit Margins\out"		// cambiar directorio

run "$path\setup.do" 	// Run the do file that prepare all variables for estimations

global details "booktabs f se(2) b(3) nonumbers star staraux"
global options "booktabs se(2) b(3) star staraux nomtitles"
global graphop "grid(none) legend(region(lcolor(none))) graphr(color(white))"

*************************************************************************
*******                 BASELINE ESTIMATES                        ******* 
*************************************************************************

* This section produces tables 5, 6, and 7 of the Appendix.

eststo drop *
foreach var of varlist final_gpm final_log_gpm final_ihs_gpm final_npm final_log_npm final_ihs_npm {
	eststo eq_`var': qui reghdfe `var' cit_exonerated, a(codigo year province) cluster(id) residuals(res_1_`var')
	estadd loc sector_fe   "\cmark": eq_`var'
	estadd loc province_fe "\cmark": eq_`var'
	estadd loc year_fe     "\cmark": eq_`var'
	
	eststo eqt_`var': qui reghdfe `var' i.final_regime, a(codigo year province) cluster(id) residuals(rest_1_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\cmark": eqt_`var'
	estadd loc province_fe "\cmark": eqt_`var'
	estadd loc year_fe     "\cmark": eqt_`var'
}

* Table 5
esttab eq_final_gpm eq_final_log_gpm eq_final_ihs_gpm using "$out\reg_baseline.tex", replace $details     ///
	   keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated")    ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   mtitles("Levels" "Log(GPM)" "IHS(GPM)")  sfmt(%9.3fc %9.3fc)

esttab eq_final_npm eq_final_log_npm eq_final_ihs_npm using "$out\reg_baseline.tex", append $details    ///
	   keep(cit_exonerated) coeflabels(cit_exonerated "Exonerated")  ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   mtitles("Levels" "Log(NPM)" "IHS(NPM)") sfmt(%9.3fc %9.3fc)

* Table 6
esttab eqt_final_gpm eqt_final_log_gpm eqt_final_ihs_gpm using "$out\reg_baseline1.tex", replace $details   ///
	   keep(1.final_regime 2.final_regime)  mtitles("Levels" "Log(GPM)" "IHS(GPM)") ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") sfmt(%9.3fc %9.3fc %9.3fc)

esttab eqt_final_npm eqt_final_log_npm eqt_final_ihs_npm using "$out\reg_baseline1.tex", append $details    ///
	   keep(1.final_regime 2.final_regime)  mtitles("Levels" "Log(NPM)" "IHS(NPM)") ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") sfmt(%9.3fc %9.3fc %9.3fc)
	   
* Table 7
eststo drop *
foreach var of varlist final_gpm final_npm {
	forval j = 1/3 {
	
		eststo eq_`var'_`j': qui reghdfe `var' cit_exonerated if final_industry == `j', a(year province) cluster(id) residuals(res_2_`var'_`j')
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
		
		eststo eqt_`var'_`j': qui reghdfe `var' i.final_regime if final_industry == `j', a(year province) cluster(id) residuals(rest_2_`var'_`j')
		qui test 1.final_regime == 2.final_regime
		estadd scalar test1 = r(p)
		estadd loc province_fe "\cmark": eqt_`var'_`j'
		estadd loc year_fe     "\cmark": eqt_`var'_`j'
	}
}

esttab eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_baseline2.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux    												///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) ///
	   mgroups("\textsc{Primary}" "\textsc{Manufacturing}" "\textsc{Services}", pattern(1 0 1 0 1 0) 		///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons)			///
	   scalars("N Observations" "r2 R-Squared" "province_fe Province FE?" "year_fe Year FE?")        		///
	   coeflabels(cit_exonerated "Exonerated")

esttab eqt_final_gpm_1 eqt_final_npm_1 eqt_final_gpm_2 eqt_final_npm_2 eqt_final_gpm_3 eqt_final_npm_3 using "$out\reg_baseline2.tex",       ///
	   append booktabs se(2) b(3) nonumbers star staraux	     					 														 ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") alignment(D{.}{.}{-1}) page(dcolumn) 		 											 ///
	   mgroups("\textsc{Primary}" "\textsc{Manufacturing}" "\textsc{Services}", pattern(1 0 1 0 1 0) 		  		 						 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)					 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "province_fe Province FE?" "year_fe Year FE?") 						 ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)") sfmt(%9.3fc %9.3fc %9.3fc)


*************************************************************************
*******                 ANALYSIS OF MECHANISMS                    ******* 
*************************************************************************

*This section produces tables 8, 9, and 10 of the Appendix.

* Estimates for all exonerated firms (Table 8)
loc z "final_log_age mnc final_log_firm_size final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_exo = `k' * cit_exonerated  
}

global iteration1 "final_log_age_exo i.mnc_exo final_log_firm_size_exo"
global iteration2 "final_log_input_costs_exo final_log_financial_costs_exo"
global iteration3 "final_capital_int_exo final_labor_int_exo final_export_share_exo final_import_share_exo"

eststo drop *
foreach var of varlist final_gpm final_npm {
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' cit_exonerated ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_3_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms1.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux       														  ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) 			  ///
	   mgroups("\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}", pattern(1 0 1 0 1 0) 		  ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(cit_exonerated  0.mnc_exo) 	  ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") 	  ///
	   coeflabels(final_log_age_exo "Exonerated $\times$ Age" 1.mnc_exo "Exonerated $\times$ MNC" final_log_firm_size_exo ///
	   "Exonerated $\times$ Firm size" _cons "Constant" final_log_input_costs_exo "Exonerated $\times$ Input costs" 	  ///
	   final_log_financial_costs_exo "Exonerated $\times$ Financial costs" final_capital_int_exo 						  ///
	   "Exonerated $\times$ Capital intensity" final_labor_int_exo "Exonerated $\times$ Labor intensity" 				  ///
	   final_export_share_exo "Exonerated $\times$ Export share" final_import_share_exo 								  ///
	   "Exonerated $\times$ Import share") 
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons cit_exonerated) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.65(0.25)0.6) $graphop  ///
		 coeflabels(final_log_age_exo = "Age" 1.mnc_exo = "MNC" final_log_firm_size_exo = "Firm size"                 ///
		 final_log_input_costs_exo = "Input costs" final_log_financial_costs_exo = "Financial costs"     			  ///
		 final_capital_int_exo = "Capital intensity" final_labor_int_exo = "Labor intensity"  		     			  ///
	     final_export_share_exo = "Export share" final_import_share_exo = "Import share", wrap(9) labsize(small))     ///
		 groups(final_log_age_exo 1.mnc_exo final_log_firm_size_exo = "{bf:Firms traits}"                  ///
		 final_log_input_costs_exo final_log_financial_costs_exo = "{bf:Costs structure}"                 ///
		 final_capital_int_exo final_labor_int_exo final_export_share_exo final_import_share_exo = "{bf:Use of inputs}", ///
		 gap(1) labsize(small)) legend(row(1)) title("{bf:All exonerated firms}", position(12) size(small)) name(g1)        
 
* Estimates for EXPORT ORIENTED exonerated firms (Table 9)
g final_export_oriented = 0
replace final_export_oriented = 1 if final_regime == 1

loc z "final_log_age mnc final_log_firm_size final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_export = `k' * final_export_oriented
}

global iteration1 "final_log_age_export i.mnc_export final_log_firm_size_export"
global iteration2 "final_log_input_costs_export final_log_financial_costs_export"
global iteration3 "final_capital_int_export final_labor_int_export final_export_share_export final_import_share_export"

eststo drop *
foreach var of varlist final_gpm final_npm {
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' final_export_oriented ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_4_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms2.tex", ///
	   replace booktabs se(2) b(3) nonumbers star staraux drop(final_export_oriented  0.mnc_export)				    	  ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) 			  ///
	   mgroups("\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}", pattern(1 0 1 0 1 0) 		  ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 								      ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") 	  ///
	   coeflabels(final_log_age_export "Export-oriented $\times$ Age" 1.mnc_export "Export-oriented $\times$ MNC" 		  ///
	   final_log_firm_size_export "Export-oriented $\times$ Firm size" _cons "Constant" final_log_input_costs_export 	  ///
	   "Export-oriented $\times$ Input costs" final_log_financial_costs_export "Export-oriented $\times$ Financial costs" ///
	   final_capital_int_export "Export-oriented $\times$ Capital intensity" final_labor_int_export 					  ///
	   "Export-oriented $\times$ Labor intensity" final_export_share_export "Export-oriented $\times$ Export share" 	  ///
	   final_import_share_export "Export-oriented $\times$ Import share")
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons final_export_oriented) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.5(0.25)0.8) $graphop   	              ///
		 coeflabels(, nolabels) title("{bf:Export-oriented exonerations}", position(12) size(small)) yscale(off) name(g2) 

* Estimates for NON-EXPORT ORIENTED exonerated firms (Table 10)
g final_nexport_oriented = 0
replace final_nexport_oriented = 1 if final_regime == 2

loc z "final_log_age mnc final_log_firm_size final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
foreach k of loc z {
	g `k'_noexp = `k' * final_nexport_oriented
}

global iteration1 "final_log_age_noexp i.mnc_noexp final_log_firm_size_noexp"
global iteration2 "final_log_input_costs_noexp final_log_financial_costs_noexp"
global iteration3 "final_capital_int_noexp final_labor_int_noexp final_export_share_noexp final_import_share_noexp"

eststo drop *
foreach var of varlist final_gpm final_npm {
	forval j = 1/3 {
		eststo eq_`var'_`j': qui reghdfe `var' final_nexport_oriented ${iteration`j'}, a(codigo year province) cluster(id) residuals(res_5_`var'_`j')
		estadd loc sector_fe   "\cmark": eq_`var'_`j'
		estadd loc province_fe "\cmark": eq_`var'_`j'
		estadd loc year_fe     "\cmark": eq_`var'_`j'
	}
}

esttab eq_final_gpm_1 eq_final_npm_1 eq_final_gpm_2 eq_final_npm_2 eq_final_gpm_3 eq_final_npm_3 using "$out\reg_mechanisms3.tex", /// 
	   replace booktabs se(2) b(3) nonumbers star staraux drop(final_nexport_oriented  0.mnc_noexp)					    		 ///
	   mtitle("GPM" "NPM" "GPM" "NPM" "GPM" "NPM") sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) 					 ///
	   mgroups("\textsc{Firms Traits}" "\textsc{Costs Structure}" "\textsc{Use of Inputs}", pattern(1 0 1 0 1 0) 				 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 							     			 ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") 			 ///
	   coeflabels(final_log_age_noexp "Non-export-oriented $\times$ Age" 1.mnc_noexp "Non-export-oriented $\times$ MNC" 		 ///
	   final_log_firm_size_noexp "Non-export-oriented $\times$ Firm size" _cons "Constant" final_log_input_costs_noexp 			 ///
	   "Non-export-oriented $\times$ Input costs" final_log_financial_costs_noexp "Non-export-oriented $\times$ Financial costs" ///
	   final_capital_int_noexp "Non-export-oriented $\times$ Capital intensity" final_labor_int_noexp 							 ///
	   "Non-export-oriented $\times$ Labor intensity" final_export_share_noexp "Non-export-oriented $\times$ Export share" 		 ///
	   final_import_share_noexp "Non-export-oriented $\times$ Import share") 
	   
coefplot (eq_final_gpm_1, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_1, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
         (eq_final_gpm_2, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_2, nokey mcolor(orange%60) ciopts(lcolor(orange%60)))  ///
		 (eq_final_gpm_3, nokey mcolor(blue%70) ciopts(lcolor(blue%70))) (eq_final_npm_3, nokey mcolor(orange%60) ciopts(lcolor(orange%60))), ///
         drop(_cons final_nexport_oriented) xline(0, lpattern(-) lwidth(tiny) lcolor(gray)) xlabel(-0.85(0.25)0.4) $graphop    ///
		 coeflabels(, nolabels) title("{bf:Non-export-oriented exonerations}", position(12) size(small)) yscale(off) name(g3)

graph combine g1 g2 g3, col(3) imargin(small) commonscheme graphr(color(white))
graph export "$out\mechanisms.pdf", replace
		 
		 
*************************************************************************
*******                     ROBUSTNESS TESTS                      ******* 
*************************************************************************

rename final_log_labor_productivity final_lproductivity
rename final_log_productivity_y     final_tfp_y
rename final_log_productivity_va	final_tfp_va

* This section produces tables 11, 12, 13, and 14 of the Appendix.
eststo drop *
foreach var of varlist final_gpm final_npm 									///
					   final_epm final_roa final_roce                       ///
					   final_eta final_gfsal final_turnover final_liquidity ///
					   final_lproductivity final_tfp_y final_tfp_va {

	eststo eq1_`var': qui reghdfe `var' cit_exonerated, a(province year) cluster(id) residuals(res_6_`var')
	estadd loc sector_fe   "\xmark": eq1_`var'
	estadd loc province_fe "\cmark": eq1_`var'
	estadd loc year_fe     "\cmark": eq1_`var'
	eststo eq2_`var': qui reghdfe `var' cit_exonerated, a(codigo year) cluster(id) residuals(res_7_`var')
	estadd loc sector_fe   "\cmark": eq2_`var'
	estadd loc province_fe "\xmark": eq2_`var'
	estadd loc year_fe     "\cmark": eq2_`var'
	eststo eq3_`var': qui reghdfe `var' cit_exonerated, a(year) cluster(id) residuals(res_8_`var')
	estadd loc sector_fe   "\xmark": eq3_`var'
	estadd loc province_fe "\xmark": eq3_`var'
	estadd loc year_fe     "\cmark": eq3_`var'
	eststo eq4_`var': qui reghdfe `var' cit_exonerated, a(codigo province year) cluster(id) residuals(res_9_`var')
	estadd loc sector_fe   "\cmark": eq4_`var'
	estadd loc province_fe "\cmark": eq4_`var'
	estadd loc year_fe     "\cmark": eq4_`var'
	
	eststo eqt1_`var': qui reghdfe `var' i.final_regime, a(province year) cluster(id) residuals(rest_6_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\xmark": eqt1_`var'
	estadd loc province_fe "\cmark": eqt1_`var'
	estadd loc year_fe     "\cmark": eqt1_`var'
	eststo eqt2_`var': qui reghdfe `var' i.final_regime, a(codigo year) cluster(id) residuals(rest_7_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\cmark": eqt2_`var'
	estadd loc province_fe "\xmark": eqt2_`var'
	estadd loc year_fe     "\cmark": eqt2_`var'
	eststo eqt3_`var': qui reghdfe `var' i.final_regime, a(year) cluster(id) residuals(rest_8_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\xmark": eqt3_`var'
	estadd loc province_fe "\xmark": eqt3_`var'
	estadd loc year_fe     "\cmark": eqt3_`var'
	eststo eqt4_`var': qui reghdfe `var' i.final_regime, a(codigo province year) cluster(id) residuals(rest_9_`var')
	qui test 1.final_regime == 2.final_regime
	estadd scalar test1 = r(p)
	estadd loc sector_fe   "\cmark": eqt4_`var'
	estadd loc province_fe "\cmark": eqt4_`var'
	estadd loc year_fe     "\cmark": eqt4_`var'
}

* Testing for different controls (Table 11)
esttab eq4_final_gpm eq1_final_gpm eq2_final_gpm eq3_final_gpm eq4_final_npm eq1_final_npm eq2_final_npm eq3_final_npm using "$out\reg_robustness1.tex", /// 
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options	 ///
	   mgroups("\textsc{Gross Profit Margins}" "\textsc{Net Profit Margins}", pattern(1 0 0 1 0 0) 				 	         ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 			 		         ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?")

esttab eqt4_final_gpm eqt1_final_gpm eqt2_final_gpm eqt3_final_gpm eqt4_final_npm eqt1_final_npm eqt2_final_npm eqt3_final_npm using "$out\reg_robustness1.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options   									 	             ///
	   mgroups("\textsc{Gross Profit Margins}" "\textsc{Net Profit Margins}", pattern(1 0 0 1 0 0) 				 	 						 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)    		 		 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)")

	   
* Alternative measures of profitability (Table 12)
esttab eq4_final_epm eq1_final_epm eq2_final_epm eq3_final_epm ///
       eq4_final_roa eq1_final_roa eq2_final_roa eq3_final_roa ///
	   eq4_final_roce eq1_final_roce eq2_final_roce eq3_final_roce using "$out\reg_robustness2.tex", ///
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options ///
	   mgroups("\textsc{EPM}" "\textsc{ROA}" "\textsc{ROCE}", pattern(1 0 0 1 0 0 1 0 0) 							     ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					     ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?")

esttab eqt4_final_epm eqt1_final_epm eqt2_final_epm eqt3_final_epm ///
       eqt4_final_roa eqt1_final_roa eqt2_final_roa eqt3_final_roa ///
	   eqt4_final_roce eqt1_final_roce eqt2_final_roce eqt3_final_roce using "$out\reg_robustness2.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options 									 					 ///
	   mgroups("\textsc{EPM}" "\textsc{ROA}" "\textsc{ROCE}", pattern(1 0 0 1 0 0 1 0 0)  						    						 ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)           			 ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)")

	   
* Alternative measures of firm performance (Table 13)
esttab eq4_final_eta eq1_final_eta eq2_final_eta eq3_final_eta 					   ///
       eq4_final_gfsal eq1_final_gfsal eq2_final_gfsal eq3_final_gfsal 			   ///
	   eq4_final_turnover eq1_final_turnover eq2_final_turnover eq3_final_turnover ///
	   eq4_final_liquidity eq1_final_liquidity eq2_final_liquidity eq3_final_liquidity using "$out\reg_robustness3.tex", replace $options  ///
	   sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") 			         ///
	   mgroups("\textsc{ETA}" "\textsc{GFSAL}" "\textsc{Turnover}" "\textsc{Liquidity}", pattern(1 0 0 1 0 0 1 0 0 1 0 0)    ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					         ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?")

esttab eqt4_final_eta eqt1_final_eta eqt2_final_eta eqt3_final_eta 					   ///
       eqt4_final_gfsal eqt1_final_gfsal eqt2_final_gfsal eqt3_final_gfsal             ///
	   eqt4_final_turnover eqt1_final_turnover eqt2_final_turnover eqt3_final_turnover ///
	   eqt1_final_liquidity eqt2_final_liquidity eqt3_final_liquidity using "$out\reg_robustness3.tex", append $options		///
	   sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn)   									 		        ///
	   mgroups("\textsc{ETA}" "\textsc{GFSAL}" "\textsc{Turnover}" "\textsc{Liquidity}", pattern(1 0 0 1 0 0 1 0 0 1 0 0)  	///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)    ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)")				///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") 

	   
* Alternative measures of firm performance - Productivity (Table 14)  
esttab eq4_final_lproductivity eq1_final_lproductivity eq2_final_lproductivity eq3_final_lproductivity 		 ///
	   eq4_final_tfp_y eq1_final_tfp_y eq2_final_tfp_y eq3_final_tfp_y   							         ///
	   eq4_final_tfp_va eq1_final_tfp_va eq2_final_tfp_va eq3_final_tfp_va using "$out\reg_robustness4.tex", ///
	   replace sfmt(%9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) coeflabels(cit_exonerated "Exonerated") $options		   ///
	   mgroups("\textsc{Labor Productivity}" "\textsc{TFP on Sales}" "\textsc{TFP on Value Added}", pattern(1 0 0 1 0 0 1 0 0)     ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) drop(_cons) 					 			   ///
	   scalars("N Observations" "r2 R-Squared" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?")

esttab eqt4_final_lproductivity eqt1_final_lproductivity eqt2_final_lproductivity eqt3_final_lproductivity 		 ///
	   eqt4_final_tfp_y eqt1_final_tfp_y eqt2_final_tfp_y eqt3_final_tfp_y   							         ///
	   eqt4_final_tfp_va eqt1_final_tfp_va eqt2_final_tfp_va eqt3_final_tfp_va using "$out\reg_robustness4.tex", ///
	   append sfmt(%9.3fc %9.3fc %9.3fc) alignment(D{.}{.}{-1}) page(dcolumn) $options  									 	      ///
	   mgroups("\textsc{Labor Productivity}" "\textsc{TFP on Sales}" "\textsc{TFP on Value Added}", pattern(1 0 0 1 0 0 1 0 0)        ///
	   prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(1.final_regime 2.final_regime)  		      ///
	   scalars("N Observations" "r2 R-Squared" "test1 $\beta1=\beta2$" "sector_fe Sector FE?" "province_fe Province FE?" "year_fe Year FE?") ///
	   coeflabels(1.final_regime "Export Oriented ($\beta1$)" 2.final_regime "Non-Export Oriented ($\beta2$)")

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
