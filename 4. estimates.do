
		*=========================================================================
		* DO FILE RUNING ECONOMETRIC MODELS FROM FINAL SAMPLE
		*=========================================================================

* Declaring sample as data panel		
xtset id year, yearly

* Global settings for tables and graphs aesthetic
global tab_details "f booktabs se(2) b(3) star(* 0.10 ** 0.05 *** 0.01)"

* Global settings for regressions
global probit_covariates "final_log_age i.final_mnc i.trader legal_attorneys ever_audited_times i.urban ib3.tamaño_ot i.activity_sector"
global outcomes1 "final_log_fixed_assets final_log_value_added final_log_employment final_log_salary tfp_y_LP tfp_y_ACF"	
global outcomes2 "final_epm final_roa final_eta final_gfsal final_turnover final_liquidity"
global controls  "final_log_age final_export_share final_import_share final_capital_int final_labor_int ib3.tamaño_ot"
global controls1 "final_log_age ib3.tamaño_ot final_liquidity final_log_dividends_relations"
global fixed_ef  "ib(freq).codigo i.year ib(freq).municipality" 
	   




*************************************************************************
*******  PROBIT ESTIMATES 
*************************************************************************

* This section conducts non-linear regressions on covariates to be an exonerated firm
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
*******  TRIMMING VARIABLES 
*************************************************************************

* The following code generates dummies identifying the trimmed sample for outcome variables.
global outcomes ${outcomes1} ${outcomes2}
foreach var of global outcomes {
	
	preserve
	qui sum `var', d
	drop if `var' < r(p5)
	gen `var'_p5 = 1
	keep id year `var'_p5
	tempfile p5
	save `p5'
	restore
	
	merge 1:1 id year using `p5', keepusing(`var'_p5)
	drop _merge
	
	preserve
	qui sum `var', d
	drop if `var' > r(p95)
	gen `var'_p95 = 1
	keep id year `var'_p95
	tempfile p95
	save `p95'
	restore
	
	merge 1:1 id year using `p95', keepusing(`var'_p95)
	drop _merge
	
	preserve
	qui sum `var', d
	drop if `var' < r(p5) | `var' > r(p95)
	gen `var'_p = 1
	keep id year `var'_p
	tempfile p
	save `p'
	restore
	
	merge 1:1 id year using `p', keepusing(`var'_p)
	drop _merge
}



	
*************************************************************************
******* BASELINE ESTIMATES
*************************************************************************	

eststo drop *

* Primary outcomes
foreach var of global outcomes1 {
	
	eststo eq1a_`var': reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1b_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1c_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1d_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	estadd loc sector_fe "\cmark": eq1d_`var'
	estadd loc muni_fe   "\cmark": eq1d_`var'
	estadd loc year_fe   "\cmark": eq1d_`var'
	estadd loc controls  "\cmark": eq1d_`var'
}

esttab eq1a_* using "$out\reg_baseline_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1b_* using "$out\reg_baseline_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1c_* using "$out\reg_baseline_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	 
	   
esttab eq1d_* using "$out\reg_baseline_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")	

	   
* Secondary outcomes
foreach var of global outcomes2 {
	
	eststo eq2a_`var': qui reghdfe `var' cit_exonerated ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2b_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2c_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2d_`var': qui reghdfe `var' cit_exonerated ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	estadd loc sector_fe "\cmark": eq2d_`var'
	estadd loc muni_fe   "\cmark": eq2d_`var'
	estadd loc year_fe   "\cmark": eq2d_`var'
	estadd loc controls  "\cmark": eq2d_`var'
}


esttab eq2a_* using "$out\reg_baseline_secondary.tex", replace ${tab_details} ///
	   mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2b_* using "$out\reg_baseline_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2c_* using "$out\reg_baseline_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	 
	   
esttab eq2d_* using "$out\reg_baseline_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	   




*************************************************************************
******* DIFFERENCES BY EXONERATION REGIME
*************************************************************************	

eststo drop *

* Primary outcomes
foreach var of global outcomes1 {
	
	eststo eq1a_`var': qui reghdfe `var' ib0.final_regime ${controls}, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test1 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean1 = r(mean)
	
	eststo eq1b_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test1 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean1 = r(mean)
	
	eststo eq1c_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test1 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean1 = r(mean)
	
	eststo eq1d_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test1 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean1 = r(mean)
	
	estadd loc sector_fe "\cmark": eq1d_`var'
	estadd loc muni_fe   "\cmark": eq1d_`var'
	estadd loc year_fe   "\cmark": eq1d_`var'
	estadd loc controls  "\cmark": eq1d_`var'
}

esttab eq1a_* using "$out\reg_regimes_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean1 Mean Dep. Var." "test1 $\beta1 = \beta2$") 
	   
esttab eq1b_* using "$out\reg_regimes_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean1 Mean Dep. Var." "test1 $\beta1 = \beta2$")
	   
esttab eq1c_* using "$out\reg_regimes_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean1 Mean Dep. Var." "test1 $\beta1 = \beta2$")	 
	   
esttab eq1d_* using "$out\reg_regimes_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean1 Mean Dep. Var." "test1 $\beta1 = \beta2$" ///
	   "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")

* Secondary outcomes
foreach var of global outcomes2 {
	
	eststo eq2a_`var': qui reghdfe `var' ib0.final_regime ${controls}, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test2 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean2 = r(mean)
	
	eststo eq2b_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test2 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean2 = r(mean)
	
	eststo eq2c_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test2 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean2 = r(mean)
	
	eststo eq2d_`var': qui reghdfe `var' ib0.final_regime ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui test i1.final_regime == i2.final_regime
	estadd scalar test2 = r(p)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean2 = r(mean)
	
	estadd loc sector_fe "\cmark": eq2d_`var'
	estadd loc muni_fe   "\cmark": eq2d_`var'
	estadd loc year_fe   "\cmark": eq2d_`var'
	estadd loc controls  "\cmark": eq2d_`var'
}

esttab eq2a_* using "$out\reg_regimes_secondary.tex", replace ${tab_details} ///
	   mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean2 Mean Dep. Var." "test2 $\beta1 = \beta2$") 
	   
esttab eq2b_* using "$out\reg_regimes_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean2 Mean Dep. Var." "test2 $\beta1 = \beta2$")
	   
esttab eq2c_* using "$out\reg_regimes_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean2 Mean Dep. Var." "test2 $\beta1 = \beta2$")	 
	   
esttab eq2d_* using "$out\reg_regimes_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc %9.3fc) keep(1.final_regime 2.final_regime) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(1.final_regime "Export-Oriented ($\beta1$)" 2.final_regime "Non-Export-Oriented ($\beta2$)") ///
	   refcat(1.final_regime "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean2 Mean Dep. Var." "test2 $\beta1 = \beta2$" ///
	   "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	   




*************************************************************************
******* HETEROGENEITY
*************************************************************************

* Primary outcomes
eststo drop *
foreach var of global outcomes1 {
	eststo eq1a_`var': qui reghdfe `var' cit_exonerated ${controls} if exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
	eststo eq1b_`var': qui reghdfe `var' cit_exonerated ${controls} if non_exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)	
	
	eststo eq1c_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
	eststo eq1d_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 2, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
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
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Non Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	 
	   
esttab eq1c_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Agricultural, extraction}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1d_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Industry}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	   
	   
esttab eq1e_* using "$out\reg_hetero_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel E: Services}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")		
	   
	   
* Secondary outcomes
eststo drop *	   
foreach var of global outcomes2 {	
	eststo eq2a_`var': qui reghdfe `var' cit_exonerated ${controls} if exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
	eststo eq2b_`var': qui reghdfe `var' cit_exonerated ${controls} if non_exporter == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
	eststo eq2c_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
	eststo eq2d_`var': qui reghdfe `var' cit_exonerated ${controls} if final_industry == 2, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1
	estadd scalar mean = r(mean)
	
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
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel B: Non Exporters}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2c_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel C: Agricultural, extraction}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	
	   
esttab eq2d_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel D: Industry}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")		   
	   
esttab eq2e_* using "$out\reg_hetero_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(cit_exonerated) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(cit_exonerated "Exonerated") refcat(cit_exonerated "\textsc{\textbf{Panel E: Services}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")		
	   




*************************************************************************
******* ROBUSTNESS: TAX CREDITS INSTEAD OF DUMMIES
*************************************************************************

* As a robustness check we use exoneration credits instead of dummies. 

eststo drop *

* Primary outcomes
foreach var of global outcomes1 {
	
	eststo eq1a_`var': qui reghdfe `var' final_log_credits_exo ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1b_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1c_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq1d_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	estadd loc sector_fe "\cmark": eq1d_`var'
	estadd loc muni_fe   "\cmark": eq1d_`var'
	estadd loc year_fe   "\cmark": eq1d_`var'
	estadd loc controls  "\cmark": eq1d_`var'
}

esttab eq1a_* using "$out\robustness_credits_primary.tex", replace ${tab_details} ///
	   mtitle("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF") sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq1b_* using "$out\robustness_credits_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	
	   
esttab eq1c_* using "$out\robustness_credits_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	   
	   
esttab eq1d_* using "$out\robustness_credits_primary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")	

	   
* Secondary outcomes
foreach var of global outcomes2 {
	
	eststo eq2a_`var': qui reghdfe `var' final_log_credits_exo ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2b_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p5 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2c_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p95 == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	eststo eq2d_`var': qui reghdfe `var' final_log_credits_exo ${controls} if `var'_p == 1, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	
	estadd loc sector_fe "\cmark": eq2d_`var'
	estadd loc muni_fe   "\cmark": eq2d_`var'
	estadd loc year_fe   "\cmark": eq2d_`var'
	estadd loc controls  "\cmark": eq2d_`var'
}

esttab eq2a_* using "$out\robustness_credits_secondary.tex", replace ${tab_details} ///
	   mtitle("EPM" "ROA" "ETA" "GFSAL" "Turnover" "Liquidity") sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel A: Full Sample}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")
	   
esttab eq2b_* using "$out\robustness_credits_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel B: Dropping Bottom 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	
	   
esttab eq2c_* using "$out\robustness_credits_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel C: Dropping Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var.")	   
	   
esttab eq2d_* using "$out\robustness_credits_secondary.tex", append ${tab_details} ///
	   sfmt(%9.0fc %9.3fc %9.3fc) keep(final_log_credits_exo) eqlabels(none) nomtitles nonumbers ///
	   coeflabels(final_log_credits_exo "Exemption credits (logs)") refcat(final_log_credits_exo "\textsc{\textbf{Panel D: Dropping Bottom 5\% and Top 5\%}}", nolabel) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")
	   




*************************************************************************
******* PROFITABILITY AND PERFORMANCE / DIVIDENDS
*************************************************************************

gen interaction1 = cit_exonerated * final_epm
gen interaction2 = cit_exonerated * final_roa

****** Performance outcomes ******
eststo drop *

foreach var of global outcomes1 {	
	eststo eq1a_`var': qui reghdfe `var' interaction1 cit_exonerated final_epm ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\cmark"
	
	eststo eq1b_`var': qui reghdfe `var' interaction1 cit_exonerated final_epm, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\xmark"
	
	eststo eq2a_`var': qui reghdfe `var' interaction2 cit_exonerated final_roa ${controls}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\cmark"
	
	eststo eq2b_`var': qui reghdfe `var' interaction2 cit_exonerated final_roa, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\xmark"	
}

esttab eq1a_final_log_fixed_assets eq1b_final_log_fixed_assets eq1a_final_log_value_added eq1b_final_log_value_added eq1a_final_log_employment eq1b_final_log_employment ///
	   eq1a_final_log_salary eq1b_final_log_salary eq1a_tfp_y_LP eq1b_tfp_y_LP eq1a_tfp_y_ACF eq1b_tfp_y_ACF ///
       using "$out\reg_profitability.tex", replace ${tab_details} refcat(interaction1 "\textsc{\textbf{Panel A: Economic Profit Margins}}", nolabel) nomtitles ///
	   keep(interaction1 cit_exonerated final_epm) coeflabels(interaction1 "Exonerated $\times$ EPM" cit_exonerated "Exonerated" final_epm "EPM") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?") ///
	   mgroups("Fixed Assets" "Value Added" "Employment" "Salary" "TFP LP" "TFP ACF", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 1 0 1 0 1 0 1 0 1 0) erepeat(\cmidrule(lr){@span}))
	   
esttab eq2a_final_log_fixed_assets eq2b_final_log_fixed_assets eq2a_final_log_value_added eq2b_final_log_value_added eq2a_final_log_employment eq2b_final_log_employment ///
	   eq2a_final_log_salary eq2b_final_log_salary eq2a_tfp_y_LP eq2b_tfp_y_LP eq2a_tfp_y_ACF eq2b_tfp_y_ACF ///
	   using "$out\reg_profitability.tex", append ${tab_details} refcat(interaction2 "\textsc{\textbf{Panel B: Return on Assets}}", nolabel) nomtitles nonumber ///
	   eqlabels(none) keep(interaction2 cit_exonerated final_roa) coeflabels(interaction2 "Exonerated $\times$ ROA" cit_exonerated "Exonerated" final_roa "ROA") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")	   

	
	
****** Payment of dividends ******
eststo drop *

foreach var of varlist final_dividends final_divid_hold {	
	eststo eq1a_`var': qui reghdfe `var' interaction1 cit_exonerated final_epm ${controls1}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\cmark"
	
	eststo eq1b_`var': qui reghdfe `var' interaction1 cit_exonerated final_epm, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\xmark"
	
	eststo eq2a_`var': qui reghdfe `var' interaction2 cit_exonerated final_roa ${controls1}, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\cmark"
	
	eststo eq2b_`var': qui reghdfe `var' interaction2 cit_exonerated final_roa, a(${fixed_ef}) vce(cluster id)
	qui sum `var' if e(sample) == 1 
	estadd scalar mean = r(mean)
	estadd loc sector_fe "\cmark"
	estadd loc muni_fe   "\cmark"
	estadd loc year_fe   "\cmark"
	estadd loc controls  "\xmark"	
}

esttab eq1a_final_dividends eq1b_final_dividends eq1a_final_divid_hold eq1b_final_divid_hold ///
       using "$out\reg_dividends.tex", replace ${tab_details} refcat(interaction1 "\textsc{\textbf{Panel A: Economic Profit Margins}}", nolabel) nomtitles ///
	   keep(interaction1 cit_exonerated final_epm) coeflabels(interaction1 "Exonerated $\times$ EPM" cit_exonerated "Exonerated" final_epm "EPM") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?") ///
	   mgroups("Dividends Payment" "Dividends per Shareholder", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 1 0) erepeat(\cmidrule(lr){@span}))
	   
esttab eq2a_final_dividends eq2b_final_dividends eq2a_final_divid_hold eq2b_final_divid_hold ///
	   using "$out\reg_dividends.tex", append ${tab_details} refcat(interaction2 "\textsc{\textbf{Panel B: Return on Assets}}", nolabel) nomtitles nonumber ///
	   eqlabels(none) keep(interaction2 cit_exonerated final_roa) coeflabels(interaction2 "Exonerated $\times$ ROA" cit_exonerated "Exonerated" final_roa "ROA") sfmt(%9.0fc %9.3fc %9.3fc) ///
	   scalars("N Observations" "r2 R-Squared" "mean Mean Dep. Var." "sector_fe Sector FE?" "muni_fe Municipality FE?" "year_fe Year FE?" "controls Controls?")	   

