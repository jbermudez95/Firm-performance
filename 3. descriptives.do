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
	global path "C:\Users\Owner\Desktop\Firm-performance"		
	global out  "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Firm-performance"		
	global out  "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
}

*Run the do file preparing every variable for descriptive statistics
run "$path\2. setup.do" 	



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
global vars "final_log_fixed_assets final_log_value_added ihss_workers final_log_salary tfp_y_LP tfp_y_ACF final_epm final_roa final_eta final_gfsal final_turnover final_liquidity final_age final_mnc legal_proxy urban final_export_share final_import_share final_labor_int final_capital_int"
	   
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
refcat(final_log_fixed_assets "\textsc{Primary Outcomes}" final_epm "\textsc{Secondary Outcomes}" final_age "\textsc{Covariates}", nolabel)
	   


*************************************************************************
*******       			        ILUSTRATIONS   		    	      ******* 
*************************************************************************

global graphop "legend(region(lcolor(none))) graphr(color(white))"

* Income percentiles
preserve
keep if !missing(cit_gross_income)
egen percentil = xtile(cit_gross_income), by(year) p(1(1)99)	
egen decil     = xtile(cit_gross_income), by(year) p(1(1)10)	 
tempfile perct
save `perct'
restore
merge 1:1 id year using `perct'
drop _m


* Credits distribution by firm size
preserve
keep if !missing(percentil)
bys percentil: egen exo_max = max(cit_cre_exo)
drop if cit_cre_exo == exo_max
drop exo_max
collapse (sum) cit_cre_*, by(percentil)

egen cit_cre_total = rowtotal(cit_cre_*)
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
	   $graphop ylab(0(20)100 0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", nogrid) xtitle("Percentile on Gross Income") xlab(0(10)100) xscale(titlegap(3)) ///
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
	   $graphop legend(off) yscale(titlegap(3)) xscale(titlegap(3)) xlab(0(10)100) ///
	   ylabel(.75 "75%" .8 "80%" .85 "85%" .9 "90%" .95 "95%" 1 "100%")
	   graph export "$out\credits_ratio.pdf", replace
restore


* Distributions for TFP and correlation between alternative measures
foreach var of varlist tfp_y_LP tfp_y_ACF tfp_va_LP tfp_va_ACF{
    loc labvar: var label `var'
    twoway (hist tfp_y_LP if cit_exonerated == 0, lcolor(blue%30) fcolor(blue%30)) ///
           (hist tfp_y_LP if cit_exonerated == 1, lcolor(blue) fcolor(none)), ///
	       $graphop legend(row(1) order(1 "Non-Exonerated" 2 "Exonerated")) ///
	       xtitle("`labvar'") ytitle("Density") ylab(0(0.2)1) xscale(titlegap(3)) yscale(titlegap(3))
           graph export "$out/`var'.pdf", replace
}

binscatter tfp_y_LP tfp_y_ACF, nquantiles(100) ytitle("TFP on sales, LP method") $graphop legend(off) ///
	       yscale(titlegap(3)) mcolors(blue%20) xtitle("TFP on sales, ACF method") xscale(titlegap(3)) yscale(titlegap(3)) 		   
	       graph export "$out\tfp_bin_sales.pdf", replace
		   
binscatter tfp_va_LP tfp_va_ACF, nquantiles(100) ytitle("TFP on value-added, LP method") $graphop legend(off) ///
	       yscale(titlegap(3)) mcolors(blue%20) xtitle("TFP on value-added, ACF method") xscale(titlegap(3)) yscale(titlegap(3)) 		   
	       graph export "$out\tfp_bin_va.pdf", replace
		   





	   
	   
	   
	   
	   
	   
	   
	   