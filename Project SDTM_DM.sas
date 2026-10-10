
/*
===============================================================================
CLINICAL PROJECT — SDTM DEMOGRAPHICS (DM) DATASET
===============================================================================

PROJECT OBJECTIVE

Create the SDTM DM dataset based on the SDTM specification file
(dm_only.xlsx).

The project uses Clinical Data Management (CDM) data sets to populate the
required demographic variables, reference dates, treatment information,
subject identifiers, and other clinical trial information.

The overall workflow combines SAS DATA steps and PROC SQL operations to
progressively construct the SDTM DM dataset.

The process covers:

    - importing the clinical data files;
    - establishing study and subject identifiers;
    - deriving subject reference start and end dates;
    - assigning treatment reference dates;
    - incorporating participation and death information;
    - populating demographic variables;
    - applying the specified demographic values and arm codes;
    - assembling the final SDTM DM dataset; and
    - exporting the dataset in Excel format.

ABOUT THE DATA

The CDM data sets capture data recorded on Case Report Forms (CRF) during
the clinical trial, either by hand or electronically.

The cleansed information from the forms is converted into CDM data sets
and used to populate the SDTM DM variables.

The five principal CDM data sets are:

    DEATH
    DM
    DS
    EX
    SPCPKB1

The program also imports CDM.xlsx.

The SDTM specification file (dm_only.xlsx) defines the variables
required for the DM dataset.

WORKFLOW STRUCTURE

    Dataset Import
        |
        v
    SDTM_DM1    Study and Subject Identifiers
        |
        v
    Concatenate Reference Start Date/Time
        |
        v
    SDTM_DM2    Subject Reference Start Date/Time
        |
        v
    SDTM_DM3    Subject Reference End Date/Time
        |
        v
    SDTM_DM4    Treatment Reference Dates
        |
        v
    SDTM_DM5    Participation and Death Dates
        |
        v
    SDTM_DM6    Subject Death Flag
        |
        v
    SDTM_DM7    Demographic Variables
        |
        v
    SDTM_DM8    Ethnicity Variable Setup
        |
        v
    SDTM_DM9    Demographic Values and Planned Arm Code
        |
        v
    SDTM_DM10   Actual Arm Code
        |
        v
    Clinical.SDTM_DM
        |
        v
    SDTM_DM.xlsx

SCOPE

The program focuses on constructing the SDTM DM dataset from the
available clinical data and the variable requirements described in the
SDTM specification.

The transformation sequence is retained in its original form.
*/


/*
===============================================================================
STAGE 1 — IMPORT THE CLINICAL DATA FILES
===============================================================================

OBSERVATION

The source information is distributed across the CDM, DEATH, DM, DS,
EX, and SPCPKB1 Excel files.

These files provide the clinical observations used throughout the
demographic dataset construction.

APPROACH

PROC IMPORT is used to read the Excel files and assign them to the
specified SAS libraries.

The imported datasets establish the source tables used in the
subsequent DATA steps and PROC SQL joins.

The original file paths, library assignments, and import statements
are preserved.
*/

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/CDM.xlsx"
              dbms=xlsx
              out= SDTM.CDM;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/DEATH.xlsx"
              dbms=xlsx
              out= SDTM.DEATH;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/DM.xlsx"
              dbms=xlsx
              out= CLINICAL.DM;
run;

proc import datafile="//home/u63696516/EPG1V2/PSDTM_DM/DS.xlsx"
              dbms=xlsx
              out= SDTM.DS;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/EX.xlsx"
              dbms=xlsx
              out= SDTM.EX;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/SPCPKB1.xlsx"
              dbms=xlsx
              out= SDTM.SPCPKB1;
run;


/*
===============================================================================
STAGE 2 — ESTABLISH STUDY AND SUBJECT IDENTIFIERS
===============================================================================

2.1 — Create the Initial SDTM DM Dataset

OBSERVATION

The DM data file contains the subject-level information needed to
establish the identifying variables for the SDTM DM dataset.

The initial dataset requires the study identifier, domain abbreviation,
unique subject identifier, and subject identifier.

APPROACH

The DATA step reads CLINICAL.DM and assigns the following variables:

    STUDYID
        Assigned the study identifier "XYZ".

    DOMAIN
        Assigned the domain abbreviation "DM".

    USUBJID
        Constructed by concatenating STUDYID and SUBJECT with "/"
        as the separator.

    SUBJID
        Assigned from SUBJECT.

CATX is used to construct the unique subject identifier.

The KEEP statement is retained exactly as implemented.

OUTPUT

    SDTM_DM1

This dataset serves as the starting point for the subsequent
subject-level transformations.
*/

DATA SDTM_DM1;
  SET CLINICAL.DM;
    STUDYID = 'XYZ';
    DOMAIN = 'DM';
    USUBJID  = CATX('/', STUDYID, SUBJECT);
    SUBJID = SUBJECT;
  KEEP Studyid Domain Userid Subjid;
RUN;


/*
===============================================================================
STAGE 3 — DERIVE SUBJECT REFERENCE START DATE/TIME
===============================================================================

3.1 — Prepare the SPCPKB1 Reference Information

OBSERVATION

The SPCPKB1 data file contains the IPFD1DAT, IPFD1TIM, PSCHDAY, PART,
and SUBJECT information used to establish the subject reference
start date/time.

The required records are identified using:

    PSCHDAY = 1
    PART = "A"

APPROACH

A temporary dataset named Concatenate is created from
CLINICAL.SPCPKB1.

The WHERE statement restricts the source observations to the
specified study day and part.

CATX combines IPFD1DAT and IPFD1TIM into RFSTDTC, separated by a
space.

OUTPUT

    Concatenate

The dataset contains the reference information used in the next
subject-level join.
*/

DATA Concatenate;
  SET CLINICAL.SPCPKB1;
   RFSTDTC = CATX(" ", IPFD1DAT, IPFD1TIM);
  WHERE PSCHDAY = 1
  AND PART = "A";
RUN;


/*
3.2 — Join the Reference Start Date/Time to SDTM_DM1

OBSERVATION

The initial demographic dataset and the prepared SPCPKB1 reference
information share the subject identifier.

This relationship is used to associate RFSTDTC with the
corresponding subject.

APPROACH

PROC SQL creates SDTM_DM2 by joining SDTM_DM1 to Concatenate.

JOIN CONDITION

    SDTM_DM1.SUBJID = Concatenate.SUBJECT

A LEFT JOIN is used, followed by the existing condition:

    RFSTDTC IS NOT NULL

The resulting table selects the identifying variables and RFSTDTC.

OUTPUT

    SDTM_DM2

The next stage uses this dataset to assign the subject reference
end date/time.
*/

PROC SQL;
CREATE TABLE SDTM_DM2 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC
FROM SDTM_DM1
  LEFT JOIN Concatenate
    ON SDTM_DM1.SUBJID = Concatenate.SUBJECT
WHERE RFSTDTC IS NOT NULL;
QUIT;


/*
===============================================================================
STAGE 4 — ASSIGN SUBJECT REFERENCE END DATE/TIME
===============================================================================

4.1 — Incorporate EXENDAT from the EX Dataset

OBSERVATION

The EX data file provides EXENDAT, which is used to populate the
subject reference end date/time variable.

APPROACH

PROC SQL joins SDTM_DM2 to CLINICAL.EX using the subject identifier.

JOIN CONDITION

    SDTM_DM2.SUBJID = EX.SUBJECT

The query retains the existing identifying and reference start
variables and assigns:

    EXENDAT AS RFENDTC

OUTPUT

    SDTM_DM3

The resulting dataset extends the subject-level information with
RFENDTC.
*/

PROC SQL;
CREATE TABLE SDTM_DM3 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       EXENDAT AS RFENDTC
FROM SDTM_DM2
  LEFT JOIN CLINICAL.EX
    ON SDTM_DM2.SUBJID=EX.SUBJECT;
QUIT;


/*
===============================================================================
STAGE 5 — ASSIGN TREATMENT REFERENCE DATES
===============================================================================

5.1 — Create RFXSTDTC and RFXENDTC

OBSERVATION

The SDTM DM specification includes the date/time of first study
treatment and the date/time of last study treatment.

The existing program assigns these variables from the reference
dates already present in SDTM_DM3.

APPROACH

A DATA step creates SDTM_DM4 and assigns:

    RFXSTDTC = RFSTDTC
    RFXENDTC = RFENDTC

OUTPUT

    SDTM_DM4

The dataset now carries the subject reference dates and the
corresponding treatment reference date variables.
*/

DATA SDTM_DM4;
  SET SDTM_DM3;
   RFXSTDTC = RFSTDTC;
   RFXENDTC = RFENDTC;
RUN;


/*
===============================================================================
STAGE 6 — INCORPORATE PARTICIPATION AND DEATH INFORMATION
===============================================================================

6.1 — Join the DS and DEATH Data Files

OBSERVATION

The DM dataset requires additional information about the end of
subject participation and the date/time of death.

These values are sourced from:

    DS.DSSTDAT
    DEATH.DTH_DAT

APPROACH

PROC SQL extends SDTM_DM4 through two LEFT JOIN operations.

FIRST JOIN

    SDTM_DM4.SUBJID = DS.SUBJECT

This associates the subject with the DS information.

SECOND JOIN

    DS.SUBJECT = DEATH.SUBJECT

This associates the joined DS record with the DEATH information.

VARIABLE ASSIGNMENTS

    DSSTDAT AS RFPENDTC
    DTH_DAT AS DTHDTC

The existing identifying, reference date, and treatment date
variables are retained in the SELECT statement.

OUTPUT

    SDTM_DM5

This dataset provides the information used to populate the
subject death flag in the next stage.
*/

PROC SQL;
CREATE TABLE SDTM_DM5 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       DSSTDAT AS RFPENDTC,
       DTH_DAT AS DTHDTC
FROM SDTM_DM4
  LEFT JOIN CLINICAL.DS
    ON SDTM_DM4.SUBJID=DS.SUBJECT
  LEFT JOIN CLINICAL.DEATH
    ON DS.SUBJECT=DEATH.SUBJECT;
QUIT;


/*
6.2 — Populate the Subject Death Flag

OBSERVATION

DTHDTC contains the date/time of death information incorporated
from the DEATH dataset.

The program uses the presence of this value to assign DTHFL.

APPROACH

A DATA step reads SDTM_DM5.

When DTHDTC is not missing, DTHFL is assigned "Y".

The original IF THEN DO statement is preserved.

OUTPUT

    SDTM_DM6

The dataset now includes the derived subject death flag.
*/

DATA SDTM_DM6;
  SET SDTM_DM5;
    IF DTHDTC NE " " THEN DO
       DTHFL="Y";
    END;
RUN;


/*
===============================================================================
STAGE 7 — INCORPORATE DEMOGRAPHIC VARIABLES
===============================================================================

7.1 — Join Additional Information from DM

OBSERVATION

The DM data file contains demographic attributes and study site
information required for the SDTM DM dataset.

These include:

    CENTRE
    BRTHDAT
    AGE
    AGEU
    SEX
    RACE
    ETHNIC

APPROACH

PROC SQL joins SDTM_DM6 to CLINICAL.DM.

JOIN CONDITION

    SDTM_DM6.SUBJID = DM.SUBJECT

The query carries forward the existing SDTM DM variables and
adds the following source fields:

    CENTRE AS SITEID
    BRTHDAT AS BRTHDC
    DM.AGE
    DM.AGEU
    DM.SEX
    DM.RACE
    DM.ETHNIC AS ETHNIC_CODE

ETHNIC_CODE retains the source ethnicity code for the subsequent
text assignment.

OUTPUT

    SDTM_DM7

The dataset now combines the reference dates, death information,
and demographic attributes.
*/

PROC SQL;
CREATE TABLE SDTM_DM7 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       RFPENDTC,
       DTHDTC,
       DTHFL,
       CENTRE AS SITEID,
       BRTHDAT AS BRTHDC,
       DM.AGE,
       DM.AGEU,
       DM.SEX,
       DM.RACE,
       DM.ETHNIC AS ETHNIC_CODE
FROM SDTM_DM6
  LEFT JOIN CLINICAL.DM
    ON SDTM_DM6.SUBJID=DM.SUBJECT;
QUIT;


/*
===============================================================================
STAGE 8 — PREPARE THE ETHNICITY VARIABLE
===============================================================================

8.1 — Establish the ETHNIC Character Variable

OBSERVATION

The previous stage retains the source ethnicity value as
ETHNIC_CODE.

A separate ETHNIC variable is required to hold the descriptive
ethnicity value.

APPROACH

A DATA step defines ETHNIC as a character variable with a length
of 22.

The variable is initialized with a blank value.

The existing variables from SDTM_DM7 are retained.

OUTPUT

    SDTM_DM8

This dataset provides the ETHNIC variable used in the next
transformation stage.
*/

DATA SDTM_DM8;
  length ETHNIC $ 22;
  SET SDTM_DM7;
    ETHNIC=" ";
RUN;


/*
===============================================================================
STAGE 9 — ASSIGN DEMOGRAPHIC VALUES AND PLANNED ARM CODE
===============================================================================

9.1 — Apply the Existing Demographic Conditions

OBSERVATION

The demographic fields include coded values for age units, sex,
race, and ethnicity.

The program applies conditional assignments to these variables
and also populates the planned arm code.

APPROACH

A DATA step reads SDTM_DM8 and evaluates the condition:

    AGEU = "C29848"

Within this IF THEN DO block, the program performs the following
assignments.

AGE UNITS

    C29848 -> YEARS

SEX

    C20197 -> M
    C16576 -> F
    Otherwise -> U

RACE

    C41260 -> ASIA
    C41261 -> WHITE

ETHNICITY

    ETHNIC_CODE = C41222
        -> NOT HISPANIC OR LATINO

PLANNED ARM CODE

    When RFSTDTC is not missing:
        ARMCD = A01-A02-A03

The demographic assignments and ARMCD condition are retained
within the original AGEU IF THEN DO block.

OUTPUT

    SDTM_DM9

This dataset carries the demographic values and planned arm
code produced by the existing conditional logic.
*/

DATA SDTM_DM9;
  SET SDTM_DM8;
    IF AGEU="C29848" THEN DO
       AGEU="YEARS";
    IF SEX="C20197" THEN
       SEX="M";
     ELSE IF SEX="C16576" THEN
       SEX="F";
     ELSE SEX="U";
    IF RACE="C41260" THEN
       RACE="ASIA";
     ELSE IF RACE="C41261" THEN
       RACE="WHITE";
    IF ETHNIC_CODE="C41222" THEN
       ETHNIC="NOT HISPANIC OR LATINO";
    IF RFSTDTC NE " " THEN
       ARMCD = "A01-A02-A03";
    END;
RUN;


/*
===============================================================================
STAGE 10 — ASSIGN ACTUAL ARM CODE
===============================================================================

10.1 — Create ACTARMCD

OBSERVATION

The SDTM DM specification includes both the planned arm code
and the actual arm code.

The previous stage populates ARMCD using the existing
conditional assignment.

APPROACH

A DATA step creates SDTM_DM10 from SDTM_DM9.

ACTARMCD is assigned the value of ARMCD.

    ACTARMCD = ARMCD

OUTPUT

    SDTM_DM10

This dataset contains the variables prepared for the final
SDTM DM assembly.
*/

DATA SDTM_DM10;
  SET SDTM_DM9;
   ACTARMCD = ARMCD;
RUN;


/*
===============================================================================
STAGE 11 — ASSEMBLE THE FINAL SDTM DM DATASET
===============================================================================

11.1 — Create Clinical.SDTM_DM

OBSERVATION

SDTM_DM10 contains the progressively constructed demographic
information, reference dates, participation dates, death
information, and arm codes.

The final dataset also requires additional fields from the
original DM data file.

APPROACH

PROC SQL creates Clinical.SDTM_DM by joining SDTM_DM10 to
CLINICAL.DM.

JOIN CONDITION

    SDTM_DM10.SUBJID = DM.SUBJECT

The query retains the selected variables from SDTM_DM10 and
incorporates the following DM fields:

    DM.VIS_DAT AS DMDTC
    DM.CENTRE
    DM.PART
    DM.RACEOTH
    VIS_DAT AS VISITDTC

DMDTC and VISITDTC are both selected from VIS_DAT in the
existing program.

The final SELECT statement establishes the variable collection
and ordering used in Clinical.SDTM_DM.

OUTPUT

    Clinical.SDTM_DM

This is the final SDTM DM dataset created by the SAS program.
*/

PROC SQL;
CREATE TABLE Clinical.SDTM_DM AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       RFPENDTC,
       DTHDTC,
       DTHFL,
       SITEID,
       BRTHDC,
       SDTM_DM10.AGE,
       SDTM_DM10.AGEU,
       SDTM_DM10.RACE,
       SDTM_DM10.ETHNIC,
       SDTM_DM10.SEX,
       ARMCD,
       ACTARMCD,
       DM.VIS_DAT AS DMDTC,
       DM.CENTRE,
       DM.PART,
       DM.RACEOTH,
       VIS_DAT AS VISITDTC
FROM SDTM_DM10
  LEFT JOIN CLINICAL.DM
    ON SDTM_DM10.SUBJID=DM.SUBJECT;
QUIT;


/*
===============================================================================
STAGE 12 — EXPORT THE SDTM DM DATASET
===============================================================================

12.1 — Produce the Excel Output

OBSERVATION

The completed Clinical.SDTM_DM dataset is the source for the
project's Excel output.

APPROACH

ODS EXCEL is used to create the SDTM_DM.xlsx workbook.

PROC PRINT displays the observations from Clinical.SDTM_DM in
the Excel output.

The existing TITLE and TITLE2 statements are retained.

OUTPUT

    SDTM_DM.xlsx

The workbook contains the printed SDTM DM dataset.
*/

ODS excel FILE="&Output/SDTM_DM.xlsx";
TITLE "PROJECT SDTM_DM";
TITLE2 "Compilation of Customers' specific details from the Case Report Forms";
PROC PRINT DATA=Clinical.SDTM_DM;
RUN;
ODS excel CLOSE;


/*
===============================================================================
WORKFLOW SUMMARY
===============================================================================

The program constructs the SDTM DM dataset through a sequence of
SAS DATA steps and PROC SQL operations.

The main stages are:

    1. Import the clinical data files.
    2. Establish study and subject identifiers.
    3. Prepare the subject reference start date/time.
    4. Join the reference start information to the demographic data.
    5. Assign the subject reference end date/time.
    6. Populate treatment reference dates.
    7. Incorporate participation and death information.
    8. Assign the subject death flag.
    9. Incorporate demographic and site information.
   10. Prepare and assign ethnicity and other demographic values.
   11. Populate planned and actual arm codes.
   12. Assemble Clinical.SDTM_DM.
   13. Export the dataset to SDTM_DM.xlsx.

The final dataset is constructed from the source clinical
information using the existing study identifiers, subject-level
relationships, variable assignments, and conditional derivations.
*/
