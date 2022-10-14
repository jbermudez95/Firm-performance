/*
Name:			setup.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates the variables that are later used for the paper "Firm performance 
				and tax incentives: evidence from Honduras". It also generates table A3
				for TFP estimations that are inlcuded in the online appendix of the paper.
Date:			November, 2021
Modified:		October, 2022
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
clear matrix
set more off

* Directories
if "`c(username)'" == "Owner" {
	global path "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
} 

/* Packages required for estimations
ssc install winsor
ssc install acfest
ssc install eststo
ssc install estout
ssc install reghdfe
ssc install ftools
*/
*************************************************************************
*******                           SET UP                          ******* 
*************************************************************************

use "$path\final_dataset1.dta", replace

* Drop firms in the financial sector, real state, education, public administration, diplomatics or without economic activity. 
* Drop cooperatives, non-profit organizations, public-private partnerships, and simplified regimes.
* Drop firms with only one employee or zero values from social security records.
drop if (codigoseccion == "K" | codigoseccion == "L" | codigoseccion == "O" | codigoseccion == "P" | codigoseccion == "U" | codigoseccion == "Z")    
drop if (cit_regime == 8 | cit_regime == 15 | cit_regime == 20 | cit_regime == 27) 		       
drop if ihss_workers == 1 | missing(ihss_workers)

* Categories for the different special fiscal regimes (according to the number code in the CIT form). 
* We reclassify firms advocated to the Tourism Incentives Law to the LIT regime.
replace cit_regime = 0 if cit_regime == 6
replace cit_regime = 5 if cit_regime == 13
replace cit_regime = 9 if cit_regime == 21
replace cit_regime = 1 if cit_regime == 14
label def cit_regime 0 "None" 1 "ZADE" 2 "ZOLI" 3 "ZOLT" 4 "RIT" 5 "Other regimes" ///	
				     7 "ZOLITUR" 9 "LIT" 23 "Renewable energy", replace
label val cit_regime cit_regime		

* Dummy identifying the type of tax exemption
g 		final_regime = 0
replace	final_regime = 1 if inlist(cit_regime, 1, 2, 4)
replace final_regime = 2 if inlist(cit_regime, 3, 5, 7, 9, 23)
label def final_regime 0 "Taxed" 1 "Export Oriented" 2 "Non-Export Oriented"
label val final_regime final_regime

* Economic activities and industries
recode codigo (1/990 = 1) (1010/3320 = 2) (3510/4390 = 3) (4510/4540 = 4) (4610/4690 4711/4799 = 5) ///
   (4910/5630 = 6) (5811/6630 = 7) (6810/8430 = 8) (8510/9329 = 9) (9411/9900 = 10) (. 0 9988= 11), gen(activity_sector)
replace activity_sector = 1  if activity_sector == 11 & inlist(codigoseccion, "A","B")
replace activity_sector = 2  if activity_sector == 11 & inlist(codigoseccion, "C")
replace activity_sector = 3  if activity_sector == 11 & inlist(codigoseccion, "D","E","F")
replace activity_sector = 5  if activity_sector == 11 & inlist(codigoseccion, "G")
replace activity_sector = 6  if activity_sector == 11 & inlist(codigoseccion, "H","I")
replace activity_sector = 7  if activity_sector == 11 & inlist(codigoseccion, "J")
replace activity_sector = 8  if activity_sector == 11 & inlist(codigoseccion, "M","N")
replace activity_sector = 9  if activity_sector == 11 & inlist(codigoseccion, "Q","R")
replace activity_sector = 10 if activity_sector == 11 & inlist(codigoseccion, "S","T")
lab def activity_sector 1 "Agriculture and extraction" 2 "Manufacturing" 3 "Utilities and construction" ///
						4 "Automotive" 5 "Wholesale and retail" 6 "Transportation, housing and toruism" 7 "Comunications and technology" ///
						8 "Professional and technical services" 9 "Health and arts" 10 "Other services", replace
lab val activity_sector activity_sector
	
gen final_industry = cond(activity_sector == 1, 1, cond(activity_sector == 2 | activity_sector ==  3, 2, ///
					 cond(activity_sector != 1 | activity_sector != 2 | activity_sector != 3, 3, .)))
label def final_industry 1 "Primary" 2 "Industry - secondary" 3 "Services - tertiary"
label val final_industry final_industry
	
* Minor settings
encode municipio, gen(province)
egen x = group(id)
drop id
rename x id
order id, first


*************************************************************************
*******               BUILDING VARIABLES OF INTEREST              ******* 
*************************************************************************

* Constructing variables for descriptive statistics and empirical estimations. 
* Variables are adjusted for inflation using 2010 = 100, and presented in millions of Lempiras.
loc mill = 1000000
loc ipc2017 = 138.0563124
loc ipc2018 = 144.0660006
foreach var of varlist cit_current_assets cit_fixed_assets cit_total_assets cit_current_liabilities 		///
					cit_gross_income cit_deductions cit_fixed_assets_depr cit_sales_local cit_sales_exports ///
					cit_turnover_exempt cit_turnover_taxed cit_other_inc_taxed cit_other_inc_exempt 		///
					cit_total_exempt_inc cit_total_taxed_inc cit_total_inc cit_goods_materials_non_ded 		///
					cit_com_costs cit_prod_costs cit_goods_materials_ded cit_labor_non_ded cit_labor_ded 	///
					cit_financial_non_ded cit_financial_ded cit_operations_non_ded cit_operations_ded 		///
					cit_losses_other_non_ded cit_losses_other_ded cit_precio_trans_ded cit_total_costs_ded 	///
					cit_total_costs_non_ded cit_total_costs cit_total_credits_r cit_total_credits_an 		///
					cit_total_credits_as cit_cre_exo vat_sales_exempted vat_sales_taxed vat_sales_exports 	///
					vat_sales_local vat_purch_exempted vat_purch_taxed vat_purch_imports vat_purch_local 	///
					custom_import custom_export final_sales_local final_exports final_imports final_total_sales final_total_purch {
							replace `var' = `var' / `mill' if !missing(`var')
							replace `var' = 0 if `var' < 0 & !missing(`var')
							replace `var' = ((`var' / `ipc2017') * 100) if year == 2017 & !missing(`var')
							replace `var' = ((`var' / `ipc2018') * 100) if year == 2018 & !missing(`var')	
							replace `var' = cond(missing(`var'), 0, `var')
}

g final_credits				 = cit_total_credits_r + cit_total_credits_an + cit_total_credits_as
g final_input_costs     	 = cit_goods_materials_non_ded + cit_goods_materials_ded
g final_financial_costs 	 = cit_financial_ded + cit_financial_non_ded
g final_net_fixed_assets     = cit_fixed_assets - cit_fixed_assets_depr
g final_total_labor_costs    = cit_labor_ded + cit_labor_non_ded
g final_net_labor_costs 	 = cit_labor_ded - cit_labor_non_ded
g final_value_added    		 = final_total_sales - final_input_costs
g final_salary               = final_total_labor_costs / ihss_workers
g final_labor_productivity   = final_total_sales / ihss_workers

g final_age        = year - date_start
replace final_age  = 1 if final_age <= 0

g final_log_credits				 = log(1 + final_credits)
g final_log_age					 = log(1 + final_age)
g final_log_sales				 = log(1 + final_total_sales)
g final_log_input_costs 		 = log(1 + final_input_costs)
g final_log_financial_costs 	 = log(1 + final_financial_costs)
g final_log_employment   		 = log(ihss_workers)
g final_log_total_assets		 = log(1 + cit_total_assets)
g final_log_net_fixed_assets	 = log(1 + final_net_fixed_assets)
g final_log_value_added     	 = log(1 + final_value_added)
g final_log_salary               = log(1 + final_salary)
g final_log_labor_productivity   = log(final_labor_productivity)

replace final_total_sales = final_exports if (final_total_sales == 0 & final_exports > 0)
g final_export_share        = final_exports / final_total_sales
replace final_export_share  = 1 if final_export_share > 1 & !missing(final_export_share)

replace final_total_purch = final_imports if (final_total_purch == 0 & final_imports > 0)
g final_import_share		= final_imports / final_total_purch
replace final_import_share  = 1 if final_import_share > 1 & !missing(final_import_share)

g final_capital_inte = final_net_fixed_assets / final_total_sales
winsor final_capital_inte if !missing(final_capital_inte), gen(final_capital_int) p(0.07)
drop final_capital_inte

g final_labor_inte = final_net_labor_costs / final_total_sales		
winsor final_labor_inte if !missing(final_labor_inte), gen(final_labor_int) p(0.01)
drop final_labor_inte

/*g final_gross_pmargin       = (final_total_sales - final_input_costs) / final_total_sales
replace final_gross_pmargin = 0 if missing(final_gross_pmargin)
winsor  final_gross_pmargin, gen(final_gpm) p(0.01)
replace final_gpm = -1 if final_gpm < -1
replace final_gpm = 1 if final_gpm > 1
drop final_gross_pmargin

g final_net_pmargin       = (cit_turnover - cit_deductions) / cit_turnover
replace final_net_pmargin = 0 if missing(final_net_pmargin)
winsor  final_net_pmargin, gen(final_npm) p(0.01)
replace final_npm = -1 if final_npm < -1
replace final_npm = 1 if final_npm > 1
drop final_net_pmargin
*/
g final_econ_pmargin        = (cit_total_inc - cit_total_costs) / cit_total_inc 
replace final_econ_pmargin  = 0 if missing(final_econ_pmargin)
winsor  final_econ_pmargin, gen(final_epm) p(0.01)
replace final_epm = -1 if final_epm < -1
replace final_epm = 1 if final_epm > 1
drop final_econ_pmargin
/*
g final_roa_pmargin       = (cit_turnover - cit_deductions) / cit_total_assets
replace final_roa_pmargin = 0 if missing(final_roa_pmargin)
winsor  final_roa_pmargin, gen(final_roa) p(0.01)
replace final_roa = -1 if final_roa < -1
replace final_roa = 1 if final_roa > 1
drop final_roa_pmargin

g final_roce_pmargin       = (cit_turnover - cit_deductions) / final_net_fixed_assets
replace final_roce_pmargin = 0 if missing(final_roce_pmargin)
winsor  final_roce_pmargin, gen(final_roce) p(0.01)
replace final_roce = -1 if final_roce < -1
replace final_roce = 1 if final_roce > 1
drop final_roce_pmargin
*/
g final_expenses_assets = cit_total_costs / cit_total_assets
replace final_expenses_assets = 0 if missing(final_expenses_assets)
winsor  final_expenses_assets, gen(final_eta) p(0.07)
drop final_expenses_assets

g final_financial_sales = final_financial_costs / final_total_sales
replace final_financial_sales = 0 if missing(final_financial_sales)
winsor final_financial_sales, gen(final_gfsal) p(0.01)
drop final_financial_sales

g final_turnover1 = final_total_sales / cit_current_assets
replace final_turnover1 = 0 if missing(final_turnover1)
winsor final_turnover1, gen(final_turnover) p(0.01)
drop final_turnover1

g final_liquidity1 = cit_current_assets / cit_current_liabilities
replace final_liquidity1 = 0 if missing(final_liquidity1)
winsor final_liquidity1, gen(final_liquidity) p(0.01)
drop final_liquidity1


* Estimation of Total Factor Productivity at the firm level by industry employing 
* the method developed by Ackerberg et al. (2015). Variables most to be renamed 
* before using the acfest command. 
xtset id year
g y  = final_log_sales
g va = final_log_value_added
g k  = final_log_total_assets
g a  = final_log_age
g l  = final_log_employment
g m  = final_log_input_costs

g final_log_productivity_y  = 0
g final_log_productivity_va = 0

eststo drop *
forv val = 1/3 {
	preserve
	keep if final_industry == `val'
	keep id year y va k a m l 
	eststo model_s_`val': qui acfest y, state(k a) proxy(m) free(l) nbs(200)
	predict tfp_y_`val', omega
	eststo model_va_`val': qui acfest va, state(k a) proxy(m) free(l) nbs(200) va
	predict tfp_va_`val', omega
	tempfile tfp_`val'
	save `tfp_`val'', replace
	restore
	
	merge m:1 id year using `tfp_`val'', keepusing(tfp_y_`val' tfp_va_`val')
	replace final_log_productivity_y  = tfp_y_`val'  if final_industry == `val'
	replace final_log_productivity_va = tfp_va_`val' if final_industry == `val'
	drop _merge tfp_y_`val' tfp_va_`val' 
	capture drop `tfp_`val''
}
drop y va k a l m

* Table A3 for online Appendix
esttab model_s_* using "$out\tfp_estimates.tex", booktabs f replace 			///
	   mtitles("Primary Sector" "Manufacturing" "Services") keep(k l)			///
	   coeflabels(k "Capital" a "Age" l "Labor" m "Input costs") order(k l a m)	///
	   scalars("N Observations" "waldcrs Wald test" "j Sargan-Hansen test")     ///
	   sfmt(%9.3fc) se(2) star staraux nonumbers b(a3)	

esttab model_va_* using "$out\tfp_estimates.tex", booktabs f append   			///
	   mtitles("Primary Sector" "Manufacturing" "Services") keep(k l)			///
	   coeflabels(k "Capital" l "Labor") order(k l a)					   		///
	   scalars("N Observations" "waldcrs Wald test" "j Sargan-Hansen test")     ///
	   sfmt(%9.3fc) se(2) star staraux nonumbers b(a3)	   

* Defining labels for all variables
order id, first
label var final_mnc  				   "Multinational (MNC)"
*label var final_gpm   				   "Gross profit margin (GPM)"
*label var final_npm 				   "Net profit margin (NPM)"
label var final_epm 				   "Economic profit margin (EPM)"
*label var final_roa 				   "Return on assets (ROA)"
*label var final_roce 				   "Return on capital employed (ROCE)" 
label var final_eta 		           "Expenses to total assets (ETA)"
label var final_gfsal 	               "Gross financial costs to sales (GFSAL)"
label var final_turnover 			   "Turnover"
label var final_liquidity 			   "Liquidity"
label var final_age 				   "Age (years)"
label var final_log_age 			   "Age (logs)" 
label var final_log_employment 		   "Employment (logs)"
label var ihss_workers			   	   "Employment (\# workers)"
label var final_input_costs 		   "Input costs (Lempiras 1M)"
label var final_log_input_costs 	   "Input costs (logs)" 
label var final_financial_costs 	   "Financial costs (Lempiras 1M)"
label var final_log_financial_costs    "Financial costs (logs)"
label var final_capital_int 		   "Capital intensity"
label var final_labor_int 			   "Labor intensity" 
label var final_export_share 		   "Export share"
label var final_import_share 		   "Import share"
label var final_log_sales			   "Sales (logs)"
label var cit_total_assets             "Total assets (Lempiras 1M)"
label var final_log_total_assets	   "Total assets (logs)"
label var final_log_net_fixed_assets   "Net fixed assets (logs)"
label var cit_fixed_assets			   "Fixed assets (Lempiras 1M)"
label var final_log_productivity_y     "TFP on sales (logs)"
label var final_log_productivity_va    "TFP on value added (logs)"
label var final_log_labor_productivity "Labor productivity (logs)"
label var final_log_value_added		   "Value added (logs)"
label var final_salary 				   "Salary"
label var final_log_salary			   "Salary (logs)"
label var final_log_credits			   "Tax credits (logs)"
label var cit_exonerated 			   "Exonerated"
