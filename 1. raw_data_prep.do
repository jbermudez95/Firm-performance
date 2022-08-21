
/*
Name:			raw_data_prep.do
Description: 	This do file cleans and prepares different administrative sources
                which are merged to build an unbalanced panel for the descriptive 
				and empirical estimations of the paper 
				"Firms' performance and tax incentives: evidence from Honduras". 
Date:			July, 2021
Modified:       August, 2022
Author:			Jose Carlo Bermúdez
Contact: 		jbermudez@sar.gob.hn
*/

clear all
set more off

*Set up directories
if "`c(username)'" == "Owner" {
	global path  "C:\Users\Owner\OneDrive - SAR\Profit Margins\preparacion inicial\base profit margins"
	global input "C:\Users\Owner\OneDrive - SAR\Bases del repositorio"
	global out	 "C:\Users\Owner\OneDrive - SAR\Profit Margins\database and codes"	
}
else if "`c(username)'" == "jbermudez" {
	global path  "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\preparacion inicial\base profit margins"
	global input "C:\Users\jbermudez\OneDrive - SAR\Bases del repositorio"
	global out	 "C:\Users\jbermudez\OneDrive - SAR\Profit Margins\database and codes"
} 


**********************************************************************************
********               FIRST STEP: CORPORATE TAX RECORDS                  ********
**********************************************************************************

preserve
* Initial setting (only keep electronic tax forms)
use "$input\Base_ISRPJ_2014_2021_0707.dta", clear
compress 

keep if year == 2017 | year == 2018
sort rtn year
duplicates drop rtn year, force

format %13.0f nro_preimpreso
tostring nro_preimpreso, gen(form) usedisplayformat
replace form = (substr(form, 1, 3))
keep if form == "357"


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

rename total_ingresos_resul_ejercicio cit_turnover
rename total_deduc_del_ejerc		  cit_deductions
rename regimenespecial				  cit_regime
rename propiedad_planta_eq            cit_fixed_assets
rename c525_deprec_acum_propiedad	  cit_fixed_assets_depr  
rename total_activo_sf                cit_total_assets
rename activos_corrientes 			  cit_current_assets
rename pasivos_corrientes			  cit_current_liabilities

keep rtn year cit_*

tempfile cit_records
save "`cit_records'"
restore



**********************************************************************************
********                 SECOND STEP: SALES TAX RECORDS                   ********
**********************************************************************************

preserve
use "$input\ISV_anual_2004_2021.dta", replace
keep if (year == 2017 | year == 2018)
duplicates drop rtn year, force

egen sales_exempted    = rowtotal(vtas_exentas_mcdo_interno12 vtas_exentas_mcdo_interno15 ventas_exentas_mcdo_interno18), missing
egen sales_taxed       = rowtotal(vtas_netas_grav_mcdo_int12 ventas_netas_grav_mcdo_int15 ventas_netas_grav_mcdo_int18), missing
egen sales_exmp_purch  = rowtotal(ventasexoneradasoce15 ventasexoneradasoce18 ventasexoneradaspn15), missing
egen sales_fyduca      = rowtotal(transfbienesfyduca15 transfbienesfyduca18 transfserviciosfyduca15 transfserviciosfyduca18), missing
egen sales_exports     = rowtotal(ventas_exentas_expor_12 ventas_exentas_expor_15 ventas_exentas_expor_18 ///
								  ventas_exentas_exp_fuera_ca_12 ventas_exentas_exp_fuera_ca_15 ventas_exentas_exp_fuera_ca_18), missing
egen sales_imports     = rowtotal(importgrav12 importgrav15 importgrav18 importregion12 importregion15 importregion18  ///
								  importacionesexentas12 importacionesexentas15 importacionesexentas18), missing							  
								  
** 1.3 MERGE BETWEEN CORPORATE AND SALES TAX RECORDS
merge 1:1 rtn year using "`cit_records'"
drop if _m == 1
drop _merge
tempfile tax_records
save "`tax_records'"
restore




**********************************************************************************
**********                   THIRD STEP: CUSTOMS RECORDS                 *********
**********************************************************************************

* Data on Exports (already in local currency - Lempiras)
preserve
use "$path\export.dta", replace
destring year, replace
keep if (year == 2017 | year == 2018)
bys rtn year: egen suma_export = sum(custom_export)
duplicates drop rtn year, force
drop custom_export 
rename suma_export custom_export
tempfile exports
save "`exports'"
restore

* Data on Imports (already in local currency - Lempiras)
preserve
use "$path\import.dta", replace
keep if regimen == "4000"
drop regimen
destring year, replace
keep if (year == 2017 | year == 2018)
bys rtn year: egen suma_import = sum(custom_import)
duplicates drop rtn year, force
drop custom_import 
rename suma_import custom_import
merge m:m rtn year using "`exports'"
drop _m
tempfile custom_records
save "`custom_records'"
restore




**********************************************************************************
**********              FOURTH STEP: SOCIAL SECURITY RECORDS             *********
**********************************************************************************

* Counting the total number of employees for each firm 
preserve 
use "$input\IHSS_2017_2018.dta", replace 
merge m:m NUMERO_PATRONAL using "$input\rtn_patrono.dta"
keep if _m == 3
drop _merge
egen ihss_n_workers = group(IDENTIDAD)
collapse (count) ihss_n_workers, by(rtn year)
tempfile social_security
save "`social_security'"
restore





**********************************************************************************
**********                   FIFTH STEP: IDENTIFYING MNC                 *********
**********************************************************************************

* MNC are pre-defined (before size restrictions) as companies reporting at least one transaction (between 2014-2021) 
* with another foreign counterpart under an ownership dependency
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




**********************************************************************************
**********                  SIXTH STEP: IDENTIFYING AGE                  *********
**********************************************************************************
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




**********************************************************************************
**********     			      SEVENTH STEP: LEGAL PROXY    			     *********
**********************************************************************************
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




**********************************************************************************
**********               EIGHTH STEP: MERGE ALL DATASETS                 *********
**********************************************************************************

use "`tax_records'", replace

merge 1:1 rtn year using "`custom_records'"
drop if _m == 2
drop _merge

foreach var of varlist custom_import custom_export sales_exports sales_imports {
	replace `var' = cond(missing(`var'), 0, `var')
}

* We assume the true value of exports/imports is the highest between the internal tax (in the sales tax form) and customs records
g final_exports = max(sales_exports, custom_export)
g final_imports = max(sales_imports, custom_import)

egen sales_total = rowtotal(sales_exempted sales_taxed sales_exmp_purch sales_fyduca final_exports), missing
egen sales_purch = rowtotal(comprasnetasmerc12 comprasnetasmerc15 comprasnetasmerc18 comprasexentasmerc12 comprasexentasmerc15 comprasexentasmerc18 ///
							comprasexoneradasoce15 comprasexoneradasoce18 adquisifyducagravadas15 adquisifyducagravadas18 ///
							adquisifyducaexeexo15 adquisifyducaexeexo18 final_imports), missing


* Merge with social security records
merge 1:1 rtn year using "`social_security'"
drop if _m == 2
drop _merge
jojojo

							
* Merge with data on MNC
merge m:1 rtn using "`mnc'", keepusing(foreign_ownership)
drop if _merge == 2
drop _merge
replace foreign_ownership = cond(missing(foreign_ownership), 0, foreign_ownership)
gen final_mnc = (foreign_ownership == 1 & ihss_n_workers >= 100)
label def final_mnc 1 "MNC" 0 "Not a MNC"
label val final_mnc final_mnc


* Merge with the age of the firm
merge m:m rtn using "`date'", keepusing(date_start)
drop if _merge == 2
drop _merge


* Merge with the legal proxy
merge m:m rtn using "`legal_proxy'", keepusing(legal_proxy)
keep if _merge == 3
drop _merge

duplicates drop rtn year, force

* Impute economic activities for final panel dataset and only keep corporations
*drop tipo_ot
merge m:1 rtn using "$input\Datos_Generales_AE_04_2022.dta", ///
	  keepusing(codigo clase codigoseccion seccion tipo_ot departamento municipio)
keep if _merge == 3
duplicates drop
drop _merge 
keep if tipo_ot == 1
drop tipo_ot

egen id = group(rtn)
duplicates tag id year, gen(isdup)
keep if isdup == 0
mvencode _all, mv(0) override
keep  id year codigo clase codigoseccion seccion departamento municipio ihss_n_workers cit_* sales_* custom_* final_* mnc date_start legal_proxy
order id year codigo clase codigoseccion seccion departamento municipio ihss_n_workers cit_* sales_* custom_* final_* mnc date_start legal_proxy
compress

*save "$out\final_dataset", replace
