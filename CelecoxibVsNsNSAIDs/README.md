OHDSI Celecoxib versus non-selective NSAIDs study
=================================================

This study aims to showcase the use of the [CohortMethod package](https://github.com/OHDSI/CohortMethod) in a study, and investigate the effect of various forms of confounder adjustment available in that package. For this we use the well-studied example of Cox-2 inhibitors (Celecoxib) versus non-selective NSAIDs and the risk of GI bleed. Other outcomes have been included as well.

Detailed information and protocol is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:celecoxib_vs_nsnsaids).

How to run
==========
1. Make sure that you have Java installed. If you don't have Java already intalled on your computed (on most computers it already is installed), go to java.com to get the latest version. (If you have trouble building with rJava below, be sure on Windows that your Path variable includes the path to jvm.dll (Windows Button --> type "path" --> Edit Environmental Variables --> Edit PATH variable, add to end ;C:/Program Files/Java/jre/bin/server) or wherever it is on your system.)

2. In R, use the following code to install the study package and its dependencies:

	```r
	install.packages("devtools")
	library(devtools)
    install_github("ohdsi/OhdsiRTools", ref = "80f5dba70e75a498e3ba4c00b5325c1e7430a3b2") 
    install_github("ohdsi/SqlRender", ref = "be36af85e3cfdba7a787f7cd48ff30e61835a002")
    install_github("ohdsi/DatabaseConnector", ref = "352b0b634db0ab823e9fd46af09c94480ab36ede")
    install_github("ohdsi/Cyclops", ref = "b66f28f823ab98c99edc14a5a644ee980227d946")
    install_github("ohdsi/PatientLevelPrediction", ref = "v1.0.0") 
    install_github("ohdsi/CohortMethod", ref = "ab762d5c89058ddd41b591669151b9b2ff40c4a7")
	install_github("ohdsi/OhdsiSharing", ref = "f5d063ee31a35d3bcfc4c15a7fd9ee3cfaa0b556")
	install_github("ohdsi/EmpiricalCalibration", ref = "457c7bc383acdee2d25e9df614c62a0769220fe0")
	install_github("ohdsi/StudyProtocols/CelecoxibVsNsNSAIDs")
	```

3. Once installed, you can execute the study by modifying and using the following code:

	```r
	library(CelecoxibVsNsNSAIDs)

	connectionDetails <- createConnectionDetails(dbms = "postgresql",
												 user = "joe",
												 password = "secret",
												 server = "myserver")

	execute(connectionDetails,
			cdmDatabaseSchema = "cdm_data",
			workDatabaseSchema = "results",
			studyCohortTable = "celecoxib_vs_nsnsaids",
			oracleTempSchema = NULL,
			outputFolder = "c:/temp/study_results",
			cdmVersion = "5")
	```

	* For details on how to configure```createConnectionDetails``` in your environment type this for help:
	```r
	?createConnectionDetails
	```

	* ```cdmDatabaseSchema``` should specify the schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
	
	* ```workDatabaseSchema``` should specify the schema name where intermediate results can be stored. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
	
	* ```studyCohortTable``` should specify the name of the table that will be created in the work database schema where the exposure and outcomes cohorts will be stored.

	* ```oracleTempSchema``` should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.

	* ```cdmVersion``` is the version of the CDM. Can be "4" or "5".
	
	* ```outputFolder``` a location in your local file system where results can be written.

4. Mail the file ```export/studyResult.zip``` in the output folder to the study coordinator.

  

