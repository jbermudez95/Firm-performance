/*
Name:			descriptives.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates Tables number 2, 3, and 4 and also the figures number 3, and 5 that 
				are included in the Appendix of the paper "Firm performance and tax incentives: 
				evidence from Honduras". Also this do file generates figures A2, A3, and A4 that 
				are then included in the online appendix of the paper.
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
	global path "C:\Users\Owner\Desktop\firm-performance-github"		
	global out  "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Firm-performance"		
	global out  "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
}

run "$path\2. setup.do" 	// Run the do file that prepare all variables for descriptive statistics



*************************************************************************
*******               BUILDING SUMMARY STATISTICS                 ******* 
*************************************************************************

* Summary statistics on main characteristics (Table 2)
global var1 "size_small size_medium size_large final_primary final_secondary final_tertiary exporter non_exporter"
global var2 "final_none final_zoli final_rit final_zade final_zolitur final_zolt final_lit final_energy final_others"
global var3 "vat_sales_exempted vat_sales_taxed vat_purch_exempted vat_purch_taxed cit_total_taxed_inc cit_total_exempt_inc cit_total_costs_ded cit_total_costs_non_ded"

eststo drop *
mvdecode $var3, mv(0)

qui estpost summ $var1, d
est store panel1
esttab panel1 using "$out\summary", replace label booktabs nonum f noobs ///
	   refcat(size_small "\textsc{Panel A: Firms' Traits}", nolabel)   ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels("Mean" "SD" "N° Obs.")
	   
qui estpost summ $var2, d
est store panel2
esttab panel2 using "$out\summary", append label booktabs nonum f noobs ///
	   refcat(final_none "\textsc{Panel B: Firms' by Special Regime}" final_zoli "\textit{Export Oriented Regimes}" final_zolitur "\textit{Non Export Oriented Regimes}", nolabel) ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels(none)
	   
qui estpost summ vat_filler $var3, d
est store panel3
esttab panel3 using "$out\summary", append label booktabs nonum f noobs ///
	   refcat(vat_filler "\textsc{Panel C: Tax Base and Exemptions}" vat_sales_exempted "\textit{VAT Descriptives}" cit_total_taxed_inc "\textit{CIT Descriptives}", nolabel)   ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels(none)  
	   
	   
	   
* Balance table
eststo drop *	
global vars "final_log_fixed_assets final_log_value_added ihss_workers final_log_salary tfp_y_LP tfp_y_ACF final_epm final_roa final_eta final_gfsal final_turnover final_liquidity final_age final_mnc legal_proxy urban final_export_share final_import_share"
	   
eststo: qui estpost summ $vars, detail
est store pooled  
eststo: qui estpost summ $vars if cit_exonerated == 0, detail
est store nonex1
eststo: qui estpost summ $vars if cit_exonerated == 1, detail
est store ex1
eststo: qui estpost ttest $vars, by(cit_exonerated) unequal
est store diff1

preserve
drop if final_regime == 0
eststo: qui estpost summ $vars if final_regime == 1, detail
est store exor1
eststo: qui estpost summ $vars if final_regime == 2, detail
est store nexor1
eststo: qui estpost ttest $vars, by(final_regime) unequal
est store diff2
restore	

esttab pooled nonex1 ex1 diff1 exor1 nexor1 diff2 using "$out\balance_table.tex", replace collabels("Mean" "SD" "()-()") label tex f alignment(r) compress nonumbers nonotes ///
	   mtitles("Pooled Sample" "Non-Exonerated" "Exonerated" "Mean Diff" "Export-Oriented" "Non Export-Oriented" "Mean Diff") ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   mgroups("\textbf{Panel A}" "\textbf{Panel B: Pooled Comparison}" "\textbf{Panel C: Exonerated Only}", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(0 1 0 0 1 0 0) erepeat(\cmidrule(lr){@span})) ///
	   refcat(final_log_fixed_assets "\textsc{Panel A: Primary Outcomes}" final_epm "\textsc{Panel B: Secondary Outcomes}" final_age "\textsc{Panel C: Covariates}", nolabel)
	   


*************************************************************************
*******       			        ILUSTRATIONS   		    	      ******* 
*************************************************************************

global details "legend(region(lcolor(none))) graphr(color(white))"

* Distributions for TFP on value added (Figure A2)
twoway (hist final_log_productivity_va if cit_exonerated == 0, lcolor(blue%30) fcolor(blue%30)) ///
       (hist final_log_productivity_va if cit_exonerated == 1, lcolor(blue) fcolor(none)), ///
	   $details legend(row(1) order(1 "Non-Exonerated" 2 "Exonerated")) ///
	   xtitle("TFP on value added") ytitle("Density") 
graph export "$out/tfp_histogram.pdf", replace

preserve
kdensity final_log_productivity_va if final_industry == 1, bw(1) gen(x1 d1) nograph
kdensity final_log_productivity_va if final_industry == 2, bw(1) gen(x2 d2) nograph
kdensity final_log_productivity_va if final_industry == 3, bw(1) gen(x3 d3) nograph
twoway line d1 x1, lc(blue) 	  lw(thick)  		   	   		||   ///
	   line d2 x2, lc(navy) 	  lw(thick)                		||   ///
	   line d3 x3, lc(midblue%80) lw(thick) lpattern(longdash)  || , ///
	   $details legend(row(1) order(1 "Primary sector" 2 "Manufacturing" 3 "Services")) ///
	   ytitle("Density") xtitle("TFP on value added") 
*graph export "$out/tfp_sectors.pdf", replace
restore

* Distributions for TFP on sales (Figure A3)
twoway (hist final_log_productivity_y if cit_exonerated == 0, lcolor(blue%30) fcolor(blue%30)) ///
       (hist final_log_productivity_y if cit_exonerated == 1, lcolor(blue) fcolor(none)), ///
	   $details legend(row(1) order(1 "Non-Exonerated" 2 "Exonerated")) ///
	   xtitle("TFP on sales") ytitle("Density") 
graph export "$out/tfp_sales_histogram.pdf", replace

preserve
kdensity final_log_productivity_y if final_industry == 1, bw(1) gen(x1 d1) nograph
kdensity final_log_productivity_y if final_industry == 2, bw(1) gen(x2 d2) nograph
kdensity final_log_productivity_y if final_industry == 3, bw(1) gen(x3 d3) nograph
twoway line d1 x1, lc(blue) 	  lw(thick)  		   	   		||   ///
	   line d2 x2, lc(navy) 	  lw(thick)                		||   ///
	   line d3 x3, lc(midblue%80) lw(thick) lpattern(longdash)  || , ///
	   $details legend(row(1) order(1 "Primary sector" 2 "Manufacturing" 3 "Services")) ///
	   ytitle("Density") xtitle("TFP on sales") 
*graph export "$out/tfp_sales_sectors.pdf", replace
restore

* Distributions for different measures of productivity (Figure A4)
preserve
kdensity final_log_labor_productivity, bw(1) gen(x1 d1) nograph
kdensity final_log_productivity_y,     bw(1) gen(x2 d2) nograph
kdensity final_log_productivity_va,    bw(1) gen(x3 d3) nograph
twoway line d1 x1, lc(blue) 	 lw(thick)  ||   ///
	   line d2 x2, lc(green%70)  lw(thick)  ||   ///
	   line d3 x3, lc(orange%60) lw(thick)  || , ///
	   $details legend(row(1) order(1 "Labor productivity" 2 "TFP on sales" 3 "TFP on value added")) ///
	   ytitle("Density") xtitle("Log(Productivity)") 
graph export "$out/tfp_measures.pdf", replace
restore

/* Correlation between tax credits and productivity (Figure 6)
program graph_scatter 
	if final_industry == 1 {
		graph export "$out\scatter_primary.svg", replace
	} 
	else if final_industry == 2 {
		graph export "$out\scatter_manufacturing.svg", replace
	}
	else {
		graph export "$out\scatter_services.svg", replace
	}
end

forval val = 1/3 {
preserve
	keep if final_industry == `val'
	pwcorr final_log_productivity_y final_log_credits, sig star(.05)
	mat A = r(sig)
	loc r_y  : di %5.2f r(rho)
	loc sig_y: di %5.4f A[2,1]
	pwcorr final_log_productivity_va final_log_credits, sig star(.05)
	mat B = r(sig)
	loc r_va  : di %5.2f r(rho)
	loc sig_va: di %5.4f B[2,1]
	twoway scatter final_log_productivity_y final_log_credits, mcolor(blue%70) msize(medsmall)   ||  ///
		   scatter final_log_productivity_va final_log_credits, mcolor(navy%60) msize(medsmall)  ||  ///
		   lfit final_log_productivity_y final_log_credits, sort lcolor(blue) lwidth(medthick)   ||  ///
		   lfit final_log_productivity_va final_log_credits, sort lcolor(navy) lwidth(medthick)  ||, ///
		   $details ytitle("Log(productivity)") xtitle("Total tax credits") ///
		   text(6 -25 "Rho = `r_y'(`sig_y')", color(blue))         ///
		   text(5 -25 "Rho = `r_va'(`sig_va')", color(navy))       ///
		   ylabel(-8(2)6) xlabel(-30(5)5) ///
		   legend(row(2) order(1 "TFP on sales" 2 "TFP on value added" 3 "Lfit TFP on sales" 4 "Lfit TFP on value added")) 
	graph_scatter   
restore
}
*/	  

twoway (hist tfp_va_LP if cit_exonerated == 0, lcolor(blue%30) fcolor(blue%30)) ///
       (hist tfp_va_LP if cit_exonerated == 1, lcolor(blue) fcolor(none)), ///
	   $details legend(row(1) order(1 "Non-Exonerated" 2 "Exonerated")) ///
	   xtitle("TFP on value added") ytitle("Density") 	   


* Income percentiles
preserve
keep if !missing(cit_gross_income)
egen percentil = xtile(cit_gross_income), by(year) p(1(1)99)	 
tempfile perct
save `perct'
restore
merge 1:1 id year using `perct'
drop _m
	

* Credits distribution by firm size
preserve
keep if !missing(percentil)
collapse (sum) cit_cre_*, by(percentil)
egen cit_cre_total = rowtotal(cit_cre_*)
loc cre "exo withholding pay surplus assignments compensation employment isran"

gen exo 		 = (cit_cre_exo / cit_cre_total) * 100
gen withholding  = ((cit_cre_exo + cit_cre_withholding) / cit_cre_total) * 100
gen pay 		 = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay) / cit_cre_total) * 100
gen surplus 	 = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay + cit_cre_surplus) / cit_cre_total) * 100 
gen assignments  = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay + cit_cre_surplus + cit_cre_assignments) / cit_cre_total) * 100 
gen compensation = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay + cit_cre_surplus + cit_cre_assignments + cit_cre_compensation) / cit_cre_total) * 100 
gen employment 	 = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay + cit_cre_surplus + cit_cre_assignments + cit_cre_compensation + cit_cre_employment) / cit_cre_total) * 100 
gen isran 		 = ((cit_cre_exo + cit_cre_withholding + cit_cre_pay + cit_cre_surplus + cit_cre_assignments + cit_cre_compensation + cit_cre_employment + cit_cre_isran) / cit_cre_total) * 100 
   
twoway (area exo percentil, fcolor(dknavy%80) lcolor(dknavy%80)) (rarea exo withholding percentil, fcolor(navy%60) lcolor(navy%60)) ///
       (rarea withholding pay percentil, fcolor(blue%60) lcolor(blue%60)) (rarea pay surplus percentil, fcolor(blue%20) lcolor(blue%20)) ///
	   (rarea surplus assignments percentil, fcolor(midblue%60) lcolor(midblue%60)) (rarea assignments compensation percentil, fcolor(ebblue%60) lcolor(ebblue%60))  /// 
	   (rarea compensation employment percentil, fcolor(eltblue%60)) (rarea employment isran percentil, fcolor(gray%60) lcolor(gray%60)), ///
	   $details ylab(0(20)100 0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", nogrid) xtitle("Percentile on Gross Income") xlab(0(10)100) ///
	   legend(row(2) lab(1 "Exempt") lab(2 "Withholding") lab(3 "Payments") lab(4 "Surplus") lab(5 "Assignments") lab(6 "Compensation") lab(7 "New jobs") lab(8 "CIT - Net assets") size(small))
	   graph export "$out\credits_share.pdf", replace
restore  
	   
* Ratio between tax exempt credits and total credits
preserve
keep if !missing(percentil)
gen ratio_exoneration = (final_credits / cit_tax_liability) *100
replace ratio_exoneration = cond(ratio_exoneration > 1, 1, ratio_exoneration)
replace ratio_exoneration = cond(missing(ratio_exoneration), 0, ratio_exoneration)
collapse (mean) ratio_exoneration, by(percentil)
twoway (scatter ratio_exoneration percentil, mcolor(blue%40)) ///
	   (fpfit ratio_exoneration percentil if percentil > 4, lcolor(blue)), ///
	   ytitle("Exempt tax credits / Tax liability") xtitle("Percentile on Gross Income") ///
	   $details legend(off) yscale(titlegap(3)) xscale(titlegap(3)) xlab(0(10)100) ///
	   ylabel(.75 "75%" .8 "80%" .85 "85%" .9 "90%" .95 "95%" 1 "100%")
	   graph export "$out\credits_ratio.pdf", replace
restore
	   
	   
	   
	   
	   
	   
	   
	   