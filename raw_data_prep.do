/*
Name:			raw_data_prep.do
Description: 	This do file cleans and prepares administrative datasets that are 
				use for the descriptive and empirical estimations of the paper 
				"Firm performance and tax incentives: evidence from Honduras". 
				It produces three individual datasets (tax, custom, 
				and social security records) which are merged later to build an 
				unbalanced panel dataset. 
Date:			July 3rd, 2021
Modified:       April, 2022
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
set more off

*Set up directories
global path  "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\preparacion inicial\base profit margins"
global input "C:\Users\jbermudez\OneDrive - SAR\Bases del repositorio"
global out	 "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\database and codes"

**********************************************************************************
********      FIRST PART: SETTING UP CORPORATE AND SALES TAX RECORDS      ********
**********************************************************************************

**------------- 1.1 AUXILIAR DATASET TO IDENTIFY EXONERATED FIRMS -------------
preserve
use "$path\Base exonerados anual\exonerados2017.dta", replace
append using "$path\Base exonerados anual\exonerados2018.dta"

encode beneficio1, gen(beneficio)
drop beneficio1

keep if (beneficio == 1 | beneficio == 2 | beneficio == 3 | beneficio == 5 | beneficio == 6 | beneficio == 10)
g regimen = 1

tempfile regimen
save "`regimen'"
restore

**------------- 1.2 CORPORATE TAX RECORDS -------------
preserve
use "$input\Base_ISRPJ_2014_2020_0821.dta", clear
compress 

keep if year == 2017 | year == 2018
sort rtn year
duplicates drop rtn year, force

* Keeping only electronic tax forms
format %13.0f nro_preimpreso
tostring nro_preimpreso, gen(form) usedisplayformat
replace form = (substr(form, 1, 3))

* Income variables
egen cit_turnover_exempt  = rowtotal(ingr_vtas_grav_12_art22 ingr_vtas_grav_15_art22 ingr_vtas_grav_18_art22 ///
								     ingr_vtas_serv_expor_art22 ingr_vtas_servicios_exe_art22 ingr_vtas_serv_fyduca_art22), missing
									 
egen cit_turnover_taxed   =  rowtotal(ingr_vtas_grav_12 ingr_vtas_grav_15 ingr_vtas_grav_18 ///
							          ingr_vtas_serv_expor ingr_vtas_servicios_exe ingr_vtas_serv_fyduca), missing
									  
egen cit_other_inc_taxed  = rowtotal(ingr_int_no_bancarios_v ingr_alq_exe_isv ingr_por_intereses ///
								     ingr_por_comisiones ingr_prov_exterior ingr_otra_renta_grav ///
									 ingrajustespreciostransf ingr_por_donac_locales), missing
									 
egen cit_other_inc_exempt = rowtotal(ingr_int_no_bancarios_art22 ingr_alq_exe_isv_art22 							  ///
									 ingr_por_intereses_art22 ingr_por_comisiones_art22 ingr_por_donaciones_ext_art22 ///
								     ingr_intereses_banc_art22 ingr_ganancias_capital_art22 ingr_seguros_art22        ///
								     ingr_dividendos_art22 ingr_bienes_herencia_art22 ingr_renta_titulos_art22        ///
								     ingr_subversiones_art22 ingr_premios_loteria_art22 ingr_loteria_electr_art22 	  ///
								     ingr_otra_rentas_no_grav_art22 ingr_prov_exterior_art22 ingr_ganan_mediciones_art22 ingr_por_donac_locales_art22), missing

g cit_total_exempt_inc = cit_turnover_exempt + cit_other_inc_exempt
g cit_total_taxed_inc  = cit_turnover_taxed  + cit_other_inc_taxed
g cit_total_inc        = cit_total_taxed_inc + cit_total_exempt_inc
g cit_total_sales	   = cit_turnover_exempt + cit_turnover_taxed

g cit_dif_ingresos      = abs(cit_total_inc - ingr_total_ingresos_total)
g cit_result_income     = cit_total_inc     - ct_ingresos_no_gravados
g cit_dif_result_income = cit_result_income - total_ingresos_resul_ejercicio

* Costs and expenses
g cit_goods_materials_non_ded = cyg_gastos_compra_vnd

g    cit_com_costs               = cyginvinicialbienesc + cygcomprasbrutaslocalc + cygcomprasimportbienesc - cygdescdevcomprasc - cyginvfinalbienesc

g    cit_prod_costs 			 = cyginvinicialmatprimac + cygcomprasnetasmatprimac + cygimportacionmatprimac - cyginvfinalmatprimac + cyggastosindirfabrc + /// 		  		
								   cyginvinicialprodprocc - cyginvfinalprodprocc + cyginvinicialprodtermc - cyginvfinalprodtermc
								   
g 	 cit_goods_materials_ded 	 = cit_com_costs + cit_prod_costs 

replace cit_goods_materials_ded  = cit_goods_materials_ded + cyg_gastos_compra_c + cyg_gastos_compra_g 

egen cit_labor_non_ded           = rowtotal(cyg_cyg_gastos_com_vtas_vnd cygsueldossalariosvnd cyg_honorarios_prof_vnd cyg_honorarios_extranj_vnd), missing

egen cit_labor_ded               = rowtotal(cygmanoobradirc cygmanoobraindirc cyg_gastos_com_vtas_c cygsueldossalariosc cyg_honorarios_prof_c cyg_honorarios_extranj_c ///
											cyg_gastos_com_vtas_g cygsueldossalariosg cyg_honorarios_prof_g cyg_cyg_honorarios_extranj_g), missing
											
egen cit_financial_non_ded 		 = rowtotal(cyg_inter_banc_local_vnd cyg_inter_banc_exterior_vnd cyg_inter_pag_ter_local_vnd /// 
										    cyg_inter_pag_ter_ext_er_vnd cyg_inter_pag_ter_localenr_vnd cyg_inter_pag_ter_ext_enr_vnd), missing

egen cit_financial_ded           = rowtotal(intereses_banc_local intereses_banc_exterior intereses_terc_local_er intereses_terc_exterior_er   ///
											intereses_terc_local_enr intereses_terc_exterior_enr local_int_bancarios_int delext_bancarios_int ///
											local_empresas_rel_int delext_empresas_rel_int local_empresas_no_rel_int delext_empresas_norel_int), missing

egen cit_operations_non_ded      = rowtotal(cyg_combustibles_lubric_vnd cyg_publicidad_propaganda_vnd cyg_suministros_mat_vnd cyg_transporte_vnd 				 ///
											cyg_gastos_ind_asig_ext_vnd cyg_gastos_g_imp_vnd cyg_gastos_viaje_vnd cyg_gastos_representacion_vnd  				 ///
											cyg_servicios_publicos_vnd cyg_pagos_otros_servicios_vnd cyg_pagos_otros_bienes_vnd cyg_isv_carga_costo_vnd 		 /// 
											cyg_beneficios_sociales_vnd cyg_capacitacion_vnd cyg_informatica_vnd cyg_gastos_seguro_vnd cyg_gastos_vigilancia_vnd /// 
											cyg_gastos_años_ant_vnd cyg_producto_financiero_vnd cyg_arrendamientos_vnd cyg_mantenimiento_rep_vnd), missing

egen cit_operations_ded 		= rowtotal(cyg_combustibles_lubric_c cyg_publicidad_propaganda_c cyg_suministros_mat_c cyg_transporte_c cyg_gastos_ind_asig_ext_c      ///
										   cyg_gastos_g_imp_c cyg_gastos_viaje_c cyg_gastos_representacion_c cyg_servicios_publicos_c cyg_pagos_otros_servicios_c      ///
										   cyg_pagos_otros_bienes_c cyg_isv_carga_costo_c cyg_combustibles_lubric_g cyg_publicidad_propaganda_g cyg_suministros_mat_g  /// 
										   cyg_transporte_g cyg_gastos_ind_asig_ext_g cyg_gastos_g_imp_g cyg_gastos_viaje_g cyg_gastos_representacion_g 			   ///
										   cyg_servicios_publicos_g cyg_pagos_otros_servicios_g cyg_pagos_otros_bienes_g cyg_isv_carga_costo_g 						   ///
										   cyg_beneficios_sociales_g cyg_capacitacion_g cyg_informatica_g cyg_gastos_seguro_g cyg_gastos_vigilancia_g              	   ///
										   cyg_gastos_años_ant_g cyg_producto_financiero_g cyg_arrendamientos_c cyg_mantenimiento_rep_c cyg_arrendamientos_g           ///
										   cyg_mantenimiento_rep_g), missing

egen cit_losses_other_non_ded   = rowtotal(cyg_cuentas_cobrar_vnd cyg_inventarios_vnd cyg_arrend_local_vnd cyg_arrend_exterior_vnd cyg_comisiones_local_vnd ///
										   cyg_comisiones_exterior_vnd cyg_perdida_vtas_act_rel_vnd cyg_perdida_vtas_act_norel_vnd cyg_otras_peridas_vnd    ///
										   cyg_seguros_reaseguros_vnd cyg_depreciacion_aceler_vnd cyg_depreciacion_noacel_vnd cyg_depreciacion_rev_pro_vnd  ///
										   cyg_agot_activos_expl_vnd cyg_otras_amortizaciones_vnd cyg_gast_reparar_dañ_nat_vnd cyg_inversiones_vnd          ///
										   cyg_cyg_gast_personales_vnd cyg_sueldos_obsequios_grat_vnd cyg_int_cap_invertidos_vnd cyg_perd_capital_inv_vnd   ///
										   cyg_contr_especial_seg_pob_vnd cyg_multas_recargos_vnd cyg_doc_no_cumplen_ley_vnd cyg_impt_rj_an_ap_vnd          ///
										   cyg_otros_gasto_no_deduc_vnd cyg_gastos_otras_prov_vnd cyg_perd_medicion_vnd), missing

egen cit_losses_other_ded       = rowtotal(cyg_otros_costos_gastos_c cyg_inventarios_c cyg_arrend_local_c cyg_arrend_exterior_c cyg_comisiones_local_c      ///
                                           cyg_comisiones_exterior_c cyg_otros_costos_gastos_g cyg_cuentas_cobrar_g cyg_inventarios_g cyg_arrend_local_g    ///
										   cyg_arrend_exterior_g cyg_comisiones_local_g delext_comisiones_int cyg_otras_peridas_c cyg_seguros_reaseguros_c  ///
										   cyg_depreciacion_aceler_c cyg_depreciacion_noacel_c cyg_depreciacion_rev_pro_c cyg_agot_activos_expl_c           ///
										   cyg_otras_amortizaciones_c cyg_perdida_vtas_act_rel_g cyg_perdida_vtas_act_norel_g cyg_otras_peridas_g           ///
										   cyg_seguros_reaseguros_g cyg_depreciacion_aceler_g cyg_depreciacion_noacel_g cyg_depreciacion_rev_pro_g          ///
										   cyg_agot_activos_expl_g cyg_otras_amortizaciones_g cyg_gnd_reparar_daños_nat_g cyg_inversiones_g                 ///
										   cyg_gast_personales_g cyg_sueldos_obsequios_grat_g cyg_int_cap_invertidos_g cyg_perd_capital_inv_g               ///
										   cyg_contr_especial_seg_pob_g cyg_multas_recargos_g cyg_doc_no_cumplen_ley_g cyg_impt_rj_an_ap_g                  ///
										   cyg_otros_gasto_no_deduc_g cyg_gastos_otras_prov_g cyg_perd_medicion_g cyg_perd_medicion_c), missing

g  double cit_precio_trans_ded  = deducautoajustepreciostran + cygajustespreciostranfc
replace cit_precio_trans_ded = 0 if (abs(deducautoajustepreciostran - cygajustespreciostranfc) < 1 & deducautoajustepreciostran != 0)

g cit_total_costs_ded = cit_goods_materials_ded + cit_operations_ded + cit_financial_ded + cit_labor_ded + cit_losses_other_ded - cit_precio_trans_ded
replace cit_total_costs_ded = 0 if cit_total_costs_ded < 0

g cit_total_costs_non_ded = cit_goods_materials_non_ded + cit_labor_non_ded + cit_financial_non_ded + cit_operations_non_ded + cit_losses_other_non_ded 
replace cit_total_costs_non_ded = 0 if cit_total_costs_non_ded < 0

g cit_total_costs = cit_total_costs_ded + cit_total_costs_non_ded 

* Generate a variable for the caused tax
loc tax_rate = 0.25
g double imp_segun_tarifa_renta_alt	   = `tax_rate' * baseimponrtanetagrav		
g porcentaje_ing_brutos_correct        = porcentaje_ing_brutos
replace porcentaje_ing_brutos_correct  = 0 if baseimponrtanetagrav <= 0 

g max_ISR_IM = max(porcentaje_ing_brutos_correct, imp_segun_tarifa_renta_alt)	
g max_AS     = max_ISR_IM + imp_segun_tarifa_aport_solid	

g causa_impuesto = .
replace causa_impuesto = 0 if max(max_AS, imp_segun_tarifa_activo_neto) == 0
replace causa_impuesto = 1 if max(max_AS, imp_segun_tarifa_activo_neto) == max_AS & ///
							  max(porcentaje_ing_brutos_correct, imp_segun_tarifa_renta_alt) == imp_segun_tarifa_renta_alt & ///
							  max(max_AS, imp_segun_tarifa_activo_neto) > 0
replace causa_impuesto = 2 if max(max_AS, imp_segun_tarifa_activo_neto) == imp_segun_tarifa_activo_neto & ///
							  max(max_AS, imp_segun_tarifa_activo_neto) > 0
replace causa_impuesto = 3 if max(max_AS, imp_segun_tarifa_activo_neto) == max_AS & ///
							  max(porcentaje_ing_brutos_correct, imp_segun_tarifa_renta_alt) == porcentaje_ing_brutos_correct & ///
							  max(max_AS, imp_segun_tarifa_activo_neto) > 0 
lab def causa_impuesto 0 "None" 1 "CIT" 2 "Net Asset" 3 "Minimum Tax"
lab val causa_impuesto causa_impuesto

g double impuesto_causado = .
replace impuesto_causado  = 0 		 						if causa_impuesto == 0 
replace impuesto_causado  = max_AS 							if causa_impuesto == 1
replace impuesto_causado  = imp_segun_tarifa_activo_neto 	if causa_impuesto == 2
replace impuesto_causado  = max_AS 							if causa_impuesto == 3
label var impuesto_causado "Impuesto causado real"

* Identify exempted firms based on tax credit levels and caused tax. If the company doesn't cause any tax, 
* it most to satisfy that made an exoneration request to the Ministery of Finance and also it has to belong to 
* any especial regime to be consider as an exonerated firm
egen cit_total_credits_r = rowtotal(cre_importe_exo_red_rta cre_retencion_art50_ley_rta cre_reten_anti_isr_o_atn_rta cre_pagos_cuenta_rta  ///
									cre_exe_ejer_fiscal_ant_rta cre_cesiones_credi_recib_rta cre_pagos_reali_periodo_rta                   ///
									cre_credi_gene_nuevos_empl cre_retencion_anti_irs_impor cre_import_compensacion_rta                    ///
									creditos_apli_pagos_cuenta_rta  pagos_anti_isr_decre96_2012), missing

egen cit_total_credits_an = rowtotal(cre_importe_exo_red_act_neto  cre_ret_anti_isr_o_atn_act_net cre_exe_ejer_fis_ant_ac_neto 		   ///
									 cre_cesiones_cred_recib_ac_net cre_pagos_reali_peri_act_net  cre_import_compensa_act_neto cre_isr_activo_neto), missing

egen cit_total_credits_as = rowtotal(cre_importe_exo_aport_soli cre_pagos_cuenta_as cre_excedente_ejer_ant_as cre_cesiones_cred_recib_as ///
									 cre_pagos_reali_periodo_as cre_import_compensacion_as creditos_apli_pagos_cuenta_as), missing

egen cre_importe_exo1 = rowtotal(cit_total_credits_*), missing
egen cre_importe_exo2 = rowtotal(cre_importe_exo_red_rta cre_importe_exo_red_act_neto cre_importe_exo_aport_soli), missing

g       exonerado_rit = 1 if max(cre_importe_exo1, cre_importe_exo2) > 1000 & (causa_impuesto == 1 | causa_impuesto == 3) & (regimenespecial == 4)
replace exonerado_rit = 0 if exonerado_rit ==.

g       ratio_exoneracion = 0
replace ratio_exoneracion = (cre_importe_exo_red_rta + cre_importe_exo_aport_soli)/(imp_segun_tarifa_renta + ///
							 imp_segun_tarifa_aport_solid) if (causa_impuesto == 1 | causa_impuesto == 3) 				
replace ratio_exoneracion = cre_importe_exo_red_act_neto / imp_segun_tarifa_activo_neto if causa_impuesto == 2	
replace ratio_exoneracion = 0 if missing(ratio_exoneracion)

merge 1:m rtn year using "`regimen'"  // Merge with the dataset of exonerated firms from the Ministry of Finance
duplicates drop
drop if _merge == 2
drop _merge
replace regimen = 0 if regimen == .

replace regimenespecial = 0 if regimenespecial == 6
g cit_exonerated = (ratio_exoneracion >= 0.9 | regimenespecial > 0)
replace cit_exonerated = 1 if (causa_impuesto == 0 & regimenespecial > 0 & regimen == 1)
replace cit_exonerated = 1 if (ratio_exoneracion < 0.9 & regimen == 1)
label def cit_exonerated 0 "Non-Exonerated" 1 "Exonerated"
label val cit_exonerated cit_exonerated

rename total_ingresos_resul_ejercicio cit_turnover
rename total_deduc_del_ejerc		  cit_deductions
rename form							  cit_form
rename regimenespecial				  cit_regime
rename causa_impuesto    			  cit_caused_tax
rename propiedad_planta_eq            cit_fixed_assets
rename c525_deprec_acum_propiedad	  cit_fixed_assets_depr  
rename total_activo_sf                cit_total_assets
rename activos_corrientes 			  cit_current_assets
rename pasivos_corrientes			  cit_current_liabilities

keep rtn year cit_*

tempfile cit_records
save "`cit_records'"
restore

**------------- 1.3 SALES TAX RECORDS -------------
preserve
use "$path\isv.dta", replace
keep if (year == 2017 | year == 2018)
keep if tipo_ot == "JURÍDICO"

egen sales_exempted    = rowtotal(vtas_exentas_mcdo_interno12 vtas_exentas_mcdo_interno15 ventas_exentas_mcdo_interno18), missing
egen sales_taxed       = rowtotal(vtas_netas_grav_mcdo_int12 ventas_netas_grav_mcdo_int15 ventas_netas_grav_mcdo_int18), missing
egen sales_exmp_purch  = rowtotal(ventasexoneradasoce15 ventasexoneradasoce18 ventasexoneradaspn15), missing
egen sales_fyduca      = rowtotal(transfbienesfyduca15 transfbienesfyduca18 transfserviciosfyduca15 transfserviciosfyduca18), missing
egen sales_exports     = rowtotal(ventas_exentas_expor_12 ventas_exentas_expor_15 ventas_exentas_expor_18 ///
								  ventas_exentas_exp_fuera_ca_12 ventas_exentas_exp_fuera_ca_15 ventas_exentas_exp_fuera_ca_18), missing
egen sales_imports     = rowtotal(importgrav12 importgrav15 importgrav18 importregion12 importregion15 importregion18  ///
								  importacionesexentas12 importacionesexentas15 importacionesexentas18), missing

** 1.3 MERGE BETWEEN CORPORATE AND SALES TAX RECORDS
merge 1:m rtn year using "`cit_records'"
drop _merge
tempfile tax_records
save "`tax_records'"
restore




**********************************************************************************
**********            SECOND PART: SETTING UP CUSTOMS RECORDS            *********
**********************************************************************************
preserve
use "$path\export.dta"
destring year, replace
keep if (year == 2017 | year == 2018)
egen x = group(rtn)
duplicates tag x year, gen(isdup)
keep if isdup == 0
drop x isdup
tempfile exports
save "`exports'"
restore

preserve
use "$path\import.dta"
keep if regimen == "4000"
drop regimen
destring year, replace
keep if (year == 2017 | year == 2018)
egen x = group(rtn)
duplicates tag x year, gen(isdup)
keep if isdup == 0
drop x isdup
merge m:m rtn year using "`exports'"
drop _merge
tempfile custom_records
save "`custom_records'"
restore




**********************************************************************************
**********              THIRD PART: SOCIAL SECURITY RECORDS              *********
**********************************************************************************

*Count for the total number of employees for each firm in 2017
preserve 
use "$path\ihss_2017.dta", replace 
merge m:1 NUMERO_PATRONAL using "$path\rtn_patrono.dta"
keep if _merge == 3
drop _merge
egen ihss_n_workers = count(IDENTIDAD), by(RTN)
sort RTN
drop if RTN == RTN[_n-1]
drop NOMBRE IDENTIDAD NUMERO_PATRONAL PATRONO RAZON_SOCIAL
g year = 2017
tempfile ihss_2017
save "`ihss_2017'"
restore

*Count for the total number of employees for each firm in 2018
preserve
use "$path\ihss_2018.dta", replace
merge m:1 NUMERO_PATRONAL using "$path\rtn_patrono.dta"
keep if _merge == 3
drop _merge
egen ihss_n_workers = count(IDENTIDAD), by(RTN)
sort RTN
drop if RTN == RTN[_n-1]
drop NOMBRE IDENTIDAD NUMERO_PATRONAL PATRONO RAZON_SOCIAL
g year = 2018
tempfile ihss_2018
save "`ihss_2018'"
restore

*Building social security dataset with tax identifier
append using "`ihss_2017'" "`ihss_2018'"
rename RTN rtn
tempfile ihss_tax_id
save "`ihss_tax_id'"




**********************************************************************************
**********                  FOURTH PART: IDENTIFYING MNC                 *********
**********************************************************************************
preserve
use "$input\Base_precios_2014_2020.dta", replace 
drop if periodo ==202001
drop if ptstiporelaciónid==18   // no relationship
keep if tipodedeclaración=="ORIGINAL" 
drop if ptstiporelaciónid==11 | ptstiporelaciónid==12

gen foreign = 0
replace foreign = 1 if ptspais != "HONDURAS"

gen owner = 0
replace owner = 1 if (ptstiporelaciónid == 1 | ptstiporelaciónid == 3 | ptstiporelaciónid == 5 | ///
					  ptstiporelaciónid == 6 | ptstiporelaciónid == 9)

gen owned = 0
replace owned = 1 if owner != 1

gen foreign_owner = 0
replace foreign_owner = 1 if owned == 1 & foreign == 1

sort otrtn
bys otrtn: egen max_foreign       = max(foreign)
bys otrtn: egen max_foreign_owner = max(foreign_owner)

keep if max_foreign_owner == 1
collapse (mean) max_foreign_owner, by(otrtn)
rename otrtn rtn
rename max_foreign_owner foreign_ownership

keep rtn foreign_ownership
tempfile mnc
save "`mnc'"
restore




**********************************************************************************
**********                  FIFTH PART: IDENTIFYING AGE                  *********
**********************************************************************************
preserve 
import excel "$path\EDAD_PJ.xlsx", firstrow clear
rename RTN 					  rtn
rename FECHA_CONSTITUCION     date_begin_aux
rename FECHA_INICIO_ACTIVIDAD date_start_aux
keep rtn date_*
tostring date_begin_aux, replace
tostring date_start_aux, replace
g date_begin = substr(date_begin_aux,1,4)
g date_start = substr(date_start_aux,1,4)
destring date_begin, replace
destring date_start, replace
drop if (missing(date_begin) | missing(date_start))
keep rtn date_begin date_start
g date_aux = max(date_begin, date_start)
drop date_begin date_start
rename date_aux date_start
drop if date_start == 6052
drop if date_start == 5062
drop if date_start == 5032
drop if date_start == 4042
drop if date_start == 3072
replace date_start = 1994 if date_start == 9994
replace date_start = 1990 if date_start == 9990
replace date_start = 2003 if date_start == 9003
replace date_start = 2007 if date_start == 3007
replace date_start = 2005 if date_start == 3005
replace date_start = 1967 if date_start == 1867
replace date_start = 1968 if date_start == 1868
tempfile date
save "`date'"
restore




**********************************************************************************
**********        SIXTH PART: NUMBER OF PARTNERS AND MANAGER GENDER      *********
**********************************************************************************
* Gender and age of the manager
preserve 
import delimited "C:\Users\jbermudez\OneDrive - SAR\Bases del repositorio\base_rnp.csv", stringcols(2)
keep nombre id fecnac genero
tempfile civil_records
save "`civil_records'"
restore

*preserve
import delimited "$input\Socios.csv", stringcols(1 3) clear
keep if tipo_relacion == "ADMINISTRADOR ¿NICO" | tipo_relacion == "GERENTE GENERAL"
order rtn rtn_relacionado, first
sort rtn rtn_relacionado
drop if (rtn == rtn[_n-1] & rtn_relacionado == rtn_relacionado[_n-1])
gen dum = (fecha_hasta != "")
drop if (dum == 1)
drop fecha_hasta dum
gen relacion = 1
replace relacion = 2 if tipo_relacion == "ADMINISTRADOR ¿NICO"
sort rtn relacion
gen dum = (rtn == rtn[_n-1] & relacion != relacion[_n-1])
drop if dum == 1
drop dum relacion
gen desde = substr(fecha_desde,1,4)
destring desde, replace
egen min = min(desde), by(rtn)
duplicates tag rtn, gen(tag)
gen dum = cond(rtn == rtn[_n-1] & min == desde & tag > 0 & desde != desde[_n-1], 1, 0) 
drop if dum == 1
drop dum fecha_desde desde min
keep if tag == 0

gen id = substr(rtn_relacionado, 1, 13)
merge 1:1 id using "`civil_records'", keepusing(nombre fecnac genero)
restore


**********************************************************************************
**********               SEVENTH PART: FINAL PANEL DATASET               *********
**********************************************************************************

* Constructing final panel dataset
merge 1:m rtn year using "`tax_records'"
keep if _merge == 3
drop _merge 

merge m:m rtn year using "`custom_records'"
duplicates drop
drop _merge

g final_exports     		 = max(sales_exports, custom_export)
g final_imports     		 = max(sales_imports, custom_import)

egen sales_total       = rowtotal(sales_exempted sales_taxed sales_exmp_purch sales_fyduca final_exports), missing
egen sales_purch       = rowtotal(comprasnetasmerc12 comprasnetasmerc15 comprasnetasmerc18 comprasexentasmerc12 comprasexentasmerc15 comprasexentasmerc18 ///
								  comprasexoneradasoce15 comprasexoneradasoce18 adquisifyducagravadas15 adquisifyducagravadas18 ///
								  adquisifyducaexeexo15 adquisifyducaexeexo18 final_imports), missing



* Impute economic activities for final panel dataset and only keep corporations
drop tipo_ot
merge m:1 rtn using "$input\Datos_Generales_AE_02_2022.dta", ///
	  keepusing(codigo clase codigoseccion seccion tipo_ot departamento municipio)
keep if _merge == 3
duplicates drop
drop _merge 
keep if tipo_ot == 1
drop tipo_ot



* Merge with multinational corporations
merge m:1 rtn using "`mnc'", keepusing(foreign_ownership)
duplicates drop
drop if _merge == 2
drop _merge
replace foreign_ownership = 0 if foreign_ownership == .
gen mnc = (foreign_ownership == 1 & ihss_n_workers >= 100)
label def mnc 1 "MNC" 0 "Not a MNC"
label val mnc mnc



* Merge with the age of the firm
merge m:m rtn using "`date'", keepusing(date_start)
drop if _merge == 2
drop _merge



egen id = group(rtn)
drop rtn
duplicates tag id year, gen(isdup)
keep if isdup == 0
keep  id year codigo clase codigoseccion seccion departamento municipio ihss_n_workers cit_* sales_* custom_* final_* mnc date_start
order id year codigo clase codigoseccion seccion departamento municipio ihss_n_workers cit_* sales_* custom_* final_* mnc date_start
mvencode _all, mv(0) override
compress

save "$out\final_dataset", replace
