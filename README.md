
# Clinical Project — SDTM Demographics (DM) Dataset

## Introduction

Clinical trial data is initially collected through Case Report Forms (CRF), where information about subjects, study participation, treatment, and demographic characteristics is recorded.

Before this information can be represented in a standardized clinical dataset, the relevant values must be identified, associated with the corresponding subjects, and assigned to the required variables.

This project focuses on constructing a **Study Data Tabulation Model (SDTM) Demographics (DM) dataset** from Clinical Data Management (CDM) data using **SAS programming and PROC SQL**.

Following the variable requirements in the `dm_only.xlsx` specification, the project brings together subject-level information from the DM, DS, EX, DEATH, and SPCPKB1 data files.

The workflow progressively:

- establishes study and subject identifiers;
- derives subject reference start and end dates;
- populates treatment reference dates;
- incorporates participation and death information;
- assigns the subject death flag;
- incorporates demographic and study site variables;
- applies the specified demographic values;
- populates planned and actual arm codes; and
- assembles and exports the final SDTM DM dataset.

The project uses a series of intermediate SAS datasets, supported by DATA steps and PROC SQL joins, to build the final `Clinical.SDTM_DM` table.

### Explore the SAS Workflow

The complete SAS program, including the source imports, transformation stages, PROC SQL joins, variable assignments, and Excel export, is documented here:

**[Project SDTM_DM.sas](./Project%20SDTM_DM.sas)**

---

## Background

### Why This Project?

Clinical trial data is collected across different Case Report Forms and subsequently organized into Clinical Data Management datasets.

Although the datasets capture related information, the values needed for a single SDTM domain may be distributed across multiple sources.

For example, demographic information is available in the DM dataset, while other subject-level dates and clinical observations are obtained from the EX, DS, DEATH, and SPCPKB1 datasets.

Creating the SDTM DM dataset therefore requires more than simply selecting columns from one source table.

The relevant records must be connected through subject identifiers, and the required variables must be populated according to the SDTM specification.

The central project question is:

> How can the available CDM datasets be combined and transformed into an SDTM Demographics dataset using SAS DATA steps and PROC SQL?

This involves several supporting questions:

- How should the study and subject identifiers be established?
- Which source fields provide the subject reference start and end dates?
- How are treatment reference dates assigned?
- How can participation and death information be incorporated?
- How should the demographic variables be populated from the DM data?
- How are the specified demographic codes represented in the output?
- How are the planned and actual arm codes assigned?
- How can the resulting variables be assembled into the final SDTM DM dataset?

The SAS program addresses these requirements through sequential dataset construction.

---

## Project Objective

The primary objective is to create the **SDTM DM dataset** based on the SDTM specification file, `dm_only.xlsx`.

The project uses the available CDM information to populate the demographic variables and other subject-level fields required for the DM domain.

The resulting dataset is created as:

`Clinical.SDTM_DM`

The program then produces an Excel output named:

`SDTM_DM.xlsx`

### Project Scope

The workflow covers:

1. Importing the source clinical data files.
2. Establishing study and subject identifiers.
3. Deriving reference and treatment date variables.
4. Incorporating participation and death information.
5. Assigning demographic attributes and coded values.
6. Populating planned and actual arm codes.
7. Assembling the final SDTM DM dataset.
8. Exporting the final dataset in Excel format.

The project is focused on **SDTM DM dataset construction**, rather than statistical analysis of clinical outcomes.

---

## Tools and Technologies

| Tool / Technology | Application |
|---|---|
| SAS | Clinical data processing and dataset construction |
| SAS DATA Step | Variable assignment, conditional logic, and intermediate dataset creation |
| PROC SQL | Subject-level joins, variable selection, and final dataset assembly |
| PROC IMPORT | Importing the clinical Excel files |
| CATX Function | Concatenating subject identifiers and date/time values |
| ODS EXCEL | Producing the final Excel output |
| Microsoft Excel | Source clinical files and SDTM DM output |

---

## Source Data

### Clinical Data Management Datasets

The source information originates from Case Report Forms completed during the clinical trial.

The cleansed CRF information is represented in CDM datasets, which provide the fields used to construct the SDTM DM variables.

The five principal source datasets are:

| Dataset | Role in the Project |
|---|---|
| DM | Subject identifiers, demographic attributes, study site information, and visit information |
| DS | Subject participation date information |
| EX | Subject reference end date information |
| DEATH | Subject death date information |
| SPCPKB1 | Subject reference start date/time information |

The SAS program also imports `CDM.xlsx`.

### Source Files

The source files referenced in the program are:

- `CDM.xlsx`
- `DEATH.xlsx`
- `DM.xlsx`
- `DS.xlsx`
- `EX.xlsx`
- `SPCPKB1.xlsx`

The SDTM variable requirements are described in:

`dm_only.xlsx`

### Source Relationships

The workflow associates records across the datasets using the subject identifier.

The main join relationships are:

| Dataset Construction | Source Relationship |
|---|---|
| SDTM_DM2 | SDTM_DM1.SUBJID = Concatenate.SUBJECT |
| SDTM_DM3 | SDTM_DM2.SUBJID = EX.SUBJECT |
| SDTM_DM5 | SDTM_DM4.SUBJID = DS.SUBJECT |
| SDTM_DM5 | DS.SUBJECT = DEATH.SUBJECT |
| SDTM_DM7 | SDTM_DM6.SUBJID = DM.SUBJECT |
| Clinical.SDTM_DM | SDTM_DM10.SUBJID = DM.SUBJECT |

These relationships support the progressive combination of information from the clinical datasets.

---

## SDTM DM Specification

The DM domain contains the subject-level variables required by the project specification.

The following table preserves the variable names and labels documented in the original project README.

| Variable Name | Variable Label |
|---|---|
| STUDYID | Study Identifier |
| DOMAIN | Domain Abbreviation |
| USUBJID | Unique Subject Identifier |
| SUBJID | Subject Identifier for the Study |
| RFSTDTC | Subject Reference Start Date/Time |
| RFENDTC | Subject Reference End Date/Time |
| RFXSTDTC | Date/Time of First Study Treatment |
| RFXENDTC | Date/Time of Last Study Treatment |
| RFPENDTC | Date/Time of End of Participation |
| DTHDTC | Date/Time of Death |
| DTHFL | Subject Death Flag |
| SITEID | Study Site Identifier |
| BRTHDTC | Date/Time of Birth |
| AGE | Age |
| AGEU | Age Units |
| RACE | Race |
| ETHNIC | Ethnicity |
| SEX | Sex |
| ARMCD | Planned Arm Code |
| ACTARMCD | Actual Arm Code |
| DMDTC | Date/Time of Collection |
| CENTRE | Centre Number |
| PART | Study Part Code |
| RACEOTH | Other Race Specification |
| VISITDTC | Date of Visit |

The SAS program constructs these variables through a combination of direct source assignments, derived values, conditional transformations, and PROC SQL joins.

---

# SAS Transformation Workflow

## Stage 1 — Import the Clinical Data Files

### Objective

Load the clinical Excel files into SAS for subsequent dataset construction.

### Approach

The program uses `PROC IMPORT` with `DBMS=XLSX` to import the source files.

The import statements assign the files to the specified SAS libraries, including `SDTM` and `CLINICAL`.

The imported information is then used in the subsequent DATA steps and PROC SQL operations.

### Output

The imported source datasets provide the foundation for the SDTM DM transformation sequence.

---

## Stage 2 — Establish Study and Subject Identifiers

### Objective

Create the initial demographic dataset with the study and subject identifying variables.

### Approach

The first DATA step reads `CLINICAL.DM` and assigns:

| Variable | Assignment |
|---|---|
| STUDYID | "XYZ" |
| DOMAIN | "DM" |
| USUBJID | CATX('/', STUDYID, SUBJECT) |
| SUBJID | SUBJECT |

The `CATX` function concatenates the study identifier and subject identifier using `/` as the separator.

The DATA step also includes a KEEP statement specifying the retained variables.

### Output

`SDTM_DM1`

This is the initial dataset in the SDTM DM construction sequence.

---

## Stage 3 — Derive Subject Reference Start Date/Time

### Objective

Populate `RFSTDTC`, the Subject Reference Start Date/Time.

### Source

`SPCPKB1`

### Approach

The program creates a temporary dataset named `Concatenate`.

The source observations are restricted to:

- `PSCHDAY = 1`
- `PART = "A"`

The `CATX` function combines `IPFD1DAT` and `IPFD1TIM`, separated by a space, to create `RFSTDTC`.

The temporary dataset is then joined to `SDTM_DM1` using the subject identifier.

The PROC SQL query uses a LEFT JOIN and retains observations where `RFSTDTC IS NOT NULL`.

### Output

`SDTM_DM2`

The dataset contains the selected identifying variables and the assigned reference start date/time.

---

## Stage 4 — Assign Subject Reference End Date/Time

### Objective

Populate `RFENDTC`, the Subject Reference End Date/Time.

### Source

`EX`

### Approach

PROC SQL joins `SDTM_DM2` to `CLINICAL.EX` using the subject identifier.

The source variable `EXENDAT` is assigned to `RFENDTC`.

The query retains the identifying variables and `RFSTDTC` while adding the reference end date.

### Output

`SDTM_DM3`

---

## Stage 5 — Populate Treatment Reference Dates

### Objective

Assign the treatment reference date variables required by the DM specification.

### Approach

A DATA step reads `SDTM_DM3` and performs the following assignments:

| Variable | Assignment |
|---|---|
| RFXSTDTC | RFSTDTC |
| RFXENDTC | RFENDTC |

The program uses the previously populated reference dates to assign the treatment reference date variables.

### Output

`SDTM_DM4`

---

## Stage 6 — Incorporate Participation and Death Information

### Objective

Populate the participation end date and death-related variables.

### Sources

- `DS`
- `DEATH`

### Approach

PROC SQL joins `SDTM_DM4` to the DS and DEATH datasets.

The first join associates the subject with the DS record.

The second join associates the DS subject with the DEATH record.

The query assigns:

| Variable | Source Assignment |
|---|---|
| RFPENDTC | DSSTDAT |
| DTHDTC | DTH_DAT |

The next DATA step evaluates `DTHDTC`.

When `DTHDTC` is not missing, the program assigns:

`DTHFL = "Y"`

### Outputs

- `SDTM_DM5` — participation and death dates.
- `SDTM_DM6` — subject death flag assignment.

---

## Stage 7 — Incorporate Demographic Information

### Objective

Add demographic attributes and study site information from the DM dataset.

### Source

`CLINICAL.DM`

### Approach

PROC SQL joins `SDTM_DM6` to `CLINICAL.DM` using the subject identifier.

The query assigns or selects:

| Source Variable | Output Variable |
|---|---|
| CENTRE | SITEID |
| BRTHDAT | BRTHDC |
| AGE | AGE |
| AGEU | AGEU |
| SEX | SEX |
| RACE | RACE |
| ETHNIC | ETHNIC_CODE |

The source ethnicity code is retained as `ETHNIC_CODE` for the subsequent transformation.

### Output

`SDTM_DM7`

The dataset combines the existing reference dates, death information, and demographic attributes.

---

## Stage 8 — Prepare the Ethnicity Variable

### Objective

Create the character variable used to store the descriptive ethnicity value.

### Approach

A DATA step reads `SDTM_DM7`.

The program defines `ETHNIC` as a character variable with a length of 22 and initializes it with a blank value.

The source ethnicity code remains available through `ETHNIC_CODE`.

### Output

`SDTM_DM8`

---

## Stage 9 — Apply Demographic Values and Planned Arm Code

### Objective

Apply the demographic assignments and populate the planned arm code.

### Approach

The program uses an IF THEN DO block beginning with the condition:

`AGEU = "C29848"`

Within this block, the following assignments are performed.

### Age Units

| Source Value | Assigned Value |
|---|---|
| C29848 | YEARS |

### Sex

| Source Value | Assigned Value |
|---|---|
| C20197 | M |
| C16576 | F |
| Otherwise | U |

### Race

| Source Value | Assigned Value |
|---|---|
| C41260 | ASIA |
| C41261 | WHITE |

### Ethnicity

| Source Value | Assigned Value |
|---|---|
| ETHNIC_CODE = C41222 | NOT HISPANIC OR LATINO |

### Planned Arm Code

When `RFSTDTC` is not missing, the program assigns:

`ARMCD = "A01-A02-A03"`

These assignments follow the conditional structure in the original SAS program.

### Output

`SDTM_DM9`

---

## Stage 10 — Assign Actual Arm Code

### Objective

Populate `ACTARMCD`, the Actual Arm Code.

### Approach

A DATA step reads `SDTM_DM9` and assigns:

`ACTARMCD = ARMCD`

This carries the planned arm code value into the actual arm code variable.

### Output

`SDTM_DM10`

---

## Stage 11 — Assemble the Final SDTM DM Dataset

### Objective

Combine the progressively constructed demographic information with the remaining selected fields from the DM dataset.

### Approach

PROC SQL creates `Clinical.SDTM_DM` by joining `SDTM_DM10` to `CLINICAL.DM`.

The join uses:

`SDTM_DM10.SUBJID = DM.SUBJECT`

The query retains the selected variables from `SDTM_DM10` and adds the following fields:

| Source Field | Final Selection |
|---|---|
| DM.VIS_DAT | DMDTC |
| DM.CENTRE | CENTRE |
| DM.PART | PART |
| DM.RACEOTH | RACEOTH |
| VIS_DAT | VISITDTC |

The program assigns both `DMDTC` and `VISITDTC` from `VIS_DAT`.

The final SELECT statement establishes the collection and order of variables in the output table.

### Output

`Clinical.SDTM_DM`

This is the final dataset created by the SAS transformation workflow.

---

## Stage 12 — Export the Final Dataset

### Objective

Produce the SDTM DM dataset in Excel format.

### Approach

The program uses `ODS EXCEL` to create the output workbook.

`PROC PRINT` displays the observations from `Clinical.SDTM_DM` in the workbook.

### Output

`SDTM_DM.xlsx`

---

# Dataset Construction Summary

The transformation process creates a sequence of intermediate datasets before assembling the final output.

| Dataset | Main Operation |
|---|---|
| SDTM_DM1 | Establish study and subject identifiers |
| Concatenate | Prepare reference start date/time information |
| SDTM_DM2 | Join reference start date/time to the initial dataset |
| SDTM_DM3 | Incorporate reference end date/time |
| SDTM_DM4 | Assign treatment reference dates |
| SDTM_DM5 | Incorporate participation and death dates |
| SDTM_DM6 | Assign subject death flag |
| SDTM_DM7 | Incorporate demographic and site variables |
| SDTM_DM8 | Initialize the ETHNIC variable |
| SDTM_DM9 | Apply demographic values and planned arm code |
| SDTM_DM10 | Assign actual arm code |
| Clinical.SDTM_DM | Assemble the final SDTM DM dataset |
| SDTM_DM.xlsx | Export the final dataset |

The sequence reflects the dependencies between the intermediate datasets.

Each subsequent stage uses the information created or selected in the preceding stages.

---

# Technical Implementation

## SAS DATA Steps

DATA steps are used to construct intermediate datasets and assign values to variables.

The program uses DATA steps for:

- study and subject identifier construction;
- date/time concatenation;
- treatment reference date assignment;
- subject death flag assignment;
- ethnicity variable initialization;
- demographic value assignments; and
- actual arm code assignment.

## PROC SQL

PROC SQL is used to combine subject-level information across the source datasets.

The main operations include:

- `CREATE TABLE` statements;
- `SELECT` statements;
- `LEFT JOIN` operations;
- subject identifier matching;
- variable aliases using `AS`; and
- filtering using `WHERE`.

These queries progressively populate the required SDTM DM variables.

## CATX Function

The SAS `CATX` function is used in two parts of the workflow.

First, it creates `USUBJID` by concatenating `STUDYID` and `SUBJECT` with `/`.

Second, it combines `IPFD1DAT` and `IPFD1TIM` to populate `RFSTDTC`.

## Conditional Logic

The program uses `IF`, `THEN`, `ELSE IF`, and `DO` statements to assign values based on specified conditions.

These operations are applied to the death flag, demographic values, and planned arm code.

## ODS EXCEL

ODS EXCEL is used to produce the final Excel workbook from the constructed SDTM DM dataset.

---

# Final Output

The final SAS dataset is:

`Clinical.SDTM_DM`

The final Excel workbook is:

`SDTM_DM.xlsx`

The final SELECT statement contains the following variables:

| Variable | Description |
|---|---|
| STUDYID | Study Identifier |
| DOMAIN | Domain Abbreviation |
| USUBJID | Unique Subject Identifier |
| SUBJID | Subject Identifier for the Study |
| RFSTDTC | Subject Reference Start Date/Time |
| RFENDTC | Subject Reference End Date/Time |
| RFXSTDTC | Date/Time of First Study Treatment |
| RFXENDTC | Date/Time of Last Study Treatment |
| RFPENDTC | Date/Time of End of Participation |
| DTHDTC | Date/Time of Death |
| DTHFL | Subject Death Flag |
| SITEID | Study Site Identifier |
| BRTHDC | Birth Date Variable Selected by the SAS Program |
| AGE | Age |
| AGEU | Age Units |
| RACE | Race |
| ETHNIC | Ethnicity |
| SEX | Sex |
| ARMCD | Planned Arm Code |
| ACTARMCD | Actual Arm Code |
| DMDTC | Date/Time of Collection |
| CENTRE | Centre Number |
| PART | Study Part Code |
| RACEOTH | Other Race Specification |
| VISITDTC | Date of Visit |

The final dataset represents the subject-level information assembled through the existing SAS transformation sequence.

---

# Project Summary

This project demonstrates the construction of an SDTM Demographics dataset from multiple clinical data sources using SAS programming and PROC SQL.

The workflow begins with clinical data imports and progressively develops the required subject-level variables through identifier construction, date derivations, dataset joins, and conditional assignments.

The intermediate datasets provide a sequential structure for assembling the demographic information before creating the final `Clinical.SDTM_DM` table.

The project demonstrates practical applications of:

- clinical data transformation;
- SAS DATA step programming;
- PROC SQL joins;
- subject-level data integration;
- variable derivation and assignment;
- conditional data processing;
- SDTM DM dataset construction; and
- Excel output generation.

The resulting program documents a complete source-to-output transformation workflow for the SDTM Demographics domain.

---

## Repository Contents

| File | Description |
|---|---|
| [Project SDTM_DM.sas](./Project%20SDTM_DM.sas) | Complete SAS program with documented transformation stages |
| [README.md](./README.md) | Project background, source data, SDTM specification, workflow, and technical documentation |

---
