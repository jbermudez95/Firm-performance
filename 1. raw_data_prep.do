/*
Name:			raw_data_prep.do
Description: 	This do file cleans and prepares different administrative sources
                which are merged to build an unbalanced panel for the descriptive 
				and empirical estimations of the paper 
				"Firms' performance and tax incentives: evidence from Honduras". 
Date:			July, 2021
Modified:       October, 2022
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
set more off
cap prog drop _all

*Set up directories
if "`c(username)'" == "Owner" {
	global path  "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\preparacion inicial\base profit margins"
	global input "C:\Users\Owner\OneDrive - SAR\Bases del repositorio"
	global out	 "C:\Users\Owner\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"	
}
else if "`c(username)'" == "jbermudez" {
	global path  "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\preparacion inicial\base profit margins"
	global input "C:\Users\jbermudez\OneDrive - SAR\Bases del repositorio"
	global out	 "C:\Users\jbermudez\OneDrive - SAR\Notas técnicas y papers\Profit Margins\database and codes"
} 

global traits "tipo_ot tamaño_ot codigo clase codigoseccion seccion departamento municipio"



**********************************************************************************
********      FIRST STEP: CORPORATE TAX RECORDS (MASTER DATASET)          ********
**********************************************************************************

dis "Setting Corporate Income Tax Records"
qui{
preserve
* Initial setting (only keep electronic tax forms)
use "$input\Base_ISRPJ_2014_2021_0707.dta", clear
keep if year == 2017 | year == 2018
sort rtn year
duplicates drop rtn year, force
drop ${traits}

format %13.0f nro_preimpreso
tostring nro_preimpreso, gen(form) usedisplayformat
replace form = (substr(form, 1, 3))
keep if form == "357"

* Income variables
egen cit_sales_local = rowtotal(ingr_vtas_grav_12_total_ingr ingr_vtas_grav_15_total ingr_vtas_grav_18_total ingr_vtas_servicios_exe_total), missing

egen cit_sales_exports = rowtotal(ingr_vtas_serv_expor_total ingr_vtas_serv_fyduca_total), missing

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

* Adjusting firms that turned out without income (in our construction) but have income > 0 in the tax form
replace cit_total_inc = cond(total_ingresos_resul_ejercicio > 0 & cit_total_inc == 0, total_ingresos_resul_ejercicio, cit_total_inc)


* Costs and expenses
g cit_goods_materials_non_ded = cyg_gastos_compra_vnd

g    cit_com_costs               = cyginvinicialbienesc + cygcomprasbrutaslocalc + cygcomprasimportbienesc - cygdescdevcomprasc - cyginvfinalbienesc

g    cit_prod_costs 			 = cyginvinicialmatprimac + cygcomprasnetasmatprimac + cygimportacionmatprimac - cyginvfinalmatprimac + cyggastosindirfabrc + /// 		  		
								   cyginvinicialprodprocc - cyginvfinalprodprocc + cyginvinicialprodtermc - cyginvfinalprodtermc
								   
g 	 cit_goods_materials_ded 	 = cit_com_costs + cit_prod_costs 

replace cit_goods_materials_ded  = cit_goods_materials_ded + cyg_gastos_compra_c + cyg_gastos_compra_g 

egen cit_labor_non_ded           = rowtotal(cyg_cyg_gastos_com_vtas_vnd cyg_sueldos_salarios_vnd cyg_honorarios_prof_vnd cyg_honorarios_extranj_vnd), missing

egen cit_labor_ded               = rowtotal(cygmanoobradirc cygmanoobraindirc cyg_gastos_com_vtas_c cyg_sueldos_salarios_c cyg_honorarios_prof_c cyg_honorarios_extranj_c ///
											cyg_gastos_com_vtas_g cyg_sueldos_salarios_g cyg_honorarios_prof_g cyg_cyg_honorarios_extranj_g), missing
											
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

g  double cit_precio_trans_ded  = deducautoajustepreciostran 
replace cit_precio_trans_ded = cond(abs(deducautoajustepreciostran - cygajustespreciostranfc) < 1 & deducautoajustepreciostran != 0, 0, cit_precio_trans_ded) 

g cit_total_costs_ded = cit_goods_materials_ded + cit_operations_ded + cit_financial_ded + cit_labor_ded + cit_losses_other_ded - cit_precio_trans_ded
replace cit_total_costs_ded = 0 if cit_total_costs_ded < 0
replace cit_total_costs_ded = cond(total_deduc_del_ejerc > 0 & cit_total_costs_ded == 0, total_deduc_del_ejerc, cit_total_costs_ded)

g cit_total_costs_non_ded = cit_goods_materials_non_ded + cit_labor_non_ded + cit_financial_non_ded + cit_operations_non_ded + cit_losses_other_non_ded 
replace cit_total_costs_non_ded = 0 if cit_total_costs_non_ded < 0

g cit_total_costs = cit_total_costs_ded + cit_total_costs_non_ded 


* Identify exonerated firms based on exonerations credits (tax authority only enables exonerated firms to fill this cell in the tax form)
egen cit_total_credits_r = rowtotal(cre_importe_exo_red_rta cre_retencion_art50_ley_rta cre_reten_anti_isr_o_atn_rta cre_pagos_cuenta_rta  ///
									cre_exe_ejer_fiscal_ant_rta cre_cesiones_credi_recib_rta cre_pagos_reali_periodo_rta                   ///
									cre_credi_gene_nuevos_empl cre_retencion_anti_irs_impor cre_import_compensacion_rta                    ///
									creditos_apli_pagos_cuenta_rta  pagos_anti_isr_decre96_2012), missing
egen cit_total_credits_an = rowtotal(cre_importe_exo_red_act_neto  cre_ret_anti_isr_o_atn_act_net cre_exe_ejer_fis_ant_ac_neto 		   ///
									 cre_cesiones_cred_recib_ac_net cre_pagos_reali_peri_act_net  cre_import_compensa_act_neto cre_isr_activo_neto), missing
egen cit_total_credits_as = rowtotal(cre_importe_exo_aport_soli cre_pagos_cuenta_as cre_excedente_ejer_ant_as cre_cesiones_cred_recib_as ///
									 cre_pagos_reali_periodo_as cre_import_compensacion_as creditos_apli_pagos_cuenta_as), missing
egen cit_cre_exo = rowtotal(cre_importe_exo_red_rta cre_importe_exo_red_act_neto cre_importe_exo_aport_soli), missing

replace regimenespecial = 6 if regimenespecial == 0
lab def regimenespecial 1 "ZADE" 2 "ZOLI" 3 "ZOLT" 4 "RIT" 5 "Otros Regímenes" 6 "Ninguno" 7 "ZOLITUR" 8 "Simplificado" 9 "LIT" ///
						11 "Depósitos Temporales" 13 "Otros Exonerados" 14 "ZADE" 15 "Cooperativas" 16 "MIPYMES" ///
						17 "Sector Social de la Economía" 18 "Transportistas" 20 "Alianza Público Privada" 21 "Incentivos al Turismo" ///
						23 "Energía Renovable" 24 "Iglesias" 27 "ONG" 28 "Organismos Internacionales" 34 "El Estado" 39 "Asociaciones Patronales" ///
						40 "Colegios Profesionales" 41 "Sindicatos Obreros" 43 "Biocombustibles" 44 "Call Centers" 46 "OPDF"					
label val regimenespecial regimenespecial

* The church, the government, professional colleges, ccoperatives, and non profit organizations are removed
drop if (regimenespecial == 8 | regimenespecial == 11 | regimenespecial == 15 | regimenespecial == 16 | ////
         regimenespecial == 18 | regimenespecial == 24 | regimenespecial == 27 | regimenespecial == 28 | /// 
         regimenespecial == 34 | regimenespecial == 39 | regimenespecial == 40 | regimenespecial == 41) 

gen cit_exonerated = cond(cit_cre_exo > 0 & regimenespecial != 6, 1, 0)
replace regimenespecial = 6 if cit_exonerated == 0
label def cit_exonerated 0 "Non-Exonerated" 1 "Exonerated"
label val cit_exonerated cit_exonerated

rename total_ingresos_resul_ejercicio cit_gross_income
rename total_deduc_del_ejerc		  cit_deductions
rename regimenespecial				  cit_regime
rename propiedad_planta_eq            cit_fixed_assets
rename c525_deprec_acum_propiedad	  cit_fixed_assets_depr  
rename total_activo_sf                cit_total_assets
rename activos_corrientes 			  cit_current_assets
rename pasivos_corrientes			  cit_current_liabilities
rename form							  cit_form
keep rtn year cit_*
tempfile cit_records
save "`cit_records'"
restore
}



**********************************************************************************
********                 SECOND STEP: SALES TAX RECORDS                   ********
**********************************************************************************

dis "Setting Value Added Tax Records"
qui{
preserve
use "$input\ISV_anual_2004_2021.dta", replace
keep if (year == 2017 | year == 2018)
duplicates drop rtn year, force
drop ${traits}
* Variables on Sales 
egen vat_sales_exempted   = rowtotal(ventasexoneradasoce15 ventasexoneradasoce18 ventasexoneradaspn15 ///
                                     vtas_exentas_mcdo_interno12 vtas_exentas_mcdo_interno15 ventas_exentas_mcdo_interno18), missing
egen vat_sales_taxed      = rowtotal(vtas_netas_grav_mcdo_int12 ventas_netas_grav_mcdo_int15 ventas_netas_grav_mcdo_int18), missing
egen vat_sales_exports    = rowtotal(transfbienesfyduca15 transfbienesfyduca18 transfserviciosfyduca15 transfserviciosfyduca18 ///
									 ventas_exentas_expor_12 ventas_exentas_expor_15 ventas_exentas_expor_18 ///
								     ventas_exentas_exp_fuera_ca_12 ventas_exentas_exp_fuera_ca_15 ventas_exentas_exp_fuera_ca_18), missing
gen vat_sales_local	      = vat_sales_exempted + vat_sales_taxed								 								  
* Variables on Purchases
egen vat_purch_exempted = rowtotal(comprasexentasmerc12 comprasexentasmerc15 comprasexentasmerc18 ///
							       comprasexoneradasoce15 comprasexoneradasoce18), missing
egen vat_purch_taxed    = rowtotal(comprasnetasmerc12 comprasnetasmerc15 comprasnetasmerc18), missing						  
egen vat_purch_imports  = rowtotal(adquisifyducagravadas15 adquisifyducagravadas18 adquisifyducaexeexo15 adquisifyducaexeexo18 ///
								   importgrav12 importgrav15 importgrav18 importregion12 importregion15 importregion18  ///
							       importacionesexentas12 importacionesexentas15 importacionesexentas18), missing							   
gen vat_purch_local     = vat_purch_exempted + vat_purch_taxed	
keep rtn year vat_*
tempfile vat_records
save "`vat_records'"		   
restore	
}



**********************************************************************************
**********                   THIRD STEP: CUSTOMS RECORDS                 *********
**********************************************************************************

dis "Setting Customs Records"
qui{
* Data on Exports/Imports (already in local currency - Lempiras)
preserve
* Exports
use "$path\export.dta", replace
destring year, replace
keep if (year == 2017 | year == 2018)
bys rtn year: egen suma_export = sum(custom_export)
duplicates drop rtn year, force
drop custom_export 
rename suma_export custom_export
tempfile exports
save "`exports'"

* Imports
use "$path\import.dta", replace
keep if regimen == "4000"
drop regimen
destring year, replace
keep if (year == 2017 | year == 2018)
bys rtn year: egen suma_import = sum(custom_import)
duplicates drop rtn year, force
drop custom_import 
rename suma_import custom_import
merge 1:1 rtn year using "`exports'"
drop _m
tempfile custom_records
save "`custom_records'"
restore
}



**********************************************************************************
**********              FOURTH STEP: SOCIAL SECURITY RECORDS             *********
**********************************************************************************

dis "Setting Social Security Records"
qui {
* Counting the total number of employees for each firm 
preserve 
use "$input\IHSS_2017_2018.dta", replace 
merge m:m NUMERO_PATRONAL using "$input\rtn_patrono.dta"
keep if _m == 3
drop _merge
egen ihss_workers = group(IDENTIDAD)
collapse (count) ihss_workers, by(rtn year)
tempfile social_security
save "`social_security'"
restore
}




**********************************************************************************
**********                   FIFTH STEP: IDENTIFYING MNC                 *********
**********************************************************************************

dis "Setting Transfer Pricing Records for MNC"
qui{
/* As in Alfaro-Ureña et al (QJE, 2022), MNC are defined as companies reporting at least one transaction  
(between 2014-2021) with another foreign counterpart with some kind of ownership dependency and also has >= 100 workers */
preserve
use "$input\Base_precios_2014_2021.dta", replace 
keep if tipodedeclaración == "ORIGINAL" 
drop if (ptstiporelacióndesc == "AMBAS PARTES SE ENCUENTRAN DIRECTAMENTE BAJO LA DIRECCIÓN, CONTROL O CAPITAL DE UNA MISMA PERSONA O ENTIDAD" | ///
         ptstiporelacióndesc == "AMBAS PARTES SE ENCUENTRAN INDIRECTAMENTE BAJO LA DIRECCIÓN, CONTROL O CAPITAL DE UNA MISMA PERSONA O ENTIDAD" | ///
		 ptstiporelacióndesc == "NO HAY RELACIÓN")			 
gen owned = cond(ptstiporelacióndesc == "DECLARANTE ES FILIAL O LA CONTRAPARTE TIENE EL 50% O MÁS DE SU PROPIEDAD" | ///
				 ptstiporelacióndesc == "CONTRAPARTE TIENE PARTICIPACIÓN DIRECTA EN LA DIRECCIÓN O ADMINISTRACIÓN DEL DECLARANTE" | ///
                 ptstiporelacióndesc == "CONTRAPARTE TIENE PARTICIPACIÓN INDIRECTA EN LA DIRECCIÓN O ADMINISTRACIÓN DEL DECLARANTE" | ///
				 ptstiporelacióndesc == "DECLARANTE ES AGENCIA O ESTABLECIMIENTO PERMANENTE" | ///
				 ptstiporelacióndesc == "DECLARANTE ES CONTROLADA" | ///
				 ptstiporelacióndesc == "DEPENDENCIA FINANCIERA O ECONÓMICA", 1, 0)
* Foreign counterpart has any kind of property on local firm 				 
gen foreign = cond(ptspais != "HONDURAS", 1, 0)
gen foreign_owned = cond(owned == 1 & foreign == 1, 1, 0)
sort otrtn
bys otrtn: egen max_foreign_owned = max(foreign_owned)
keep if max_foreign_owned == 1
collapse (mean) max_foreign_owned, by(otrtn otnombrerazónsocial)
duplicates drop otrtn, force
rename otrtn rtn
rename max_foreign_owned foreign_ownership
keep rtn foreign_ownership
tempfile mnc
save "`mnc'"
restore
}



**********************************************************************************
**********                  SIXTH STEP: IDENTIFYING AGE                  *********
**********************************************************************************

dis "Setting Date for Firms' Start-Up'"
qui {
/* In order to identify the age, we define the beginning of the firm as the
 minimum value between the registration year and the start-up year of operations */
preserve 
import excel "$path\EDAD_PJ.xlsx", firstrow clear
rename RTN 					  rtn
rename FECHA_CONSTITUCION     date_begin_aux
rename FECHA_INICIO_ACTIVIDAD date_start_aux
tostring date_begin_aux, replace
tostring date_start_aux, replace
g date_begin = substr(date_begin_aux,1,4)
g date_start = substr(date_start_aux,1,4)
destring date_begin, replace
destring date_start, replace
drop if (missing(date_begin) & missing(date_start))
* Fixing up wrong dates by hand
replace date_begin = 2001 if date_begin == 1001 | date_begin == 1042
replace date_begin = 2002 if date_begin == 1002
replace date_begin = 1960 if date_begin == 1060
replace date_begin = 2005 if date_begin == 1201
replace date_begin = 2007 if date_begin == 2007
replace date_begin = 1991 if date_begin == 1091
replace date_begin = 1990 if date_begin == 1990
replace date_begin = 1982 if date_begin == 1820
replace date_begin = 1971 if date_begin == 1071
replace date_begin = 1982 if date_begin == 1082
replace date_begin = 1997 if date_begin == 1197
replace date_begin = 2006 if date_begin == 1837
replace date_begin = 1976 if date_begin == 1900
replace date_start = 2011 if date_start == 6052
replace date_start = 1999 if date_start == 5062
replace date_start = 2005 if date_start == 5032
replace date_start = 2005 if date_start == 4042
replace date_start = 2009 if date_start == 3072
replace date_start = 1994 if date_start == 9994
replace date_start = 2012 if date_start == 9990
replace date_start = 2003 if date_start == 9003
replace date_start = 2007 if date_start == 3007
replace date_start = 2014 if date_start == 3005
replace date_start = 2002 if date_start == 2202
replace date_start = 2013 if date_start == 2200
replace date_start = 2006 if date_start == 2060
replace date_start = 2007 if date_start == 2207
replace date_start = 2009 if date_start == 2099
replace date_start = 2002 if date_start == 2092
replace date_start = 2010 if date_start == 2505
replace date_start = 2010 if date_start == 2201
replace date_start = 2008 if date_start == 2088
replace date_start = 2010 if date_start == 2201
replace date_start = 2004 if date_start == 2044
replace date_start = 2011 if date_start == 2101
replace date_start = 2010 if date_start == 2301
replace date_start = 2011 if date_start == 2032
replace date_start = 2005 if date_start == 2055
replace date_start = 2008 if date_start == 2088
replace date_start = 2008 if date_start == 2044
replace date_start = 2007 if date_start == 2207
replace date_start = 2012 if date_start == 2031
replace date_start = 2013 if date_start == 2052
replace date_start = 2013 if date_start == 2225
replace date_start = 2013 if date_start == 2213
replace date_start = 2013 if date_start == 2031
replace date_start = 2014 if date_start == 2040
replace date_start = 2012 if date_start == 2041
replace date_start = 1995 if date_start == .
replace date_begin = 1979 if rtn == "08019995313990"
replace date_begin = 2007 if rtn == "12129007114176" 
replace date_begin = 1990 if rtn == "08019995367485"
replace date_begin = 2007 if rtn == "05019007485205"
replace date_begin = 2009 if rtn == "05019009492085"
replace date_start = 2016 if rtn == "08019016875008"
replace date_start = 2018 if rtn == "08019019093491"
replace date_start = 2018 if rtn == "04019019139143"
replace date_start = 2020 if rtn == "08019020236054"
replace date_start = 2021 if rtn == "08019021257260"
replace date_start = 2021 if rtn == "08019021282966"
replace date_start = 2021 if rtn == "08019021291269"
replace date_start = 2021 if rtn == "08019021303971"
replace date_start = 2021 if rtn == "08019021311475"
replace date_start = 2021 if rtn == "08019021322465"
replace date_start = 2021 if rtn == "08019021330061"
replace date_start = 2021 if rtn == "08019021328201"
replace date_start = 1975 if rtn == "01019995013536"
replace date_start = 2013 if rtn == "08019013601520"
replace date_start = 2008 if rtn == "05019008164664"
replace date_start = 2006 if rtn == "10069007053489"
replace date_start = 2001 if rtn == "04019002035232"
replace date_start = 2000 if rtn == "14169006503710"
replace date_start = 2010 if rtn == "08019009253390"
replace date_start = 2008 if rtn == "05019009209033"
replace date_start = 2009 if rtn == "08019010274457"
replace date_start = 2011 if rtn == "08019011356994"
replace date_start = 2001 if rtn == "05019008186129"
replace date_start = 2008 if rtn == "05019008139473"
replace date_start = 2001 if rtn == "05019001055434"
replace date_start = 2000 if rtn == "05019001054690"
replace date_start = 2013 if rtn == "08019013578662"
replace date_start = 2012 if rtn == "05019012505640"
replace date_start = 2011 if rtn == "17019011433857"
replace date_start = 1989 if rtn == "07019995379153"
replace date_start = 1992 if rtn == "15179004473784"
replace date_start = 1992 if rtn == "05019995108344"
replace date_start = 2010 if rtn == "17099011344403"
replace date_start = 2001 if rtn == "05019002066596"
replace date_start = 2000 if rtn == "05019001051767"
replace date_start = 2015 if rtn == "08019014703372"
replace date_start = 2008 if rtn == "08019011406916"
replace date_start = 1996 if rtn == "05019002068600"
replace date_start = 1995 if rtn == "05069995154411"
replace date_start = 1992 if rtn == "05019998168899"
replace date_start = 1983 if rtn == "08019999402898"
replace date_start = 2000 if rtn == "03029001029422"
replace date_start = 1970 if rtn == "16219995440272"
replace date_start = 2012 if rtn == "08019012447460"
replace date_start = 1999 if rtn == "08019998386654"
replace date_start = 1998 if rtn == "08019995381815"
replace date_start = 1998 if rtn == "08019998394364"
replace date_start = 1998 if rtn == "15099998443855"
replace date_start = 1998 if rtn == "08019995368181"
replace date_start = 1999 if rtn == "05019998170605"
replace date_start = 2011 if rtn == "02099011439544"
replace date_start = 1996 if rtn == "04019998037887"
replace date_start = 1997 if rtn == "07039998206570"
replace date_start = 2004 if rtn == "01019995012998"
replace date_start = 2003 if rtn == "04019003036825"
replace date_start = 2010 if rtn == "01079995021595"
replace date_start = 1995 if rtn == "08019998390080"
g date_aux = min(date_begin, date_start)
keep rtn date_aux
rename date_aux date_start
tempfile date
save "`date'"
restore
}



**********************************************************************************
**********     			      SEVENTH STEP: LEGAL PROXY    			     *********
**********************************************************************************

dis "Setting for Legal Representative Proxy on Lobby"
qui {
* We approximate firms' lobbying ability as an extensive margin measure, according to the number of attorneys it has
preserve
import delimited "$input\relaciones_profesionales.csv", stringcols(1 4 5 6 7) clear
keep if tipo_relacion == "REPRESENTANTE LEGAL" | tipo_relacion == "APODERADO LEGAL"
sort rtn identificacion
gen hasta = cond(fecha_hasta != "", substr(fecha_hasta,1,4), "")
destring hasta, replace
drop if hasta < 2017 & !missing(hasta)
drop if hasta > 2022 & !missing(hasta)
duplicates drop rtn identificacion , force
egen x = group(identificacion)
collapse (count) x, by(rtn)
g legal_proxy = cond(x>1,1,0)
label def legal_proxy 0 "No lobbying ability" 1 "Lobbying ability"
label val legal_proxy legal_proxy
keep rtn legal_proxy
tempfile legal_proxy
save "`legal_proxy'"
restore
}



**********************************************************************************
**********     			      EIGHTH STEP: EVER AUDITED    			     *********
**********************************************************************************

dis "Setting for firms that have been audited at least once"
qui{
preserve
import excel using "$path\ORDENES DE FISCALIZACION.xlsx", firstrow clear 
drop K-Q
rename _all, lower
drop if (estado_proceso == "INTERRUMPIDO" | estado_proceso == "PENDIENTE")
gen notificacion = fecha_presentacion
tostring notificacion, replace
replace notificacion = substr(notificacion,3,4)
destring notificacion, replace
gen inicio = year(fecha_inicio)
gen dif = notificacion - inicio
gsort -dif
duplicates drop rtn, force
drop if inicio == 2020
gen ever_audited = 1
label def ever_audited 0 "Non audited" 1 "Audited at least once"
label var ever_audited ever_audited
tempfile ever_audited
save "`ever_audited'"
restore	
}



**********************************************************************************
**********                  EIGHTH STEP: FINAL DATASET                   *********
**********************************************************************************

* Merge datasets
use "`cit_records'", replace
loc records1 "vat_records custom_records social_security"
foreach r of loc records1 {
	merge 1:1 rtn year using "``r''"
	drop if _m == 2
	drop _m
	duplicates drop rtn year, force 
}
loc records2 "mnc date legal_proxy ever_audited"
foreach r of loc records2 {
	merge m:1 rtn using "``r''"
	drop if _m == 2
	drop _m
	duplicates drop rtn year, force 
}

replace foreign_ownership = cond(missing(foreign_ownership), 0, foreign_ownership)
replace legal_proxy 	  = cond(missing(legal_proxy), 0, legal_proxy)
replace ever_audited 	  = cond(missing(ever_audited), 0, ever_audited)

* Turnover (and purchases) might be underestimated so we rebuild it combining CIT, VAT and Customs records for local and foreign sales
* We assume that the true value of exports/imports is the highest between the internal tax (in the CIT/VAT tax form) and customs records
g final_sales_local = max(cit_sales_local, vat_sales_local)
g final_exports     = max(cit_sales_exports, vat_sales_exports, custom_export)
g final_imports     = max(vat_purch_imports, custom_import)

egen final_total_sales = rowtotal(final_sales_local final_exports)
egen final_total_purch = rowtotal(vat_purch_local final_imports)

* Encode as missing all values equal to zero
	mvdecode vat_* custom_* final_* cit_current_assets cit_fixed_assets cit_total_assets cit_current_liabilities cit_gross_income ///
			 cit_deductions cit_fixed_assets_depr cit_sales_local cit_sales_exports cit_turnover_exempt cit_turnover_taxed ///
			 cit_other_inc_taxed cit_other_inc_exempt cit_total_exempt_inc cit_total_taxed_inc cit_total_inc ///
			 cit_goods_materials_non_ded cit_com_costs cit_prod_costs cit_goods_materials_ded cit_labor_non_ded ///
			 cit_labor_ded cit_financial_non_ded cit_financial_ded cit_operations_non_ded cit_operations_ded ///
			 cit_losses_other_non_ded cit_losses_other_ded cit_precio_trans_ded cit_total_costs_ded cit_total_costs_non_ded ///
			 cit_total_costs cit_total_credits_r cit_total_credits_an cit_total_credits_as cit_cre_exo, mv(0)

* Identifying MNC according to foreign ownership and size restrictions
bys rtn: egen mean_work = mean(ihss_workers)
gen final_mnc = (foreign_ownership == 1 & mean_work >= 100 & !missing(mean_work))
label def final_mnc 1 "MNC" 0 "Not a MNC"
label val final_mnc final_mnc
drop mean_work

* Impute economic activities for final panel dataset and only keep corporations
merge m:1 rtn using "$input\Datos_Generales_09_2022.dta", keepusing(${traits})
keep if _m == 3
drop _merge 

egen id = group(rtn)
duplicates tag id year, gen(isdup)
keep if isdup == 0
keep  id year ${traits} ihss_workers cit_* vat_* custom_* final_* final_mnc date_start legal_proxy ever_audited
order id year ${traits} ihss_workers cit_* vat_* custom_* final_* final_mnc date_start legal_proxy ever_audited
compress
save "$out\final_dataset1", replace
								  								  
