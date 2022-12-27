/*
Name: 0. main.do
Description: This do file replicates all tables and figures reported troughout the 
             paper Firms' performance and tax incentives: evidence from Honduras.
*/

clear all

* Set up directories
if "`c(username)'" == "Jose Carlo Bermúdez" {
	global codes "C:\Users\Owner\Desktop\Firm-performance"
}
else if "`c(username)'" == "jbermudez" {
	global codes "C:\Users\jbermudez\OneDrive - SAR\Firm-performance"	
}

/* Packages required for estimations
ssc install winsor
ssc install eststo
ssc install estout
ssc install reghdfe
ssc install ftools
ssc install erepost
ssc install prodest
ssc install binscatter
ssc install wbopendata
ssc install egenmore
ssc install cdfplot
*/

* Running do files
