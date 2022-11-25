/*
Name:			context_graphs.do
Description: 	This do file uses secondary datasets to make the figures number 
1, 2, and 4 that are included in the Appendix of the paper "Firm
performance and tax incentives: Evidence from Honduras".
Date:			November, 2021
Modified:		November, 2022
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
keep if year == 2019

foreach var of varlist tax indv corp vat {
	qui sum `var' if cname == "Honduras"
	loc hnd_`var': di %5.1f r(mean)
	qui sum `var' if latam == 1
	loc latam_`var': di %5.1f r(mean)
	qui sum `var' if ocde == 1
	loc ocde_`var': di %5.1f r(mean)
}

g hnd_mean = .
replace hnd_mean = `hnd_tax'  in 1
replace hnd_mean = `hnd_indv' in 2
replace hnd_mean = `hnd_corp' in 3
replace hnd_mean = `hnd_vat'  in 4

g latam_mean = .
replace latam_mean = `latam_tax'  in 1
replace latam_mean = `latam_indv' in 2
replace latam_mean = `latam_corp' in 3
replace latam_mean = `latam_vat'  in 4

g ocde_mean = .
replace ocde_mean = `ocde_tax'  in 1
replace ocde_mean = `ocde_indv'	in 2
replace ocde_mean = `ocde_corp' in 3
replace ocde_mean = `ocde_vat'  in 4

g taxes = .
replace taxes = 1 in 1
replace taxes = 2 in 2
replace taxes = 3 in 3
replace taxes = 4 in 4
label def taxes 1 "Total Tax Revenue" 2 "Individual" 3 "Corporations" 4 "VAT"
label val taxes taxes

g trend = _n

graph bar hnd_mean latam_mean ocde_mean if trend <= 4, over(taxes) $graphop blabel(total, format(%10.1fc) color(blue)) ///
	   legend(row(1) order(1 "Honduras" 2 "Latin America" 3 "OECD")) ylabel(, nogrid) ///
	   ytitle("% of GDP") bar(1, color(navy%70)) bar(2, color(midblue%80)) bar(3, color(blue*.5%40)) 
graph export "$out/taxes.pdf", replace

	   
	   
********************************************************************************
* Scatter plot between tax expenditures and gdp per capita using GTED
********************************************************************************

* Tax expenditures coming from the Global Tax Expenditures Dataset (https://gted.net/)

import excel using "$path\GTED_FullDatabase.xlsx", firstrow clear sheet("RevenueForgone")
rename _all, lower
drop note
keep if year == 2019

preserve
import excel using "$path\GTED_FullDatabase.xlsx", firstrow clear sheet("TEProvisions")
rename _all, lower
keep provisionid countrycode taxbaselevel2
rename countrycode country
tempfile base
save `base'
restore

merge 1:1 country provisionid using `base'
keep if _merge == 3
drop _merge


* Building total tax expenditure and CIT tax axpenditure (both as % of GDP) by country 
replace rfofgdp = cond(missing(rfofgdp), 0, rfofgdp)
replace rfusd   = cond(missing(rfusd), 0, rfusd)

gen tax_exp_cit     = cond(taxbaselevel2 == "Corporate Income Tax (CIT)", rfofgdp, 0)
gen tax_exp_cit_usd = cond(taxbaselevel2 == "Corporate Income Tax (CIT)", rfusd, 0)

gcollapse (sum) tax_exp_total = rfofgdp (sum) tax_exp_cit (sum) tax_exp_cit_usd, by(country year)
format %20.0fc tax_exp_cit_usd

* Merge with Development Indicators
preserve
wbopendata, indicator(ny.gdp.pcap.pp.kd; ny.gdp.mktp.cd; sp.pop.1564.to; sp.pop.totl) clear long
rename ny_gdp_pcap_pp_kd gdp_per_capita
rename ny_gdp_mktp_cd gdp_current_usd
rename sp_pop_1564_to population_15_64
rename sp_pop_totl total_population
tempfile gdp
save `gdp'
restore

rename country countrycode
merge 1:1 countrycode year using `gdp', keepusing(countryname region gdp_per_capita gdp_current_usd population_15_64 total_population)
keep if _m == 3
drop _m

* Merge with 2019 statutory tax rates from KPMG
preserve
import excel using "$path\statutory_tax_rates.xlsx", firstrow clear sheet("cit_tax_rate")
tempfile rate
save `rate'
restore

merge 1:1 countryname using `rate'
keep if _m == 3
drop _m

* Merge with tax revenue as % of GDP from the IMF database
rename countryname cname 
merge m:1 cname year using "$path\fiscal_data_imf.dta", keepusing(tax)
drop if _m == 2
drop _m

* Building variables
gen cit_tax_expend_percap1 = log(tax_exp_cit_usd / population_15_64)
gen cit_tax_expend_percap2 = log(tax_exp_cit_usd / total_population)
gen log_gdp = log(gdp_per_capita)

label var log_gdp 		"Log(GDP Per Capita, PPP)"
label var tax_exp_total "Total tax expenditure (% GDP)"
label var tax_exp_cit   "CIT tax expenditure (% GDP)"
label var cit_tax_rate  "Corporate tax rate"

* Identifying Honduras for highlighting in the scatterplot
gen hnd 			   = countrycode if strpos(countrycode, "HND")   									
gen hnd_gdp 		   = log_gdp       			if countrycode == "HND"
gen hnd_tax_exp_total  = tax_exp_total 			if countrycode == "HND"
gen hnd_tax_exp_cit    = tax_exp_cit   			if countrycode == "HND"
gen hnd_cit_tax_exp_pc = cit_tax_expend_percap1 if countrycode == "HND"


* Scatterplot for the corporate tax expenditure and GDP per capita
preserve
qui sum tax_exp_cit, d
keep if tax_exp_cit < r(p99)

qui reg tax_exp_cit log_gdp, robust
loc b1: di %4.2fc _b[log_gdp]
loc s1: di %4.2fc _se[log_gdp]

twoway (scatter tax_exp_cit log_gdp if missing(hnd), mlcolor(blue%40) mfcolor(blue%40) msize(medlarge)) ///
	   (scatter hnd_tax_exp_cit hnd_gdp, msymbol(triangle) mcolor(red) mlabel(hnd) mlabcolor(red) msize(medlarge)) ///
	   (lfit tax_exp_cit log_gdp, lcolor(blue)), $graphop ytitle("Tax expenditure in the CIT (% GDP)") legend(off) ///
	   yscale(titlegap(3)) xscale(titlegap(3)) ylabel(0(1)2.5 0 "0%" .5 "0.5%" 1 "1%" 1.5 "1.5%" 2 "2%" 2.5 "2.5%") ///
	   text(1.7 7 "Slope = `b1' (`s1')", color(black) size(small))
	   graph export "$out\scatter_tax_exp_cit.pdf", replace   
restore	   


* Scatterplot for the corporate tax rate and corporate tax expenditure per capita
preserve
qui sum cit_tax_expend_percap1, d
keep if cit_tax_expend_percap1 > r(p1)

qui reg cit_tax_rate cit_tax_expend_percap1, robust
loc b2: di %4.2fc _b[cit_tax_expend_percap1]
loc s2: di %4.2fc _se[cit_tax_expend_percap1]

twoway (scatter cit_tax_rate cit_tax_expend_percap1 if missing(hnd), mlcolor(blue%40) mfcolor(blue%40) msize(medlarge)) ///
	   (scatter cit_tax_rate hnd_cit_tax_exp_pc, msymbol(triangle) mcolor(red) mlabel(hnd) mlabcolor(red) msize(medlarge)) ///
	   (lfit cit_tax_rate cit_tax_expend_percap1, lcolor(blue)), ytitle("Corporate tax rate") $graphop legend(off) ///
	   yscale(titlegap(3)) xscale(titlegap(3)) xtitle("Log(CIT tax expenditures per capita, in USD)") ///
	   text(12 7.5 "Slope = `b2' (`s2')", color(black) size(small)) ylabel(5(10)35 5 "5%" 15 "15%" 25 "25%" 35 "35%")
	   graph export "$out\scatter_tax_exp_percap.pdf", replace
restore


	   
	   
