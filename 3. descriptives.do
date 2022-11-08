/*
Name:			descriptives.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates Tables number 2, 3, and 4 and also the figures number 3, and 5 that 
				are included in the Appendix of the paper "Firm performance and tax incentives: 
				evidence from Honduras". Also this do file generates figures A2, A3, and A4 that 
				are then included in the online appendix of the paper.
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
global var1 "size_small size_medium size_large final_primary final_secondary final_tertiary"
global var2 "final_none final_zoli final_rit final_zade final_zolitur final_zolt final_lit final_energy final_others"
global var3 "cit_total_taxed_inc cit_total_exempt_inc cit_total_costs_ded cit_total_costs_non_ded vat_sales_exempted vat_sales_taxed vat_purch_exempted vat_purch_taxed"

eststo drop *
mvdecode $var3, mv(0)

qui estpost summ $var1, d
est store panel1
esttab panel1 using "$out\summary", replace label booktabs nonum f noobs 		///
	   refcat(size_small "\textsc{Panel A: Firms' Traits}", nolabel)   ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels("Mean" "SD" "N° Obs.")
	   
qui estpost summ $var2, d
est store panel2
esttab panel2 using "$out\summary", append label booktabs nonum f noobs  		///
	   refcat(final_none "\textsc{Panel B: Firms' by Special Regime}" final_zoli "\textit{Export Oriented Regimes}" final_zolitur "\textit{Non Export Oriented Regimes}", nolabel) ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels(none)
	   
qui estpost summ $var3, d
est store panel3
esttab panel3 using "$out\summary", append label booktabs nonum f noobs 			  	  ///
	   refcat(cit_total_taxed_inc "\textsc{Panel C: Tax Base and Exemptions}", nolabel)   ///
	   cells("mean(fmt(%20.2fc)) sd count(fmt(%20.0fc))") collabels(none)  
	   
* Balance table
eststo drop *		
/*preserve															
qui summ final_npm, d	
keep if final_npm > r(p1)	
qui summ     final_npm, d
estpost summ final_npm, detail quietly
est store npm_
qui summ 	 final_npm if cit_exonerated == 0, d
estpost summ final_npm if cit_exonerated == 0, detail quietly
est store npm_nonex1
qui summ 	 final_npm if cit_exonerated == 1, d
estpost summ final_npm if cit_exonerated == 1, detail quietly
est store npm_ex1
estpost ttest final_npm, by(cit_exonerated) unequal quietly
est store npm_diff1
restore

preserve
drop if final_regime == 0
qui summ final_npm, d
keep if final_npm > r(p1)
qui summ 	 final_npm if final_regime == 1, d
estpost summ final_npm if final_regime == 1, detail quietly
est store npm_exor1
qui summ 	 final_npm if final_regime == 2, d
estpost summ final_npm if final_regime == 2, detail quietly
est store npm_nexor1
estpost ttest final_npm, by(final_regime) unequal quietly
est store npm_diff2
restore

esttab npm_ npm_nonex1 npm_ex1 npm_diff1 npm_exor1 npm_nexor1 npm_diff2 using "$out\tab1.tex", replace ///
	   mtitles("Pooled Sample" "Non-Exonerated" "Exonerated" "Mean Diff" "Export-Oriented" "Non Export-Oriented" "Mean Diff") ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   mgroups("" "\textbf{Pooled Comparison}" "\textbf{Exonerated Only}", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(0 1 0 0 1 0 0) erepeat(\cmidrule(lr){@span})) ///
	   collabels("Mean" "SD" "()-()") label tex f alignment(r) compress nonumbers noobs nonotes 
   
preserve															
qui summ final_epm, d	
keep if final_epm > r(p5)	
qui summ     final_epm, d
estpost summ final_epm, detail quietly
est store epm_
qui summ 	 final_epm if cit_exonerated == 0, d
estpost summ final_epm if cit_exonerated == 0, detail quietly
est store epm_nonex1
qui summ 	 final_epm if cit_exonerated == 1, d
estpost summ final_epm if cit_exonerated == 1, detail quietly
est store epm_ex1
estpost ttest final_epm, by(cit_exonerated) unequal quietly
est store epm_diff1
restore

preserve
drop if final_regime == 0
qui summ final_epm, d
keep if final_epm > r(p5)
qui summ 	 final_epm if final_regime == 1, d
estpost summ final_epm if final_regime == 1, detail quietly
est store epm_exor1
qui summ 	 final_epm if final_regime == 2, d
estpost summ final_epm if final_regime == 2, detail quietly
est store epm_nexor1
estpost ttest final_epm, by(final_regime) unequal quietly
est store epm_diff2
restore

esttab epm_ epm_nonex1 epm_ex1 epm_diff1 epm_exor1 epm_nexor1 epm_diff2 using "$out\tab1_oct.tex", replace ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   nomtitles collabels(none) label tex f alignment(r) compress nonumbers noobs nonotes 

	   esttab epm_ epm_nonex1 epm_ex1 epm_diff1 epm_exor1 epm_nexor1 epm_diff2 using "$out\tab1_oct.tex", replace ///
	      mtitles("Pooled Sample" "Non-Exonerated" "Exonerated" "Mean Diff" "Export-Oriented" "Non Export-Oriented" "Mean Diff") ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   mgroups("" "\textbf{Pooled Comparison}" "\textbf{Exonerated Only}", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(0 1 0 0 1 0 0) erepeat(\cmidrule(lr){@span})) ///
	   collabels("Mean" "SD" "()-()") label tex f alignment(r) compress nonumbers noobs nonotes */
	   
global vars "final_log_net_fixed_assets final_log_value_added ihss_workers final_log_salary final_log_productivity_va final_epm final_eta final_gfsal final_turnover final_liquidity final_age final_mnc legal_proxy urban tamaño_ot final_export_share final_import_share"
	   
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

/*esttab pooled nonex1 ex1 diff1 exor1 nexor1 diff2 using "$out\tab1_oct.tex", append ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   nomtitles collabels(none) label tex f alignment(r) compress nonumbers*/
	   
	   esttab pooled nonex1 ex1 diff1 exor1 nexor1 diff2 using "$out\tab1_oct.tex", replace ///
	      mtitles("Pooled Sample" "Non-Exonerated" "Exonerated" "Mean Diff" "Export-Oriented" "Non Export-Oriented" "Mean Diff") ///
	   cells("mean(pattern(1 1 1 0 1 1 0) fmt(2)) sd(pattern(1 1 1 0 1 1 0) fmt(2) par) b(star pattern(0 0 0 1 0 0 1) fmt(2))") ///
	   mgroups("" "\textbf{Pooled Comparison}" "\textbf{Exonerated Only}", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(0 1 0 0 1 0 0) erepeat(\cmidrule(lr){@span})) ///
	   collabels("Mean" "SD" "()-()") label tex f alignment(r) compress nonumbers nonotes 

	   
* Sample distribution by special regime and industry (Table 3)
preserve
keep if cit_exonerated == 1
gen final_aux_regime = cit_regime
replace final_aux_regime = 3 if (cit_regime == 7 | cit_regime == 9) 
label def final_aux_regime 0 "None" 1 "ZIP" 2 "ZOLI" 3 "Tourism" 4 "RIT" 5 "Others" 14 "ZADE" 23 "Renewable Energy" 
label val final_aux_regime final_aux_regime
tab final_aux_regime final_industry, row nofreq
estpost tab final_aux_regime final_industry, nototal
esttab using "$out\tab2.tex", cell(colpct(fmt(1))) unstack label ///
	   tex f alignment(r) noobs nonumber collabels("") compress replace  
restore

/*Correlation matrix between explanatory variables (Table 4)
global controls "final_log_age mnc final_fixasset_quint final_log_input_costs final_log_financial_costs final_capital_int final_labor_int final_export_share final_import_share"
qui correlate $controls
estpost correlate $controls, matrix listwise
est store corr_matrix
esttab corr_matrix using "$out\corr_matrix.tex", replace b(3) unstack ///
	   not nonumbers nonotes noobs compress label */

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
	   $details legend(off) yscale(titlegap(3)) xscale(titlegap(3)) ///
	   ylabel(.75 "75%" .8 "80%" .85 "85%" .9 "90%" .95 "95%" 1 "100%")
	   graph export "$out\credits_ratio.pdf", replace
restore


* Credits distribution by firm size
preserve
keep if !missing(percentil)
collapse (sum) cit_cre_*, by(percentil)
egen cit_cre_total = rowtotal(cit_cre_*)
loc cre "exo withholding pay surplus assignments compensation employment isran"
foreach c of loc cre {
	gen `c' = cit_cre_`c' / cit_cre_total
}
drop cit_cre_*
stackedcount `cre' percentil 
restore
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   