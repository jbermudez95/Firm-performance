/*
Name:			context_graphs.do
Description: 	This do file uses secondary datasets to make the figures number 
1, 2, and 4 that are included in the Appendix of the paper "Firm
performance and tax incentives: Evidence from Honduras".
Date:			November, 2021
Modified:		November, 2021
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all

* Insert personal directories
if "`c(username)'" == "Owner" {
	global path "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out  "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out  "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
}	

global graphop "legend(region(lcolor(none))) graphr(color(white))"


********************************************************************************
* Bar graph for taxes as % of GDP
********************************************************************************

use "$path\fiscal_data_imf.dta", replace
drop *_src ccode

g latam = 1 if (cname == "Argentina" | cname == "Brazil" | cname == "Chile" | cname == "Costa Rica" | /// 
                cname == "Colombia"  | cname == "Mexico" | cname == "Peru"  | cname == "Uruguay")
replace latam = 0 if missing(latam)

g ocde = 1 if (cname == "Canada"   | cname == "United States"   | cname == "United Kingdom" | cname == "Denmark"     | ///
               cname == "Iceland"  | cname == "Norway"          | cname == "Turkey"         | cname == "Spain"       | ///
			   cname == "Portugal" | cname == "France"          | cname == "Ireland"        | cname == "Belgium"     | ///
			   cname == "Germany"  | cname == "Greece"          | cname == "Sweden"         | cname == "Switzerland" | /// 
			   cname == "Austria"  | cname == "Netherlands"     | cname == "Luxembourg"     | cname == "Italy"       | ///
			   cname == "Japan"    | cname == "Finland"         | cname == "Australia"      | cname == "New Zealand" | ///
			   cname == "Mexico"   | cname == "Czech Republic"  | cname == "Hungary"        | cname == "Poland"      | /// 
			   cname == "Korea"    | cname == "Slovak Republic" | cname == "Chile"          | cname == "Slovenia"    | ///
			   cname == "Israel"   | cname == "Estonia"         | cname == "Latvia"         | cname == "Lithuania"   | ///
			   cname == "Colombia" | cname == "Costa Rica") 
replace ocde = 0 if missing(ocde)

keep if (latam == 1 | ocde == 1 | cname == "Honduras")
keep if year == 2018

qui sum tax if cname == "Honduras"
loc hnd_tax: di %5.1f r(mean)
qui sum indv if cname == "Honduras"
loc hnd_indv: di %5.1f r(mean)
qui sum corp if cname == "Honduras"
loc hnd_corp: di %5.1f r(mean)
qui sum goods if cname == "Honduras"
loc hnd_goods: di %5.1f r(mean)

qui sum tax if latam == 1
loc latam_tax: di %5.1f r(mean)
qui sum indv if latam == 1
loc latam_indv: di %5.1f r(mean)
qui sum corp if latam == 1
loc latam_corp: di %5.1f r(mean)
qui sum goods if latam == 1
loc latam_goods: di %5.1f r(mean)

qui sum tax if ocde == 1
loc ocde_tax: di %5.1f r(mean)
qui sum indv if ocde == 1
loc ocde_indv: di %5.1f r(mean)
qui sum corp if ocde == 1
loc ocde_corp: di %5.1f r(mean)
qui sum goods if ocde == 1
loc ocde_goods: di %5.1f r(mean)

g hnd_mean = .
replace hnd_mean = `hnd_tax'   in 1
replace hnd_mean = `hnd_indv'  in 2
replace hnd_mean = `hnd_corp'  in 3
replace hnd_mean = `hnd_goods' in 4

g latam_mean = .
replace latam_mean = `latam_tax'   in 1
replace latam_mean = `latam_indv'  in 2
replace latam_mean = `latam_corp'  in 3
replace latam_mean = `latam_goods' in 4

g ocde_mean = .
replace ocde_mean = `ocde_tax'   in 1
replace ocde_mean = `ocde_indv'	 in 2
replace ocde_mean = `ocde_corp'  in 3
replace ocde_mean = `ocde_goods' in 4

g taxes = .
replace taxes = 1 in 1
replace taxes = 2 in 2
replace taxes = 3 in 3
replace taxes = 4 in 4
label def taxes 1 "Tax Revenue" 2 "Individual" 3 "Corporations" 4 "Goods & Services"
label val taxes taxes

g trend = _n

graph bar hnd_mean latam_mean ocde_mean if trend <= 4, over(taxes) $graphop blabel(total, format(%10.1fc) color(blue)) ///
	   legend(row(1) order(1 "Honduras" 2 "Latin America" 3 "OECD")) ///
	   ytitle("% of GDP") bar(1, color(navy%70)) bar(2, color(midblue%80)) bar(3, color(blue*.5%40)) 
graph export "$out/taxes.pdf", replace


********************************************************************************
* Scatter plot between tax expenditures and gdp per capita
********************************************************************************

*  Dataset was generated manually based on 
* https://www.ciat.org/Biblioteca/DocumentosdeTrabajo/2019/DT_06_2019_pelaez.pdf
import excel using "$path\GTED_FullDatabase.xlsx", firstrow clear sheet("RevenueForgone")
rename _all, lower
drop note

* Getting tax expenditures by country during 2019
keep if year == 2019

* Merge with tax preassure from the IMF database
rename country cname
merge 1:1 cname year using "$path\fiscal_data_imf.dta", keepusing(tax)
drop if _m == 2
drop _m

* Merge with GDP Per capita from the World Bank open dataset
* ssc install wbopendata
preserve
wbopendata, indicator(ny.gdp.pcap.pp.kd; ny.gdp.mktp.cd; sp.pop.1564.to; sp.pop.totl) clear long
rename ny_gdp_pcap_pp_kd gdp_per_capita
rename ny_gdp_mktp_cd gdp_current_usd
rename sp_pop_1564_to population_15_64
rename sp_pop_totl total_population
tempfile gdp
save `gdp'
restore

merge 1:1 countrycode year using `gdp', keepusing(region gdp_per_capita gdp_current_usd population_15_64 total_population)
keep if _m == 3
drop _m

* Building variables
gen cit_tax_expend_percap1 = log(((tax_exp_cit / 100) * gdp_current_usd) / population_15_64)
gen cit_tax_expend_percap2 = log(((tax_exp_cit / 100) * gdp_current_usd) / total_population)

gen log_gdp = log(gdp_per_capita)
label var log_gdp 		"Log(GDP Per Capita, PPP)"
label var tax_exp_total "Total tax expenditure (% GDP)"
label var tax_exp_cit   "CIT tax expenditure (% GDP)"


* Identifying Honduras for highlighting in the scatterplot
gen hnd 			   = countrycode if strpos(countrycode, "HND")   									
gen hnd_gdp 		   = log_gdp       			if countrycode == "HND"
gen hnd_tax_exp_total  = tax_exp_total 			if countrycode == "HND"
gen hnd_tax_exp_cit    = tax_exp_cit   			if countrycode == "HND"
gen hnd_cit_tax_exp_pc = cit_tax_expend_percap1 if countrycode == "HND"

* Raw Correlations and Scatterplots
twoway (scatter tax_exp_total log_gdp if missing(hnd), mlcolor(blue%40) mfcolor(blue%40) msize(medlarge)) ///
	   (scatter hnd_tax_exp_total hnd_gdp, msymbol(triangle) mcolor(red) mlabel(hnd) mlabcolor(red) msize(medlarge)) ///
	   (lfit tax_exp_total log_gdp, lcolor(blue)), ytitle("Total tax expenditure (% GDP)") ///
	   $graphop yscale(titlegap(3)) xscale(titlegap(3)) ///
	   ylabel(0(2)10 0 "0%" 2 "2%" 4 "4%" 6 "6%" 8 "8%" 10 "10%") legend(off)
	   graph export "$out\scatter_tax_exp_total.pdf", replace
	   
twoway (scatter cit_tax_expend_percap1 cit_tax_rate if missing(hnd), mlcolor(blue%40) mfcolor(blue%40) msize(medlarge)) ///
	   (scatter hnd_cit_tax_exp_pc cit_tax_rate, msymbol(triangle) mcolor(red) mlabel(hnd) mlabcolor(red) msize(medlarge)) ///
	   (lfit cit_tax_expend_percap1 cit_tax_rate  if region == "LCN", lcolor(blue)), xtitle("Corporate tax rate") ///
	   yscale(titlegap(3)) xscale(titlegap(3)) ytitle("CIT tax expenditures per capita (in USD)") ///
	   $graphop legend(off)
	   graph export "$out\scatter_tax_exp_percap.pdf", replace	   
	   

	   
********************************************************************************
* Bar graph for tax expenditures
********************************************************************************
use "$path\tax_expenditures.dta", replace
 
graph bar tax_exp_total, over(country) asyvars $graphop   ///
	   ytitle("% of GDP") bar(1, color(navy%70)) bar(2, color(midblue%80)) ///
	   bar(3, color(blue*.5%40)) blabel(total, format(%10.2fc) color(blue)) ///
	   legend(row(1) order(1 "Honduras" 2 "Latin America" 3 "North-America & Europe"))
graph export "$out/taxexp_tot.pdf", replace

graph bar tax_exp_corps, over(country) asyvars $graphop   ///
	   ytitle("% of GDP") bar(1, color(navy%70)) bar(2, color(midblue%80)) ///
	   bar(3, color(blue*.5%40)) blabel(total, format(%10.2fc) color(blue)) ///
	   legend(row(1) order(1 "Honduras" 2 "Latin America" 3 "North-America & Europe"))
graph export "$out/taxexp_corps.pdf", replace

* Fiscal sacrifice by sector
use "$path\fiscal_sacr.dta", replace
g m = 0
replace m = 119.4 in 1
replace m = 117.4 in 2
replace m = 72.2 in 3
graph bar m, over(final_industry) asyvars $graphop  ///
	   ytitle("Percentages") bar(1, color(navy%70)) bar(2, color(midblue%80)) ///
	   bar(3, color(blue*.5%40)) blabel(total, format(%10.1fc) color(blue)) ///
	   legend(row(1) order(1 "Primary" 2 "Manufacturing" 3 "Services")) bargap(20)  
graph export "$out/fiscal_sacr.pdf", replace
