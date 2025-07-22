* ------------------------------------------------------------------------------------------------ *
*                                  RST 2025 Version Control                                        *
*                                                                                                  *
* This code duplicated from the coding best practices session. Follow the steps in the             *
* instructions to complete the exercise.                                                           *
*                                                                                                  *
* ------------------------------------------------------------------------------------------------ *

clear all
set more off

*Check to see that id uniquely identifies observations in all pulls and that IDs are in the same format.
foreach pull in pull1 pull2 pull3 {
  use ../data/`pull'.dta, clear
  *Format of ID variable?
  display as text "Dataset `pull' ID format:"
  describe id //tells you the format of the variable
  *Does ID uniquely identify observations in pull?
  capture isid id
  if _rc != 0 {
    display in red "DUPLICATE IDS EXIST IN DATASET `pull'. THE FOLLOWING HAVE A NON-UNIQUE ID:"
    bysort id: gen duplicate_id = _N
    list id Q1 Q2 Q3* if duplicate_id > 1
    *If the ID does not uniquely identify observations in pull, check to see if a combination of ID and name do.
    capture isid id Q1 Q2
    if _rc != 0 {
      display in red "ID, first and last name DO NOT uniquely identify observations in `pull'."
    }
    else {
      display as text "ID, first and last name uniquely identify observations in `pull'."
    }
  }
  else {
    display as text "No duplicate IDs exist in `pull'."
  }   
}

*Append the three pulls together. 
append using ../data/pull1.dta
append using ../data/pull3.dta
sort id Q1 Q2 pull
save ../data/allpulls.dta, replace


*Verify we have appropriate follow-up information on the people is consistent. (example code for reference, no adjustment required)

*Make sure everyone in pulls 1 and 2 appear exactly twice
bys id Q1 Q2: gen multiple_pulls = _N
cap assert multiple_pulls == 2 if pull == 1 | pull == 2
if _rc != 0 {
  display in red "Some people did not have a follow up recorded in data. See the following:"
  list id Q1 Q2 pull if multiple_pulls == 1 & (pull == 1 | pull == 2)
}
else {
  display as text "Follow up visits recorded for all expected individuals."
}

*Make sure the visits were in consecutive quarters/pulls.
quietly by id Q1 Q2: gen nonconsecutive_pulls = pull[2] != (pull[1] + 1) if multiple_pulls == 2
cap assert nonconsecutive_pulls == 0 if multiple_pulls == 2
if _rc != 0 {
  display in red "Some people did not have a CONSECUTIVE follow up recorded in data. See the following:"
  list id Q1 Q2 pull if nonconsecutive_pulls == 1
}
else {
  display as text "Follow up visits recorded consecutively for all expected individuals."
}

*Make sure information is consistent between the two pulls for consecutive pulls.
foreach var of varlist Q5 Q3* region* treat Q4 {
  quietly by id Q1 Q2: gen `var'_inconsistency = `var'[1] != `var'[2] if multiple_pulls != 1
  cap assert `var'_inconsistency == 0 | missing(`var'_inconsistency)
  if _rc != 0 {
    display in red "The variable `var' is not consistent across pulls for the following people:"
    list id Q1 Q2 `var' if  `var'_inconsistency == 1
  }
  else {
    display as text "The variable `var' is consistent across pulls."
  }
  drop `var'_inconsistency
}
*It seems like there are a few quality issues with our data. 
  **Some seem to be due to typos and others look like the provider changed how they coded key variables.

****************************************************************************************************
****************************************DATA CLEANING***********************************************
****************************************************************************************************

*STEP A -- Rename and label variables as necessary (refer to the code book)



*STEP B -- For the missing application dates that don't need an answer, recode them as "N/A" (".n"). 
          *For the missing application dates that should be there, recode them as "don't know" (".d")
          
