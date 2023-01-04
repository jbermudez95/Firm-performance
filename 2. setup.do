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
if "`c(username)'" == "Jose Carlo Bermúdez" {
	global path "C:\Users\bermu\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out "C:\Users\bermu\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"	
}
else if "`c(username)'" == "jbermudez" {
	global path "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"		
	global out "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\out"
} 


*************************************************************************
*******                           SET UP                          ******* 
*************************************************************************

use "$path\final_dataset1.dta", replace

* Drop firms in the financial sector, real state, education, public administration, diplomatics or without economic activity. 
* Drop cooperatives, non-profit organizations, public-private partnerships, and simplified regimes.
* Drop firms with only one employee or zero values from social security records.
drop if (codigoseccion == "K" | codigoseccion == "L" | codigoseccion == "O" | codigoseccion == "P" | codigoseccion == "U" | codigoseccion == "Z")    
drop if (cit_regime == 8 | cit_regime == 15 | cit_regime == 20 | cit_regime == 27) 		       
drop if (ihss_workers == 1 | missing(ihss_workers))


* Categories for the different special fiscal regimes (according to the number code in the CIT form). 
* We reclassify firms advocated to the Tourism Incentives Law to the LIT regime.
replace cit_regime = 0 if cit_regime == 6
replace cit_regime = 5 if cit_regime == 13
replace cit_regime = 9 if cit_regime == 21
replace cit_regime = 1 if cit_regime == 14
label def cit_regime 0 "None" 1 "ZADE" 2 "ZOLI" 3 "ZOLT" 4 "RIT" 5 "Other regimes" ///	
				     7 "ZOLITUR" 9 "LIT" 23 "Renewable energy", replace
label val cit_regime cit_regime

gen final_none = cond(cit_regime == 0, 1, 0)
labe var final_none "Taxed firms"	

gen final_zade = cond(cit_regime == 1, 1, 0)
labe var final_zade "Exempt firms: ZADE"

gen final_zoli = cond(cit_regime == 2, 1, 0)
labe var final_zoli "Exempt firms: ZOLI"

gen final_zolt = cond(cit_regime == 3, 1, 0)
labe var final_zolt "Exempt firms: ZOLT"

gen final_rit = cond(cit_regime == 4, 1, 0)
labe var final_rit "Exempt firms: RIT"

gen final_others = cond(cit_regime == 5, 1, 0)
labe var final_others "Exempt firms: Other regimes"

gen final_zolitur = cond(cit_regime == 7, 1, 0)
labe var final_zolitur "Exempt firms: ZOLITUR"

gen final_lit = cond(cit_regime == 9, 1, 0)
labe var final_lit "Exempt firms: LIT"

gen final_energy = cond(cit_regime == 23, 1, 0)
labe var final_energy "Exempt firms: Renewable energy"


* Dummy identifying the type of tax exemption
g 		final_regime = 0
replace	final_regime = 1 if inlist(cit_regime, 1, 2, 4)
replace final_regime = 2 if inlist(cit_regime, 3, 5, 7, 9, 23)
label def final_regime 0 "Taxed" 1 "Export Oriented" 2 "Non-Export Oriented"
label val final_regime final_regime

gen exempt_export     = cond(final_regime == 1, 1, 0)
replace exempt_export = cond(final_regime == 2, ., exempt_export)
label var exempt_export "Export oriented"

gen exempt_non_export     = cond(final_regime == 2, 1, 0)
replace exempt_non_export = cond(final_regime == 1, ., exempt_non_export)
label var exempt_non_export "Non-Export oriented"


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
						4 "Automotive" 5 "Wholesale and retail" 6 "Transportation, housing and tourism" 7 "Comunications and technology" ///
						8 "Professional and technical services" 9 "Health and arts" 10 "Other services", replace
lab val activity_sector activity_sector
	
gen final_industry = cond(activity_sector == 1, 1, cond(activity_sector == 2 | activity_sector ==  3, 2, ///
					 cond(activity_sector != 1 | activity_sector != 2 | activity_sector != 3, 3, .)))
label def final_industry 1 "Primary: Agricultural, extraction" 2 "Secondary: Industry" 3 "Tertiary: Services"
label val final_industry final_industry

gen final_primary = cond(final_industry == 1, 1, 0)
label var final_primary "Primary: Agricultural, extraction"

gen final_secondary = cond(final_industry == 2, 1, 0)
label var final_secondary "Secondary: Industry"

gen final_tertiary = cond(final_industry == 3, 1, 0)
label var final_tertiary "Tertiary: Services"


* Firms size
label def tamaño_ot 1 "Large taxpayer" 2 "Medium taxpayer" 3 "Small taxpayer", replace
label val tamaño_ot tamaño_ot

gen size_small  = cond(tamaño_ot == 3, 1, 0)
label var size_small "Small sized firms"

gen size_medium = cond(tamaño_ot == 2, 1, 0)
label var size_medium "Medium sized firms"

gen size_large  = cond(tamaño_ot == 1, 1, 0)
label var size_large "Large sized firms"


* Trade position
gen trader = cond(!missing(final_exports) | !missing(final_imports), 1, 0)
lab def trader 0 "Non Trader" 1 "Foreign trade activity"

gen exporter = cond(!missing(final_exports), 1, 0)
replace exporter = cond(exempt_non_export == 1, 0, exporter)
label var exporter "Exporter"

gen non_exporter = cond(missing(final_exports), 1, 0)
replace non_exporter = cond(exempt_export == 1, ., non_exporter)
label var non_exporter "Non-exporter"


* Minor settings
encode municipio, gen(municipality)
egen x = group(id)
drop id
rename x id
order id, first

gen urban = cond(municipio == "SAN PEDRO SULA" | municipio == "DISTRITO CENTRAL", 1, 0)
lab def urban 0 "Not main urban" 1 "Main urban cities"


* Income percentiles
preserve
keep if !missing(cit_gross_income)
egen percentil = xtile(cit_gross_income), by(year) p(1(1)99)	
egen decil     = xtile(cit_gross_income), by(year) p(1(1)10)	 
tempfile perct
save `perct'
restore
merge 1:1 id year using `perct'
drop _merge



*************************************************************************
*******               BUILDING VARIABLES OF INTEREST              ******* 
*************************************************************************

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
						cit_total_credits_as cit_cre_exo cit_cre_withholding cit_cre_pay cit_cre_surplus 		///
						cit_cre_assignments cit_cre_compensation cit_cre_employment cit_cre_isran 			    ///
						vat_sales_exempted vat_sales_taxed vat_sales_exports vat_sales_local vat_purch_exempted ///
						vat_purch_taxed vat_purch_imports vat_purch_local custom_import custom_export    		///
						final_sales_local final_exports final_imports final_total_sales final_total_purch cit_tax_liability dividends_value {
								replace `var' = `var' / `mill' if !missing(`var')
								replace `var' = 0 if (`var' < 0 & !missing(`var'))
								replace `var' = ((`var' / `ipc2017') * 100) if year == 2017 & !missing(`var')
								replace `var' = ((`var' / `ipc2018') * 100) if year == 2018 & !missing(`var')	
								replace `var' = cond(missing(`var'), 0, `var')
	}

* Constructing variables for descriptive statistics and empirical estimations. 
g final_credits				 = cit_total_credits_r + cit_total_credits_an + cit_total_credits_as
g final_input_costs     	 = cit_goods_materials_non_ded + cit_goods_materials_ded
g final_financial_costs 	 = cit_financial_ded + cit_financial_non_ded
g final_fixed_assets     	 = cit_fixed_assets - cit_fixed_assets_depr
g final_total_labor_costs    = cit_labor_ded + cit_labor_non_ded
g final_net_labor_costs 	 = cit_labor_ded - cit_labor_non_ded
g final_value_added    		 = final_total_sales - final_input_costs
g final_salary               = final_total_labor_costs / ihss_workers
g final_labor_productivity   = final_total_sales / ihss_workers

g final_age        = year - date_start
replace final_age  = 1 if final_age <= 0

local v "credits age total_sales fixed_assets value_added salary input_costs financial_costs"
foreach k of local v {
	g final_log_`k' = log(1 + final_`k')
}

g final_log_total_assets		 = log(1 + cit_total_assets)
g final_log_employment   		 = log(ihss_workers)
g final_log_labor_productivity   = log(final_labor_productivity)
g final_log_credits_exo			 = log(1 + cit_cre_exo)
g final_log_dividends_value		 = log(1 + dividends_value)
g final_log_dividends_relations  = log(dividends_relations)

g final_export_share = final_exports / final_total_sales
g final_import_share = final_imports / final_total_purch

g final_capital_inte = final_fixed_assets / final_total_sales
winsor final_capital_inte if !missing(final_capital_inte), gen(final_capital_int) p(0.07)
drop final_capital_inte

g final_labor_inte = final_net_labor_costs / final_total_sales		
winsor final_labor_inte if !missing(final_labor_inte), gen(final_labor_int) p(0.01)
drop final_labor_inte

g final_gross_pmargin     = (final_total_sales - final_input_costs) / final_total_sales
replace final_gross_pmargin = 0 if missing(final_gross_pmargin)
winsor  final_gross_pmargin, gen(final_gpm) p(0.01)
replace final_gpm = -1 if final_gpm < -1
replace final_gpm = 1 if final_gpm > 1
drop final_gross_pmargin

g final_roa_pmargin       = (cit_total_inc - cit_total_costs) / cit_total_assets
replace final_roa_pmargin  = 0 if missing(final_roa_pmargin) | final_roa_pmargin < 0
winsor  final_roa_pmargin, gen(final_roa) p(0.01)
drop final_roa_pmargin

g final_roce_pmargin       = (cit_gross_income - cit_deductions) / final_fixed_assets
replace final_roce_pmargin  = 0 if missing(final_roce_pmargin) | final_roce_pmargin < 0
winsor  final_roce_pmargin, gen(final_roce) p(0.01)
replace final_roce = -1 if final_roce < -1
replace final_roce = 1 if final_roce > 1
drop final_roce_pmargin

g final_econ_pmargin        = (cit_total_inc - cit_total_costs) / cit_total_inc 
replace final_econ_pmargin  = 0 if missing(final_econ_pmargin) | final_econ_pmargin < 0
winsor  final_econ_pmargin, gen(final_epm) p(0.01)
drop final_econ_pmargin

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


* TFP estimation at the firm level.
set seed 123 
xtset id year

g y  = final_log_total_sales
g va = final_log_value_added
g k  = final_log_total_assets
g l  = final_log_employment
g m  = final_log_input_costs

eststo drop *
local output y va
foreach var of local output {
	if "`var'" == "y" {
	eststo model_LP_`var':  qui prodest `var', free(l) state(k) proxy(m) met(lp) opt(dfp) reps(100) id(id) t(year) fsresidual(tfp_`var'_LP) 
	eststo model_ACF_`var': qui prodest `var', free(l) state(k) proxy(m) met(lp) opt(dfp) reps(100) id(id) t(year) acf fsresidual(tfp_`var'_ACF)
	}
	else if "`var'" == "va" {
	eststo model_LP_`var':  qui prodest `var', free(l) state(k) proxy(m) met(lp) opt(dfp) reps(100) id(id) t(year) valueadded fsresidual(tfp_`var'_LP) 
	eststo model_ACF_`var': qui prodest `var', free(l) state(k) proxy(m) met(lp) opt(dfp) reps(100) id(id) t(year) valueadded acf fsresidual(tfp_`var'_ACF)
	}
}

drop y va k l m

* Table A3 for online Appendix
esttab model_LP_* model_ACF_* using "$out\tfp_estimatesv2", replace keep(k l)  ///
	   mgroups("\cite{levinsohn03} Method" "\cite{ackerberg15} Method", ///
	   span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 1 0) erepeat(\cmidrule(lr){@span})) ///
	   mtitles("Sales" "Value-Added" "Sales" "Value-Added") ///
	   coeflabels(k "Capital stock" l "Labor") order(k l)	///
	   scalars("N Observations" "waldP Wald test") sfmt(%9.0fc %9.3fc) ///
	   se(2) b(3) star nonumbers booktabs
eststo drop *


* Defining labels for all variables
order id, first
label var final_mnc  				    "Multinational (MNC)"
label var final_gpm   				    "Gross profit margin (GPM)"
label var final_epm 				    "Economic profit margin (EPM)"
label var final_roa 				    "Return on assets (ROA)"
label var final_roce 				    "Return on capital employed (ROCE)" 
label var final_eta 		            "Expenses to total assets (ETA)"
label var final_gfsal 	                "Gross financial costs to sales (GFSAL)"
label var final_turnover 			    "Turnover"
label var final_liquidity 			    "Liquidity"
label var final_age 				    "Age (years)"
label var final_log_age 			    "Age (logs)" 
label var final_log_employment 		    "Employment (logs)"
label var ihss_workers			   	    "Employment (\# workers)"
label var final_input_costs 		    "Input costs (Lempiras 1M)"
label var final_log_input_costs 	    "Input costs (logs)" 
label var final_financial_costs 	    "Financial costs (Lempiras 1M)"
label var final_log_financial_costs     "Financial costs (logs)"
label var final_capital_int 		    "Capital intensity"
label var final_labor_int 			    "Labor intensity" 
label var final_export_share 		    "Export share"
label var final_import_share 		    "Import share"
label var final_log_total_sales		    "Sales (logs)"
label var cit_total_assets              "Total assets (Lempiras 1M)"
label var final_log_total_assets	    "Total assets (logs)"
label var final_log_fixed_assets   	    "Net fixed assets (logs)"
label var cit_fixed_assets			    "Fixed assets (Lempiras 1M)"
label var cit_total_taxed_inc 		    "Taxable income (Lempiras 1M)"
label var cit_total_exempt_inc 		    "Non-taxable income (Lempiras 1M)"
label var cit_total_costs_ded 		    "Deductible costs (Lempiras 1M)"
label var cit_total_costs_non_ded 	    "Non-deductible costs (Lempiras 1M)"
label var vat_sales_exempted 		    "Exempt sales (Lempiras 1M)"
label var vat_sales_taxed			    "Taxed sales (Lempiras 1M)"
label var vat_purch_exempted 		    "Exempt purchases (Lempiras 1M)"
label var vat_purch_taxed			    "Taxed purchases (Lempiras 1M)"
label var vat_filler				    "Filling VAT"
label var tfp_y_LP     				    "TFP on sales (logs), LP method"
label var tfp_va_LP    				    "TFP on value added (logs), LP method"
label var tfp_y_ACF     			    "TFP on sales (logs), ACF method"
label var tfp_va_ACF    			    "TFP on value added (logs), ACF method"
label var final_log_labor_productivity  "Labor productivity (logs)"
label var final_log_value_added		    "Value added (logs)"
label var final_salary 				    "Salary"
label var final_log_salary			    "Salary (logs)"
label var final_log_credits			    "Tax credits (logs)"
label var cit_exonerated 			    "Exonerated"
label var legal_proxy 				    "Lobbying ability"
label var urban 					    "Main urban cities"
label var legal_attorneys 			    "Lobbying ability"
label var legal_proxy				    "Lobbying ability"
label var ever_audited_times 		    "Number of times audited"
label var ever_audited				    "Audited at least once"
label var percentil					    "Percentile on gross income"
label var decil 					    "Decil on gross income"
label var dividends_relations		    "Number of shareholders"
label var final_log_dividends_relations "Number of shareholders (logs)"
label var dividends_value			    "Payment of dividends"
label var final_log_dividends_value	    "Payment of dividends (logs)"


