/*
Name: 0. main.do
Description: This do file replicates all tables and figures reported troughout the 
             paper Firms' performance and tax incentives: evidence from Honduras.
*/

clear all

* Set up directories
if "`c(username)'" == "Owner" {
	global codes "C:\Users\Owner\Desktop\Firm-performance"
}
else if "`c(username)'" == "jbermudez" {
	global codes "C:\Users\jbermudez\OneDrive - SAR\Firm-performance"	
}

* Running do files
