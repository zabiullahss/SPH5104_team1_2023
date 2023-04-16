****Import all CSV files into DTA****

/*
//All datasets used in this code are as follows: 
//edstays
//medrecon
//patient (hospital)
//pyxis
//triage

cd "/Users/amyng/Desktop/Group Assignment Proposal/DTA"

clear
import delimited "/Users/amyng/Desktop/Group Assignment Proposal/CSV/edstays.csv"
save edstays.dta, replace

clear
import delimited "/Users/amyng/Desktop/Group Assignment Proposal/CSV/medrecon.csv"
save medrecon.dta, replace

clear
import delimited "/Users/amyng/Desktop/Group Assignment Proposal/CSV/patients.csv"
save patients.dta, replace

clear
import delimited "/Users/amyng/Desktop/Group Assignment Proposal/CSV/pyxis.csv"
save pyxis.dta, replace

clear
import delimited "/Users/amyng/Desktop/Group Assignment Proposal/CSV/triage.csv"
save triage.dta, replace
*/

*_______________________________________________________________________________

***Cleaning Population Numbers****

cd "/Users/amyng/Desktop/Group Assignment Proposal/DTA"

clear
set more off

log using "/Users/amyng/Desktop/Group Assignment Proposal/population.smcl", replace

use edstays.dta
//(425,087 obs)

sort subject_id stay_id

//keep first ED visit per patient
duplicates drop subject_id, force
//(219,583 observations deleted)

//merge with patient data 
merge 1:1 subject_id using patients.dta
drop if _merge == 2 
drop _merge

//Encode race into 4 main categories: Asian, Black, White, Hispanic/Latino, Others/Declined to answer
tab race
gen race_type = 1 if strpos(race, "WHITE")>0
replace race_type = 2 if strpos(race, "HISPANIC")>0
replace race_type = 2 if strpos(race, "LATINO")>0
replace race_type = 3 if strpos(race, "BLACK")>0
replace race_type = 4 if strpos(race, "ASIAN")>0
replace race_type = 5 if race_type == .

tab race if race_type == 1
tab race if race_type == 2
tab race if race_type == 3
tab race if race_type == 4
tab race if race_type == 5

label define race_label 1 "WHITE" 2 "HISPANIC/LATINO" 3 "BLACK" 4 "ASIAN" 5 "OTHERS"
label values race_type race_label

//encode disposition
encode disposition, gen(EDdischarge_type)
tab EDdischarge_type
tab EDdischarge_type, nolabel
drop disposition

gen Discharge_type = 1 if EDdischarge_type == 4
replace Discharge_type = 2 if EDdischarge_type == 1
replace Discharge_type = 3 if Discharge_type == .

label define discharge 1 "Home" 2 "Admitted" 3 "Others"
label values Discharge_type discharge

save population.dta, replace 

//merge with diagnosis data 
merge 1:m subject_id stay_id using diagnosis.dta
keep if _merge == 3
//only keep patients with diagnosis 
drop _merge

gen pregnant = 1 if strpos(icd_title, "preg")>0
replace pregnant = 1 if strpos(icd_title, "Preg")>0
replace pregnant = 1 if strpos(icd_title, "PREG")>0

keep if pregnant == 1 
keep subject_id 
duplicates drop subject_id, force

//remove pregnant people from population dataset
merge 1:1 subject_id using population.dta
keep if _merge == 2
drop _merge

//merge with triage dataset
merge 1:1 subject_id stay_id using triage.dta
drop if _merge == 2
drop _merge

//keep patients who presented with abdominal pain
gen abd_pain = 1 if strpos(chiefcomplaint, "abd pain")>0
replace abd_pain = 1 if strpos(chiefcomplaint, "ABD PAIN")>0
replace abd_pain = 1 if strpos(chiefcomplaint, "ABDOMINAL PAIN")>0
replace abd_pain = 1 if strpos(chiefcomplaint, "abdominal pain")>0

keep if abd_pain == 1 

//drop if patients chiefcomplaint is pregnant 
drop if strpos(chiefcomplaint, "PREG")>0
drop if strpos(chiefcomplaint, "Preg")>0
drop if strpos(chiefcomplaint, "preg")>0
drop if strpos(chiefcomplaint, "36WEEKS")>0
drop if strpos(chiefcomplaint, "POSITIVE UHCG")>0
drop if strpos(chiefcomplaint, "C SECTION")>0

//remove patients without valid pain score
gen scorevalid = 1 if pain == "1"
replace scorevalid = 1 if pain == "2"
replace scorevalid = 1 if pain == "3"
replace scorevalid = 1 if pain == "4"
replace scorevalid = 1 if pain == "5"
replace scorevalid = 1 if pain == "6"
replace scorevalid = 1 if pain == "7"
replace scorevalid = 1 if pain == "8"
replace scorevalid = 1 if pain == "9"
replace scorevalid = 1 if pain == "10"
replace scorevalid = 1 if pain == "0"

keep if scorevalid == 1 
drop scorevalid

//categorise arrival tranasport as numeric
encode arrival_transport, gen(arrival_transport2)
drop arrival_transport
rename arrival_transport2 arrival_transport
tab arrival_transport
tab arrival_transport, nolabel

gen arrive_type = 1 if arrival_transport == 5
replace arrive_type = 2 if arrival_transport == 1
replace arrive_type = 3 if arrive_type ==.

label define arrive 1 "Walk In" 2 "Ambulance" 3 "Unknown/Others"
label values arrive_type arrive

save population.dta, replace 

*_______________________________________________________________________________

***Clean Medication List***

//merge pyxis.csv to see painkiller prescription 
merge 1:m subject_id stay_id using pyxis.dta
drop if _merge == 2 
drop _merge
//Note that not all patients had medication prescription 

keep subject_id stay_id name charttime anchor_year anchor_year_group
tab name

//Note that opiods and non-opiod medications may be prescribed together (E.g. Acetaminophen with codeine)

gen Acetaminophen = 1 if strpos(name, "Acetamin")>0
replace Acetaminophen = 0 if Acetaminophen ==. 

gen Codeine = 1 if strpos(name, "Codeine")>0 
replace Codeine = 0 if Codeine ==. 

gen Aspirin = 1 if strpos(name, "Aspirin")>0 
replace Aspirin = 0 if Aspirin ==. 

gen Duloxetine = 1 if strpos(name, "DUL")>0
replace Duloxetine = 0 if Duloxetine ==. 

gen Gabapentin = 1 if strpos(name, "Gabapentin")>0 
replace Gabapentin = 0 if Gabapentin ==.

gen Ibuprofen = 1 if strpos(name, "Ibuprofen")>0
replace Ibuprofen = 0 if Ibuprofen ==. 

gen Lidocaine = 1 if strpos(name, "Lidocaine")>0
replace Lidocaine = 0 if Lidocaine ==. 

gen Naproxen = 1 if strpos(name, "Naproxen")>0
replace Naproxen = 0 if Naproxen ==. 

gen Pregabalin = 1 if strpos(name, "Pregabalin")>0
replace Pregabalin = 0 if Pregabalin ==.

gen Amitriptyline = 1 if strpos(name, "Amitriptyline")>0
replace Amitriptyline = 0 if Amitriptyline ==. 

gen non_opioid = max(Acetaminophen, Aspirin, Duloxetine, Gabapentin, Ibuprofen, Lidocaine, Naproxen, Pregabalin, Amitriptyline)

gen Oxycodone = 1 if strpos(name, "CODONE")>0
replace Oxycodone = 1 if strpos(name, "Oxycodone")>0
replace Oxycodone = 1 if strpos(name, "OxycoDONE")>0
replace Oxycodone = 0 if Oxycodone ==.

gen Hydromorphone = 1 if strpos(name, "morphone")>0
replace Hydromorphone = 0 if Hydromorphone ==.

gen Hydrocodone = 1 if strpos(name, "Hydrocodone")>0
replace Hydrocodone = 0 if Hydrocodone ==. 

gen Fentanyl = 1 if strpos(name, "Fentanyl")>0
replace Fentanyl = 0 if Fentanyl ==. 

gen Morphine = 1 if strpos(name, "Morphine")>0 
replace Morphine = 0 if Morphine ==. 

gen Methadone = 1 if strpos(name, "Methadone")>0 
replace Methadone = 0 if Methadone ==. 

gen Tramadol = 1 if strpos(name, "TraMADOL")>0 
replace Tramadol = 1 if strpos(name, "TraMADol")>0 
replace Tramadol = 0 if Tramadol ==. 

gen opioid = max(Oxycodone, Codeine, Hydrocodone, Hydromorphone, Fentanyl, Morphine, Methadone, Tramadol)

gen painkiller = 1 if opioid == 1 
replace painkiller = 1 if non_opioid == 1 
replace painkiller = 0 if painkiller ==. 

//check if missed out tagging on any medication
tab name if painkiller == 0 

//extract time medication was administered if painkillers were prescribed
gen double medtime = clock(charttime,"YMDhms",2200) if painkiller == 1 
format medtime %tc

//reformat to 1 subject 1 row dataset
collapse (max) opioid non_opioid painkiller Acetaminophen Aspirin Duloxetine Gabapentin Ibuprofen Lidocaine Naproxen Pregabalin Amitriptyline Oxycodone Codeine Hydrocodone Hydromorphone Fentanyl Morphine Methadone Tramadol (min) medtime, by(subject_id stay_id)

merge 1:1 subject_id stay_id using population.dta 
drop _merge

//create variable from time of ED admission to painkiller medication 
gen double EDadmit = clock(intime,"DMYhm",2200)
format EDadmit %tc

gen date_admit = date(intime, "DMYhm", 2200)
format date_admit %td
gen ED_year = year(date_admit)

gen yeardiff = ED_year - anchor_year
gen age = anchor_age + yeardiff

replace date_admit = date(intime, "DMYhm", 2300) if yeardiff < 0 
replace EDadmit = clock(intime, "DMYhm", 2300) if yeardiff < 0 
format EDadmit %tc
replace ED_year = year(date_admit) if yeardiff < 0 

drop age yeardiff

gen yeardiff = ED_year - anchor_year
gen age = anchor_age + yeardiff

//drop individuals aged younger than 18 
drop if age < 18

gen timetomed = medtime - EDadmit 

//timetomed format is in miliseconds, divide by 1000 to get in seconds
gen time_to_med = timetomed / 1000

//divde by 60 to get per minute
gen timetomed2 = time_to_med / 60 
tab timetomed2

//there is one outlier where timetomed is negative. drop this person
drop if timetomed2 < 0 
drop time_to_med timetomed

rename timetomed2 timetomed

//there is also another outlier where the time in minutes in medication is at 6000. drop this person
tab timetomed
drop if timetomed > 6000 & timetomed != .

//create variable for day of week based on ED admit date
gen Admit_dayofweek = dow(date_admit)
tab Admit_dayofweek

label define dayofweek 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
label values Admit_dayofweek dayofweek

tab Admit_dayofweek

//create variable for discharge date time 
gen double EDdischarge = clock(outtime, "DMYhm", 2200)
format EDdischarge %tc

gen date_discharge = date(outtime, "DMYhm", 2200)
format date_discharge %td
gen Discharge_year = year(date_discharge)

gen yeardiff2 = Discharge_year - anchor_year

tab yeardiff2

replace date_discharge = date(outtime, "DMYhm", 2300) if yeardiff2 < 0 
replace EDdischarge = clock(outtime, "DMYhm", 2300) if yeardiff2 < 0 
format EDdischarge %tc
replace Discharge_year = year(date_discharge) if yeardiff2 < 0 

drop yeardiff yeardiff2

//Create new variable medtodis (medication to discharge/IP admission)
gen medtodis0 = EDdischarge - medtime

//timetomed format is in miliseconds, divide by 1000 to get in seconds
gen medtodis1 = medtodis0/ 1000

//divde by 60 to get per minute
gen medtodis = medtodis1 / 60 
tab medtodis

//Drop extra variables
drop medtodis0 medtodis1 temperature heartrate resprate o2sat sbp dbp anchor_age anchor_year anchor_year_group abd_pain date_admit ED_year date_discharge Discharge_year

//Create variable for number of hours spent in ED_year
gen timeinED = EDdischarge - EDadmit
gen hoursinED = timeinED / 1000 / 60 / 60

//Drop gender-related complaints
gen gendercomplaint = 1 if strpos(upper(chiefcomplaint), "VAG")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "TESTIS")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "TESTICULAR")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "GROIN")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "PENI")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "EGG RETRIEVAL")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "IVF")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "BREAST")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "CRAMPS")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "GYN")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "SCROTAL")>0
replace gendercomplaint = 1 if strpos(upper(chiefcomplaint), "OVARIAN")>0

drop if gendercomplaint == 1
drop gendercomplaint 

//destring variables 
destring pain, replace 
gen female = 1 if gender == "F"
replace female = 0 if gender == "M"
tab female 

//drop unnecessary variables
drop EDdischarge_type arrival_transport intime outtime timeinED

rename EDadmit intime
rename EDdischarge outtime

//Export excel for base dataset
sort subject_id stay_id
order subject_id stay_id hadm_id age gender female race race_type dod arrive_type intime Admit_dayofweek outtime hoursinED chiefcomplaint pain acuity Discharge_type opioid non_opioid painkiller Acetaminophen Aspirin Duloxetine Gabapentin Ibuprofen Lidocaine Naproxen Pregabalin Amitriptyline Oxycodone Codeine Hydrocodone Hydromorphone Fentanyl Morphine Methadone Tramadol medtime timetomed medtodis

save base_data.dta, replace 

export excel using "/Users/amyng/Desktop/Group Assignment Proposal/Base Dataset (8 Apr 2023).xls", firstrow(variables) replace

*-------------------------------------------------------------------------------
***Propensity Score Matching***

clear

use base_data.dta 

//generate summary stats for Table 1

sum age if gender == "M"
sum age if gender == "F"

tab painkiller gender, col missing

sum timetomed gender if gender == "M"
sum timetomed gender if gender == "F"

tab race_type gender, col missing
tab acuity gender, col missing
tab pain gender, col missing

tab arrive_type gender , col missing
tab Discharge_type gender, col missing

sum hoursinED if gender == "M"
sum hoursinED if gender == "F"

tab Admit_dayofweek gender, col missing


*****BASELINE MODEL REGRESSION******

//Check which variables are significant for regression

logit painkiller female, or 

logit painkiller female i.race_type, or

logit painkiller female age, or

logit painkiller female i.acuity, or

logit painkiller female i.pain, or 

//don't put in day of week, not very significant
logit painkiller female i.Admit_dayofweek, or

logit painkiller female i.arrive_type, or

logit painkiller female i.Discharge_type, or

logit painkiller female hoursinED, or

reg timetomed female

reg timetomed female i.race_type

reg timetomed female age

reg timetomed female i.acuity

reg timetomed female i.pain

//don't put in day of week, not very significant
reg timetomed female i.Admit_dayofweek

reg timetomed female i.arrive_type

reg timetomed female i.Discharge_type

reg timetomed female hoursinED

//Simple Logistic Regression for Painkiller
logit painkiller female i.race_type age i.acuity i.pain i.Admit_dayofweek i.arrive_type i.Discharge_type hoursinED
//remove acuity because not significant

//Final Logistic Regression Equation for Painkiller
logit painkiller female i.race_type age i.pain i.arrive_type i.Discharge_type hoursinED

//Sub-group Opioid and Non-Opioid
logit opioid female i.race_type age i.pain i.arrive_type i.Discharge_type hoursinED
logit non_opioid female i.race_type age i.pain i.arrive_type i.Discharge_type hoursinED

//Simple Linear Regression for Time to Medication (only for those who received medication)
reg timetomed female i.race_type age i.acuity i.pain i.arrive_type i.Discharge_type hoursinED



*****Propensity Score Matching*****

//test which variables are significant in predicting whether the person is female

logit female i.race_type, or

logit female age, or

logit female i.acuity, or
//acuity is not predictive

logit female i.pain, or 

//logit female i.Admit_dayofweek, or
//omit in general

logit female i.arrive_type, or
//arrive type not significant

logit female i.Discharge_type, or

logit female hoursinED, or
//hoursinED not significant

//conduct propensity score matching: one-to-one matching for the variables of race, age, pain and dishcarge type for the outcome of painkiller

//psmatch for painkiler, nn = 1 
psmatch2 female age i.race_type i.pain i.Discharge_type, n(1) outcome(painkiller) logit ate
pstest  painkiller age i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//opioid, nn = 1
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(1) outcome(opioid)  logit  ate
pstest  opioid age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//non-opiod, nn = 1
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(1) outcome(non_opioid)  logit  ate
pstest  non_opioid age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//time to medication, nn = 1
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(1) outcome(timetomed)  logit  ate
pstest  timetomed age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//painkiller, nn = 3
psmatch2 female age i.race_type i.pain i.Discharge_type, n(3) outcome(painkiller) logit  ate
pstest  painkiller age i.race_type i.pain i.Discharge_type, both t(female) rub lab

//generate summary stats for Table 1 based on matched cohort of nn = 3
sum _n3

tab gender if _support == 1

sum age if gender == "M" & _support == 1 
sum age if gender == "F" & _support == 1 

tab painkiller gender if _support == 1, col missing

sum timetomed gender if gender == "M" & _support == 1
sum timetomed gender if gender == "F" & _support == 1

tab race_type gender if _support == 1 , col missing
tab acuity gender if _support == 1, col missing
tab pain gender if _support == 1, col missing

tab arrive_type gender if _support == 1, col missing
tab Discharge_type gender if _support == 1, col missing

sum hoursinED if gender == "M" & _support == 1
sum hoursinED if gender == "F" & _support == 1

tab Admit_dayofweek gender if _support == 1, col missing 

//opioid, nn = 3
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(3) outcome(opioid)  logit  ate
pstest  opioid age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//non-opioid, nn = 3
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(3) outcome(non_opioid)  logit  ate
pstest  non_opioid age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab

//time to medicaiton, nn = 3
psmatch2 female age  i.race_type   i.pain  i.Discharge_type , n(3) outcome(timetomed)  logit  ate
pstest  timetomed age   i.race_type  i.pain  i.Discharge_type , both t(female) rub lab



***TEFFECTS for PSM Model Results***

// for painkiller nn=1

teffects psmatch (painkiller) (female age i.race_type i.pain i.Discharge_type)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn1_PK.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn1_var_PK.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Painkiller Propensity score-NN1") name(ps_nn,replace) xsize(8)

graph export "combined_NN1_PK.png", as(png) replace


//opoid, nn = 1
teffects psmatch (opioid) (female age i.race_type i.pain i.Discharge_type)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn1_opiod.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn1_var_opiod.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Opiod Propensity score-NN1") name(ps_nn,replace) xsize(8)

graph export "combined_NN1_opiod.png", as(png) replace

//non-opiod, nn = 1
teffects psmatch (non_opioid) (female age i.race_type i.pain i.Discharge_type)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn1_non_opiod.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn1_var_non_opiod.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Non Opiod Propensity score-NN1") name(ps_nn,replace) xsize(8)

graph export "combined_NN1_non_opiod.png", as(png) replace

//timetomed, nn = 1 

teffects psmatch (timetomed) (female age i.race_type i.pain i.Discharge_type)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn1_timetomed.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn1_var_timetomed.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Time to Med Propensity score-NN1") name(ps_nn,replace) xsize(8)

graph export "combined_NN1_timetomed.png", as(png) replace


//painkiller, nn = 3
teffects psmatch (painkiller) (female age i.race_type i.pain i.Discharge_type),nn(3)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn3_PK.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn3_var_PK.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Painkiller Propensity score-NN3") name(ps_nn,replace) xsize(8)

graph export "combined_NN3_PK.png", as(png) replace


//opioid, nn = 3
teffects psmatch (opioid) (female age i.race_type i.pain i.Discharge_type),nn(3)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn3_opiod.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn3_var_opiod.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Opiod Propensity score-NN3") name(ps_nn,replace) xsize(8)

graph export "combined_NN3_opiod.png", as(png) replace


//non-opioid, nn = 3
teffects psmatch (non_opioid) (female age i.race_type i.pain i.Discharge_type), nn(3)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn3_non_opiod.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn3_var_non_opiod.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Non-opiod Propensity score-NN3") name(ps_nn,replace) xsize(8)

graph export "combined_NN3_non_opiod.png", as(png) replace

//timetomed, nn = 3

teffects psmatch (timetomed) (female age i.race_type i.pain i.Discharge_type), nn(3)
tebalance summarize

mat M = r(table)
coefplot matrix(M[,1]) matrix(M[,2]) , title ("Std. mean differences") noci  xlabel(-0.6(0.1)0.6,labsize(vsmall)) legend(off) ylabel(,labsize(tiny)) xline(0) xline(-0.1 0.1, lpattern(dash))  name(ps_logit_nn,replace) 
graph export "ps_logit_nn3_timetomed.png", as(png) replace

coefplot matrix(M[,3]) matrix(M[,4]) , noci  title("Variance ratios") legend(off) xlabel(0.2(0.1)1.8,labsize(vsmall))  name(ps_logit_nn_var,replace) ylabel(,labsize(tiny)) xline(1) xline(0.9 1.1, lpattern(dash)) 

graph export "ps_logit_nn3_var_timetomed.png", as(png) replace

graph combine  ps_logit_nn ps_logit_nn_var, col(2) title("Time to Med - Propensity score-NN3") name(ps_nn,replace) xsize(8)

graph export "combined_NN3_timetomed.png", as(png) replace


log close 



