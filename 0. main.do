/*
Description:   This do file replicates every result in the working paper 
			   "Firms' performance and tax incentives. Evidence from Honduras".
			   Data for replication is only available upon request to SAR.
Author: 	   Jose Carlo Bermúdez
Affilitation:  Servicio de Administración de Rentas (SAR), Honduras
Contact: 	   jbermudez@sar.gob.hn / bermudezjosecarlo@gmail.com
Final Version: Janurary, 2023
*/

clear all
clear matrix
set more off
cap prog drop _all

timer clear 1
timer on 1

* Packages required for estimations
global packs "winsor eststo estout reghdfe ftools erepost prodest binscatter wbopendata egenmore cdfplot"
foreach p of global packs {
	cap which `p'
	if (_rc) ssc install `p'
}

* Set up directories
if "`c(username)'" == "jbermudez" {
	global path		  "C:\Users\jbermudez\OneDrive - SAR"
	global datawork   "$path\Notas técnicas y papers\Profit Margins\preparacion inicial\base profit margins"
	global input 	  "$path\Bases del repositorio"
	global final_data "$path\Notas técnicas y papers\Profit Margins\database and codes"
	global codes 	  "$path\Firm-performance"
	global out 		  "$path\Notas técnicas y papers\Profit Margins\out"
}
else if "`c(username)'" == "Jose Carlo Bermúdez" {	
	global path		  "C:\Users\bermu\OneDrive - SAR"
	global datawork   "$path\Notas técnicas y papers\Profit Margins\preparacion inicial\base profit margins"
	global input 	  "$path\Bases del repositorio"
	global final_data "$path\Notas técnicas y papers\Profit Margins\database and codes"
	global codes 	  "C:\Users\bermu\Desktop\Firm-performance"
	global out 		  "$path\Notas técnicas y papers\Profit Margins\out"
}

* Globals for graphs visualization
global graphop "legend(region(lcolor(none))) graphr(color(white))"


************** Running Do Files for Replications **************

* Cleaning raw administrative records
qui {
run "$codes\1. raw_data_prep.do"
}

* Final sample set up
qui {
use "$final_data\final_dataset.dta", replace
run "$codes\2. setup.do"
}

* Replicating summary statistics and illustrations from final sample
qui {
run "$codes\3. descriptives.do"
}

* Replicating econometric results
qui {
run "$codes\4. estimates.do"
}

* Replicating illustrations from public data sources
qui {
run "$codes\5. context_graphs.do"
}

qui{
timer off 1
timer list 1
local minutes = round(`r(t1)'/60)
}
dis "The code took `minutes' minutes to be run"


