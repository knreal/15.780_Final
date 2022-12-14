clear all
log using Airline_DataCleaning_and_Analysis.log, replace
ssc install randomtag

*cd "/Users/eileenliu/Documents"
import delimited "Aircraft_Type.csv"
rename v2 flight
rename v3 aircraft
drop if v1==.
save aircraft, replace
clear
import delimited "Clean_Dataset.csv"
isid v1
set seed 4732321


merge m:m flight using "aircraft.dta"
rename aircraft Aircraft
drop if Aircraft == ""
gen capacity = 188 if Aircraft == "737"
replace capacity = 194 if Aircraft == "A20N"
replace capacity = 180 if Aircraft == "A320"
replace capacity = 220 if Aircraft == "A321"
replace capacity = 74 if Aircraft == "AT43"
replace capacity = 74 if Aircraft == "ATR"
replace capacity = 210 if Aircraft == "B38M"
replace capacity = 169 if Aircraft == "B738"
gen business_capacity = 16 if Aircraft == "B738"
gen economy_capacity = 153 if Aircraft == "B738"
replace capacity = 342 if Aircraft == "B77W"
replace business_capacity = 39 if Aircraft == "B77W"
replace economy_capacity = 303 if Aircraft == "B77W"
replace capacity = 256 if Aircraft == "B788"
replace business_capacity = 18 if Aircraft == "B788"
replace economy_capacity = 238 if Aircraft == "B788"
replace capacity = 78 if Aircraft == "DH8B"
replace economy_capacity = capacity if economy_capacity == .




gen class_dummy = class == "Business"
*
*sort airline
*by airline: summarize price
*by airline: summarize class

*Only Air India and Vistara have business classes 

*gen dummies for airlines 
gen airasia = airline == "AirAsia"
gen airindia = airline == "Air_India"
gen gofirst = airline == "GO_FIRST"
gen indigo = airline == "Indigo"
gen spicejet = airline == "SpiceJet"
gen vistara = airline == "Vistara"

replace stops = "1" if stops =="one"
replace stops = "0" if stops =="zero"
replace stops = "2" if stops =="two_or_more"
destring stops, replace ignore(" ")


gen source_bangalore = source_city == "Bangalore"
gen source_chennai = source_city == "Chennai"
gen source_delhi = source_city == "Delhi"
gen source_hyperabad = source_city == "Hyderabad"
gen source_kolkata = source_city == "Kolkata"
gen source_mumbai = source_city == "Mumbai"

gen destination_bangalore = destination_city == "Bangalore"
gen destination_chennai = destination_city == "Chennai"
gen destination_delhi = destination_city == "Delhi"
gen destination_hyperabad = destination_city == "Hyderabad"
gen destination_kolkata = destination_city == "Kolkata"
gen destination_mumbai = destination_city == "Mumbai"

gen depart_after = departure_time == "Afternoon"
gen depart_early = departure_time == "Early_Morning"
gen depart_even = departure_time == "Evening"
gen depart_late = departure_time == "Late_Night"
gen depart_morn = departure_time == "Morning"
gen depart_night = departure_time == "Night"

gen arr_after = arrival_time == "Afternoon"
gen arr_early = arrival_time == "Early_Morning"
gen arr_even = arrival_time == "Evening"
gen arr_late = arrival_time == "Late_Night"
gen arr_morn = arrival_time == "Morning"
gen arr_night = arrival_time == "Night"

gen sourcedestination = source_city+destination_city
egen total = count(sourcedestination) 
bysort sourcedestination: egen type = count(sourcedestination)
gen competition = type/total

gen days_left_squared = days_left^2
gen days_left_cubed = days_left^3

gen duration2 = string(duration)
gen stops2 = string(stops)

gen id = flight + sourcedestination+duration2+class+arrival_time+departure_time+stops2

sort id days_left 

by id, sort: gen blarg = _n==1

preserve
contract id
save "flight_freq.dta", replace
restore

drop _merge
merge m:m id using "flight_freq.dta"


collapse price, by(airline flight source_city departure_time stops arrival_time destination_city class duration days_left Aircraft capacity business_capacity economy_capacity class_dummy airasia airindia gofirst indigo spicejet vistara source_bangalore source_chennai source_delhi source_hyperabad source_kolkata source_mumbai destination_bangalore destination_chennai destination_delhi destination_hyperabad destination_kolkata destination_mumbai depart_after depart_early depart_even depart_late depart_morn depart_night arr_after arr_early arr_even arr_late arr_morn arr_night sourcedestination total type competition days_left_squared days_left_cubed id blarg _freq)


by id, sort: gen blarg2 = _n==1

drop _freq
preserve
contract id
save "flight_freq2.dta", replace
restore

merge m:m id using "flight_freq2.dta"


drop if _freq<31

save "averaged_data.dta", replace


*********************
********TRain by flight
**********************
*Delhi/Mumbai
clear 
use "averaged_data.dta"
set seed 4732321
ssc inst unique
keep if sourcedestination == "DelhiMumbai"|sourcedestination == "MumbaiDelhi"
drop _merge

save delhimumbai.tmp, replace

unique id

by id, sort: gen id2 = _n==1



keep if id2==1
randomtag, count(374) gen(train_noclass)
save delhimumbaiunique.tmp, replace


use delhimumbai.tmp


merge m:m id using delhimumbaiunique.tmp
drop _merge



eststo Mumbai_Delhi: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn capacity class_dummy if train_noclass==1

esttab Mumbai_Delhi using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi Linear Regression, not cleaned data, by flight
summarize ape

**********************
*Delhi/Bangalore
clear 
use "averaged_data.dta"
set seed 4732321
ssc inst unique
keep if sourcedestination == "DelhiBangalore"|sourcedestination == "BangaloreDelhi"
drop _merge

save delhibangalore.tmp, replace

unique id

by id, sort: gen id2 = _n==1



keep if id2==1
randomtag, count(324) gen(train_noclass)
save delhibangaloreunique.tmp, replace


use delhibangalore.tmp


merge m:m id using delhibangaloreunique.tmp
drop _merge



eststo Bangalore_Delhi: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn   capacity class_dummy if train_noclass==1

esttab Bangalore_Delhi using "Bangalore_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi Linear Regression, not cleaned data, by flight
summarize ape

**********************
*Mumbai/Bangalore
clear 
use "averaged_data.dta"
set seed 4732321
ssc inst unique
keep if sourcedestination == "MumbaiBangalore"|sourcedestination == "BangaloreMumbai"
drop _merge

save mumbaibangalore.tmp, replace

unique id

by id, sort: gen id2 = _n==1



keep if id2==1
randomtag, count(314) gen(train_noclass)
save mumbaibangaloreunique.tmp, replace


use mumbaibangalore.tmp


merge m:m id using mumbaibangaloreunique.tmp
drop _merge



eststo Mumbai_Delhi: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn   capacity class_dummy if train_noclass==1

esttab Mumbai_Delhi using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore Linear Regression, not cleaned data, by flight
summarize ape



****************************
*Train  by observation
****************************
*Delhi/Mumbai
clear 
use "averaged_data.dta"
set seed 9879879
ssc inst unique
keep if sourcedestination == "DelhiMumbai"|sourcedestination == "MumbaiDelhi"
drop _merge

count

randomtag, count(15488) gen(train_noclass)


eststo Mumbai_Delhi2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn  capacity class_dummy if train_noclass==1

*esttab Mumbai_Delhi2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi Linear Regression, not cleaned data
summarize ape
************************
*Delhi/Bangalore
clear 
use "averaged_data.dta"
set seed 9879879
ssc inst unique
keep if sourcedestination == "DelhiBangalore"|sourcedestination == "BangaloreDelhi"
drop _merge

count

randomtag, count(13521) gen(train_noclass)


eststo Bangalore_Delhi2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1

*esttab Bangalore_Delhi2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi Linear Regression, not cleaned data
summarize ape


************************
*Mumbai/Bangalore
clear 
use "averaged_data.dta"
set seed 9879879
ssc inst unique
keep if sourcedestination == "MumbaiBangalore"|sourcedestination == "BangaloreMumbai"
drop _merge

count

randomtag, count(13098) gen(train_noclass)


eststo Bangalore_Mumbai2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1

*esttab Bangalore_Mumbai2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore Linear Regression, not cleaned data
summarize ape


***************************************
*CART
***************************************
*Delhi and Mumbai 
clear 
use "averaged_data.dta"
set seed 28492234
ssc inst unique
keep if sourcedestination == "DelhiMumbai"|sourcedestination == "MumbaiDelhi"
drop _merge

count

randomtag, count(15488) gen(train_noclass)

crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

*esttab Mumbai_Delhi2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi CART, not cleaned data
summarize ape


**************************
*Delhi/Bangalore
clear 
use "averaged_data.dta"
set seed 28492234
ssc inst unique
keep if sourcedestination == "DelhiBangalore"|sourcedestination == "BangaloreDelhi"
drop _merge

count

randomtag, count(13521) gen(train_noclass)

crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

*esttab Bangalore_Delhi2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi CART, not cleaned data
summarize ape


************************
*Mumbai/Bangalore
clear 
use "averaged_data.dta"
set seed 28492234
ssc inst unique
keep if sourcedestination == "MumbaiBangalore"|sourcedestination == "BangaloreMumbai"
drop _merge

count

randomtag, count(13098) gen(train_noclass)


crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

*esttab Bangalore_Mumbai2 using "Mumbai_Delhi_Regression.tex", p replace r2 label 

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore CART, not cleaned data
summarize ape












***************************************************
*Remove outliers*
***************************************************
*Delhi Mumbai
clear
use "averaged_data.dta"
set seed 739292
ssc inst unique
keep if sourcedestination == "MumbaiDelhi"|sourcedestination == "DelhiMumbai"
drop _merge


******Economy*******
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==0
histogram price if days_left<=50 & days_left>=41 & class_dummy ==0, width(500)
*histogram price if days_left<=50 & days_left>=41 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2450 & days_left<=50 & days_left>=41 & class_dummy ==0
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==0
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==0
histogram price if days_left<=40 & days_left>=31 & class_dummy ==0, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2500 & days_left<=40 & days_left>=31 & class_dummy ==0
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==0
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==0
histogram price if days_left<=30 & days_left>=21 & class_dummy ==0, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2500 & days_left<=30 & days_left>=21 & class_dummy ==0
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==0
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==0
histogram price if days_left<=20 & days_left>=11 & class_dummy ==0, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2500 & days_left<=20 & days_left>=11 & class_dummy ==0
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==0
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==0
histogram price if days_left<=10 & days_left>=1 & class_dummy ==0, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==0 & price<=10000, width(100)
drop if price <=6100 & days_left<=10 & days_left>=1 & class_dummy ==0
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==0
drop p25
drop p75


******Buiness*******
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==1
histogram price if days_left<=50 & days_left>=41 & class_dummy ==1, width(500)
*histogram price if days_left<=50 & days_left>=41 & class_dummy ==1 & price<=30000, width(100)
drop if price <=24000 & days_left<=50 & days_left>=41 & class_dummy ==1
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==1
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==1
histogram price if days_left<=40 & days_left>=31 & class_dummy ==1, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==1 & price<=30000, width(100)
drop if price <=24000 & days_left<=40 & days_left>=31 & class_dummy ==1
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==1
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==1
histogram price if days_left<=30 & days_left>=21 & class_dummy ==1, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==1& price<=30000, width(100)
drop if price <=24000 & days_left<=30 & days_left>=21 & class_dummy ==1
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==1
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==1
histogram price if days_left<=20 & days_left>=11 & class_dummy ==1, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==1 & price<=5000, width(100)
drop if price <=24000 & days_left<=20 & days_left>=11 & class_dummy ==1
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==1
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==1
histogram price if days_left<=10 & days_left>=1 & class_dummy ==1, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==1 & price<=30000, width(100)
drop if price <=24000 & days_left<=10 & days_left>=1 & class_dummy ==1
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==1
drop p25
drop p75



count 

randomtag, count(11985) gen(train_noclass)

eststo Delhi_Mumbai2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi Linear Regression, cleaned data
summarize ape
save "delmumbaiclean.dta", replace

***************************************************
*Delhi Bangalore
clear
use "averaged_data.dta"
set seed 739292
ssc inst unique
keep if sourcedestination == "BangaloreDelhi"|sourcedestination == "DelhiBangalore"
drop _merge


******Economy*******
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==0
histogram price if days_left<=50 & days_left>=41 & class_dummy ==0, width(500)
*histogram price if days_left<=50 & days_left>=41 & class_dummy ==0 & price<=5000, width(100)
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==0
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==0
histogram price if days_left<=40 & days_left>=31 & class_dummy ==0, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==0 & price<=5000, width(100)
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==0
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==0
histogram price if days_left<=30 & days_left>=21 & class_dummy ==0, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==0 & price<=5000, width(100)
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==0
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==0
histogram price if days_left<=20 & days_left>=11 & class_dummy ==0, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2500 & days_left<=20 & days_left>=11 & class_dummy ==0
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==0
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==0
histogram price if days_left<=10 & days_left>=1 & class_dummy ==0, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==0 & price<=10000, width(100)
drop if price <=7500 & days_left<=10 & days_left>=1 & class_dummy ==0
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==0
drop p25
drop p75


******Buiness*******
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==1
histogram price if days_left<=50 & days_left>=41 & class_dummy ==1, width(500)
*histogram price if days_left<=50 & days_left>=41 & class_dummy ==1 & price<=50000, width(100)
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==1
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==1
histogram price if days_left<=40 & days_left>=31 & class_dummy ==1, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==1 & price<=30000, width(100)
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==1
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==1
histogram price if days_left<=30 & days_left>=21 & class_dummy ==1, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==1& price<=30000, width(100)
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==1
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==1
histogram price if days_left<=20 & days_left>=11 & class_dummy ==1, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==1 & price<=5000, width(100)
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==1
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==1
histogram price if days_left<=10 & days_left>=1 & class_dummy ==1, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==1 & price<=30000, width(100)
drop if price <=33000 & days_left<=10 & days_left>=1 & class_dummy ==1
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==1
drop p25
drop p75



count 

randomtag, count(12327) gen(train_noclass)

eststo Delhi_Bangalore2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi Linear Regression, cleaned data
summarize ape
save "delbangclean.dta", replace


***************************************************
*Mumbai Bangalore
clear
use "averaged_data.dta"
set seed 739292
ssc inst unique
keep if sourcedestination == "MumbaiBangalore"|sourcedestination == "BangaloreMumbai"
drop _merge

********Econ*****
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==0
histogram price if days_left<=50 & days_left>=41 & class_dummy ==0, width(500)
drop if price <=2200 & days_left<=50 & days_left>=41 & class_dummy ==0
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==0
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==0
histogram price if days_left<=40 & days_left>=31 & class_dummy ==0, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2300 & days_left<=40 & days_left>=31 & class_dummy ==0
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==0
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==0
histogram price if days_left<=30 & days_left>=21 & class_dummy ==0, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2300 & days_left<=30 & days_left>=21 & class_dummy ==0
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==0
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==0
histogram price if days_left<=20 & days_left>=11 & class_dummy ==0, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==0 & price<=5000, width(100)
drop if price <=2300 & days_left<=20 & days_left>=11 & class_dummy ==0
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==0
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==0
histogram price if days_left<=10 & days_left>=1 & class_dummy ==0, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==0 & price<=10000, width(100)
drop if price <=5200 & days_left<=10 & days_left>=1 & class_dummy ==0
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==0, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==0, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==0
drop p25
drop p75


******Buiness*******
*50-41
graph hbox price if days_left<=50 & days_left>=41 & class_dummy ==1
histogram price if days_left<=50 & days_left>=41 & class_dummy ==1, width(500)
*histogram price if days_left<=50 & days_left>=41 & class_dummy ==1 & price<=30000, width(100)
drop if price <=21000 & days_left<=50 & days_left>=41 & class_dummy ==1
tabstat price if days_left<=50 & days_left>=41 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=50 & days_left>=41 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=50 & days_left>=41 & class_dummy ==1
drop p25
drop p75

*40-31
graph hbox price if days_left<=40 & days_left>=31 & class_dummy ==1
histogram price if days_left<=40 & days_left>=31 & class_dummy ==1, width(500)
*histogram price if days_left<=40 & days_left>=31 & class_dummy ==1 & price<=40000, width(100)
drop if price <=25000 & days_left<=40 & days_left>=31 & class_dummy ==1
tabstat price if days_left<=40 & days_left>=31 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=40 & days_left>=31 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=40 & days_left>=31 & class_dummy ==1
drop p25
drop p75


*30-21
graph hbox price if days_left<=30 & days_left>=21 & class_dummy ==1
histogram price if days_left<=30 & days_left>=21 & class_dummy ==1, width(500)
*histogram price if days_left<=30 & days_left>=21 & class_dummy ==1& price<=30000, width(100)
drop if price <=21000 & days_left<=30 & days_left>=21 & class_dummy ==1
tabstat price if days_left<=30 & days_left>=21 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=30 & days_left>=21 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=30 & days_left>=21 & class_dummy ==1
drop p25
drop p75

*20-11
graph hbox price if days_left<=20 & days_left>=11 & class_dummy ==1
histogram price if days_left<=20 & days_left>=11 & class_dummy ==1, width(500)
*histogram price if days_left<=20 & days_left>=11 & class_dummy ==1 & price<=30000, width(100)
drop if price <=21000 & days_left<=20 & days_left>=11 & class_dummy ==1
tabstat price if days_left<=20 & days_left>=11 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=20 & days_left>=11 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=20 & days_left>=11 & class_dummy ==1
drop p25
drop p75

*10-1
graph hbox price if days_left<=10 & days_left>=1 & class_dummy ==1
histogram price if days_left<=10 & days_left>=1 & class_dummy ==1, width(500)
*histogram price if days_left<=10 & days_left>=1 & class_dummy ==1 & price<=30000, width(100)
drop if price <=21000 & days_left<=10 & days_left>=1 & class_dummy ==1
tabstat price if days_left<=10 & days_left>=1 & class_dummy ==1, statistics(mean p25 p75)
egen p25 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(25)
egen p75 = pctile(price) if days_left<=10 & days_left>=1 & class_dummy ==1, p(75)
drop if (price>= p75+1.5*(p75-p25)|price<= p25-1.5*(p75-p25)) & days_left<=10 & days_left>=1 & class_dummy ==1
drop p25
drop p75


count 

randomtag, count(10789) gen(train_noclass)

eststo Bangalore_Mumbai2: regress price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore Linear Regression, cleaned data
summarize ape

save "bangmumbaiclean.dta", replace





****************
*CART on clean data
****************
*Delhi/Mumbai
clear
use "delmumbaiclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 12322

count 

randomtag, count(11985) gen(train_noclass)

crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi CART, cleaned data
summarize ape

****************
*Delhi/Bangalore
clear
use "delbangclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 12322

count 

randomtag, count(12327) gen(train_noclass)

crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi CART, cleaned data
summarize ape


****************
*Mumbai/Bangalore
clear
use "bangmumbaiclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 12322

count 

randomtag, count(10789) gen(train_noclass)

crtrees price class_dummy duration days_left stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity if train_noclass==1, stop(50) generate(predicted) seed(123) rule(2)

predict pred_price  if  train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore CART, cleaned data
summarize ape







*********************************
*Random Forest
********************************
*********CLEAN*********************
*Dellhi Mumbai
clear
ssc install rforest
use "delmumbaiclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 275643

count 
randomtag, count(12327) gen(train_noclass)

rforest price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1, type(reg) iter(500)

predict pred_price if train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Delhi Random Forest, cleaned data
summarize ape



*******************
*Dellhi Bangalore
clear
ssc install rforest
use "delbangclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 275643

count 
randomtag, count(11985) gen(train_noclass)

rforest price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1, type(reg) iter(500)

predict pred_price if train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Bangalore Delhi Random Forest, cleaned data
summarize ape

******************************
*Bangalore Mumbai
clear
ssc install rforest
use "bangmumbaiclean.dta"
drop train_noclass
drop pred_price
drop error
drop error_square
drop ape
set seed 275643

count 
randomtag, count(10789) gen(train_noclass)

rforest price duration days_left days_left_squared days_left_cubed stops depart_after depart_early depart_even depart_late depart_morn arr_after arr_early arr_even arr_late arr_morn    capacity class_dummy if train_noclass==1, type(reg) iter(500)

predict pred_price if train_noclass==0
gen error = pred_price-price
gen error_square = error^2
gen ape = abs(error/price)
*MSE
summarize error_square
*Mumbai Bangalore Random Forest, cleaned data
summarize ape

log close
