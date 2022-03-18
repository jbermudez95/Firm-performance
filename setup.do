/*
Name:			setup.do
Description: 	This do file uses the panel data "final_dataset" built from data_prep.do 
				and generates the variables that are later used for the paper "Firm performance 
				and tax incentives: evidence from Honduras". It also generates table A3
				for TFP estimations that are inlcuded in the online appendix of the paper.
Date:			November, 2021
Modified:		November, 2021
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
global path "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\database and codes"		// cambiar directorio
global out "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\out"						// cambiar directorio

/* Paquetes necesarios para las estimaciones
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

* Drop firms without economic activity. Drop cooperatives, non-profit org and simplified regimes.
* Drop firms without income (or turnover) or costs. Drop firms with only one employee
use "$path\final_dataset.dta"
keep if (cit_form == "352" | cit_form == "357")
encode municipio, gen(province)
drop if codigoseccion == "Z"     						         
keep if (codigoseccion == "A" | codigoseccion == "B" | codigoseccion == "C" | ///
		 codigoseccion == "D" | codigoseccion == "G" | codigoseccion == "I" )
drop if (cit_regime == 8| cit_regime == 15 | cit_regime == 27) 
drop if (cit_total_inc == 0 | cit_total_costs == 0)		       
drop if max(cit_total_sales, sales_total) == 0			       
drop if ihss_n_workers == 1
egen x = group(id)
drop id
rename x id

* Categories for the different special fiscal regimes (according to the number code in the CIT form). 
* We reclassify firms advocated to the Tourism Incentives Law to the LIT regime.
replace cit_regime = 5 if cit_regime == 13
replace cit_regime = 9 if cit_regime == 21
replace cit_regime = 5 if (cit_exonerated == 1 & cit_regime == 0)
label def cit_regime 0 "None" 1 "ZIP" 2 "ZOLI" 3 "ZOLT" 4 "RIT" 5 "Others" 7 "ZOLITUR" ///
					 9 "LIT" 14 "ZADE" 23 "Renewable Energy"
label val cit_regime cit_regime		

* Dummy identifying the type of tax exemption
g 		final_regime = 0
replace	final_regime = 1 if (cit_regime == 1 | cit_regime == 2 | cit_regime == 4 | cit_regime == 14)
replace final_regime = 2 if (cit_regime == 3 | cit_regime == 5 | cit_regime == 7 | cit_regime == 9 | cit_regime == 23)
label def final_regime 0 "Taxed" 1 "Export Oriented" 2 "Non-Export Oriented"
label val final_regime final_regime

* Generate economic categories 
gen     final_industry = 1 if (codigoseccion == "A")
replace final_industry = 2 if (codigoseccion == "B" | codigoseccion == "C" | codigoseccion == "D")
replace final_industry = 3 if (codigoseccion == "G" | codigoseccion == "I")
label def final_industry 1 "Primary" 2 "Manufacturing" 3 "Services"
label val final_industry final_industry

* Firm size classification following the WBES
g final_firm_size = 0
replace final_firm_size = 1 if ihss_n_workers < 20
replace final_firm_size = 2 if ihss_n_workers >= 20 & ihss_n_workers < 100
replace final_firm_size = 3 if ihss_n_workers >= 100
label def final_firm_size 1 "Small" 2 "Medium" 3 "Large"
label val final_firm_size final_firm_size

*************************************************************************
*******               BUILDING VARIABLES OF INTEREST              ******* 
*************************************************************************

* Constructing variables for descriptive statistics and empirical estimations. 
* Variables are adjusted for inflation using 2010 = 100, and presented in millions of Lempiras.
loc mill = 1000000
loc ipc2017 = 138.0563124
loc ipc2018 = 144.0660006
foreach var of varlist cit_current_assets cit_fixed_assets cit_total_assets cit_turnover           						  ///
					   cit_deductions cit_fixed_assets_depr cit_turnover_exempt cit_turnover_taxed 					      ///
					   cit_other_inc_taxed cit_other_inc_exempt cit_total_exempt_inc cit_total_taxed_inc 				  ///
					   cit_total_inc cit_total_sales cit_dif_ingresos cit_result_income cit_dif_result_income 			  ///
					   cit_goods_materials_non_ded cit_com_costs cit_prod_costs cit_goods_materials_ded 				  ///
					   cit_labor_non_ded cit_labor_ded cit_financial_non_ded cit_financial_ded cit_operations_non_ded 	  ///
					   cit_operations_ded cit_losses_other_non_ded cit_losses_other_ded cit_precio_trans_ded       		  ///
					   cit_total_costs_ded cit_total_costs_non_ded cit_total_costs cit_caused_tax cit_total_credits_r     ///
					   cit_total_credits_an cit_total_credits_as sales_exempted sales_taxed sales_exmp_purch sales_fyduca ///
					   sales_exports sales_imports sales_total sales_purch custom_import custom_export 					  ///
					   cit_current_liabilities cit_total_credits_r cit_total_credits_an cit_total_credits_as {
							replace `var' = `var' / `mill'
							replace `var' = 0 if `var' < 0
							replace `var' = ((`var' / `ipc2017') * 100) if year == 2017
							replace `var' = ((`var' / `ipc2018') * 100) if year == 2018
							replace `var' = 0 if missing(`var')									 
}

g final_sales       		 = max(cit_total_sales, sales_total)
g final_exports     		 = max(sales_exports, custom_export)
g final_imports     		 = max(sales_imports, custom_import)
g final_input_costs     	 = cit_goods_materials_non_ded + cit_goods_materials_ded
g final_financial_costs 	 = cit_financial_ded + cit_financial_non_ded
g final_fixed_assets    	 = cit_fixed_assets - cit_fixed_assets_depr
g final_net_labor_costs 	 = cit_labor_ded - cit_labor_non_ded
g final_value_added    		 = final_sales - final_input_costs
g final_labor_productivity   = final_sales / ihss_n_workers

g final_age        = year - date_start
replace final_age  = 1 if final_age <= 0

g final_log_age					 = log(final_age)
g final_log_sales				 = log(1 + final_sales)
g final_log_input_costs 		 = log(1 + final_input_costs)
g final_log_financial_costs 	 = log(1 + final_financial_costs)
g final_log_firm_size   		 = log(ihss_n_workers)
g final_log_total_assets		 = log(1 + cit_total_assets)
g final_log_fixed_assets		 = log(1 + final_fixed_assets)
g final_log_value_added     	 = log(1 + final_value_added)
g final_log_labor_productivity   = log(final_labor_productivity)

replace final_sales = final_exports if (final_sales == 0 & final_exports > 0)
g final_export_share        = final_exports / final_sales
replace final_export_share  = 1 if final_export_share > 1

replace sales_purch = final_imports if (sales_purch == 0 & final_imports > 0)
g final_import_share		= final_imports / sales_purch
replace final_import_share  = 1 if final_import_share > 1

g final_capital_inte = final_fixed_assets / final_sales
winsor final_capital_inte, gen(final_capital_int) p(0.07)
drop final_capital_inte

g final_labor_inte = final_net_labor_costs / final_sales		
winsor final_labor_inte, gen(final_labor_int) p(0.01)
drop final_labor_inte

g final_gross_pmargin       = (final_sales - final_input_costs) / final_sales
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

g final_econ_pmargin        = (cit_total_inc - cit_total_costs) / cit_total_inc 
replace final_econ_pmargin  = 0 if missing(final_econ_pmargin)
winsor  final_econ_pmargin, gen(final_epm) p(0.01)
replace final_epm = -1 if final_epm < -1
replace final_epm = 1 if final_epm > 1
drop final_econ_pmargin

g final_roa_pmargin       = (cit_turnover - cit_deductions) / cit_total_assets
replace final_roa_pmargin = 0 if missing(final_roa_pmargin)
winsor  final_roa_pmargin, gen(final_roa) p(0.01)
replace final_roa = -1 if final_roa < -1
replace final_roa = 1 if final_roa > 1
drop final_roa_pmargin

g final_roce_pmargin       = (cit_turnover - cit_deductions) / final_fixed_assets
replace final_roce_pmargin = 0 if missing(final_roce_pmargin)
winsor  final_roce_pmargin, gen(final_roce) p(0.01)
replace final_roce = -1 if final_roce < -1
replace final_roce = 1 if final_roce > 1
drop final_roce_pmargin

g final_expenses_assets = cit_total_costs / cit_total_assets
replace final_expenses_assets = 0 if missing(final_expenses_assets)
winsor  final_expenses_assets, gen(final_eta) p(0.07)
drop final_expenses_assets

g final_financial_sales = final_financial_costs / final_sales
replace final_financial_sales = 0 if missing(final_financial_sales)
winsor final_financial_sales, gen(final_gfsal) p(0.01)
drop final_financial_sales

g final_turnover1 = final_sales / cit_current_assets
replace final_turnover1 = 0 if missing(final_turnover1)
winsor final_turnover1, gen(final_turnover) p(0.01)
drop final_turnover1

g final_liquidity1 = cit_current_assets / cit_current_liabilities
replace final_liquidity1 = 0 if missing(final_liquidity1)
winsor final_liquidity1, gen(final_liquidity) p(0.01)
drop final_liquidity1

g final_log_gpm             = log(1 + final_gpm)
g final_log_npm             = log(1 + final_npm)
g final_ihs_gpm             = asinh(final_gpm)
g final_ihs_npm             = asinh(final_npm)

* Estimation of Total Factor Productivity at the firm level by industry employing 
* the method developed by Ackerberg et al. (2015). Variables most to be renamed 
* before using the acfest command. 
xtset id year
g y  = final_log_sales
g va = final_log_value_added
g k  = final_log_total_assets
g a  = final_log_age
g l  = final_log_firm_size
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
}
drop y va k a l m
qui sum final_log_productivity_va
replace final_log_productivity_va = r(mean) if final_log_productivity_va ==.

* Table A3 for online Appendix
esttab model_s_1 model_s_2 model_s_3 using "$out\tfp_estimates.tex", booktabs f replace ///
	   mtitles("Primary Sector" "Manufacturing" "Services") 					        ///
	   coeflabels(k "Capital" a "Age" l "Labor" m "Input costs") order(k l a m)			///
	   scalars("N Observations" "waldcrs Wald test" "j Sargan-Hansen test")             ///
	   sfmt(%9.3fc) se(2) star staraux nonumbers b(a3)	

esttab model_va_1 model_va_2 model_va_3 using "$out\tfp_estimates.tex", booktabs f append   ///
	   mtitles("Primary Sector" "Manufacturing" "Services") 					    ///
	   coeflabels(k "Capital" a "Age" l "Labor") order(k l a)					    ///
	   scalars("N Observations" "waldcrs Wald test" "j Sargan-Hansen test")         ///
	   sfmt(%9.3fc) se(2) star staraux nonumbers b(a3)	

* Defining labels for all variables
label var final_gpm   				   "GPM"
label var final_npm 				   "NPM"
label var final_epm 				   "EPM"
label var final_roa 				   "ROA"
label var final_roce 				   "ROCE" 
label var final_eta 		           "ETA"
label var final_gfsal 	               "GFSAL"
label var final_turnover 			   "Turnover"
label var final_liquidity 			   "Liquidity"
label var final_age 				   "Age"
label var final_log_age 			   "Age" 
label var final_firm_size 			   "Firm size"
label var final_log_firm_size 		   "Firm size"
label var ihss_n_workers			   "Firm size"
label var final_input_costs 		   "Input costs"
label var final_log_input_costs 	   "Input costs" 
label var final_financial_costs 	   "Financial costs"
label var final_log_financial_costs    "Financial costs"
label var final_capital_int 		   "Capital intensity"
label var final_labor_int 			   "Labor intensity" 
label var final_export_share 		   "Export share"
label var final_import_share 		   "Import share"
label var final_log_sales			   "Sales"
label var final_log_total_assets	   "Total assets"
label var final_log_fixed_assets	   "Fixed assets"
label var final_log_productivity_y     "TFP on sales"
label var final_log_productivity_va    "TFP on value added"
label var final_log_labor_productivity "Labor productivity"
label var final_log_gpm                "Log(GPM)"
label var final_log_npm                "Log(NPM)"
label var final_ihs_gpm                "IHS(GPM)"
label var final_ihs_npm                "IHS(NPM)"
