/*****************************************************************************************************************************************************************************
	Author: Josh Wilson
	Date: 1.3.24
	Purpose: Combine the Current Visit Review Data w/ Historical
	Structure:
				Step 1: Update values in the table where 
				Step 2: Delete those months from the historical
				Step 3:	
	Dependencies: 
														
******************************************************************************************************************************************************************************/


--DROP TABLE	EDSOAnalytics..VisitReview_ETL

IF OBJECT_ID('tempdb.dbo.#VR_ETL', 'U') IS NOT NULL
	DROP TABLE #VR_ETL;

	SELECT
			ETL.*
			, Date_Convention.FiscalYear AS FY
			, Date_Convention.FiscalQuarter AS FYQ
			, Date_Convention.Year AS Year
			, Date_Convention.FiscalQuarterName AS FiscalQuarterName
			, Date_Convention.FiscalHalfName AS FiscalHalfName
	  INTO	#VR_ETL
	  FROM	EDSOAnalytics..VisitReview_ETL AS ETL
LEFT JOIN EDSOAnalytics..MS_Dates AS Date_Convention
			ON Date_Convention.DAte = ETL.[Month]

MERGE EDSOAnalytics..VisitReview_FY21_Onwards AS TARGET
USING #VR_ETL AS SOURCE
ON (TARGET.LOB_in_VR = SOURCE.LOB_in_VR
	AND TARGET.Month = SOURCE.Month)
WHEN MATCHED AND (TARGET.MQL <> SOURCE.MQL
					OR TARGET.Visit <> SOURCE.Visit
					OR TARGET.MQL_Goal <> SOURCE.MQL_Goal
					OR TARGET.Visit_Goal <> SOURCE.Visit_Goal)
THEN UPDATE SET
		TARGET.MQL = SOURCE.MQL
		, TARGET.MQL_Goal = SOURCE.MQL_Goal
		, TARGET.Percent_MQL_Goal = SOURCE.Percent_MQL_Goal
		, TARGET.Visit = SOURCE.Visit
		, TARGET.Visit_Goal = SOURCE.Visit_Goal
		, TARGET.Percent_Visit_Goal = SOURCE.Percent_Visit_Goal
WHEN NOT MATCHED BY TARGET
THEN INSERT (
				Vertical
				, LOB_in_VR
				, ProgramAcronym
				, Month
				, MQL
				, MQL_Goal
				, Percent_MQL_Goal
				, Visit
				, Visit_Goal
				, Percent_Visit_Goal
				, Exclude
				, LOB_Consolidated
				, FY
				, FYQ
				, Year
				, FiscalQuarterName
				, FiscalHalfName
			)
VALUES (
				SOURCE.Vertical
				, SOURCE.LOB_in_VR
				, SOURCE.ProgramAcronym
				, SOURCE.Month
				, SOURCE.MQL
				, SOURCE.MQL_Goal
				, SOURCE.Percent_MQL_Goal
				, SOURCE.Visit
				, SOURCE.Visit_Goal
				, SOURCE.Percent_Visit_Goal
				, SOURCE.Exclude
				, SOURCE.LOB_Consolidated
				, FY
				, FYQ
				, Year
				, FiscalQuarterName
				, FiscalHalfName
)

OUTPUT $action;
GO


/*

-- Add Date Columns to Table
ALTER TABLE EDSOAnalytics..VisitReview_FY21_Onwards
ADD FY INT

ALTER TABLE EDSOAnalytics..VisitReview_FY21_Onwards
ADD FYQ INT


ALTER TABLE EDSOAnalytics..VisitReview_FY21_Onwards
ADD Year INT

ALTER TABLE EDSOAnalytics..VisitReview_FY21_Onwards
ADD FiscalQuarterName NVARCHAR(3)

ALTER TABLE EDSOAnalytics..VisitReview_FY21_Onwards
ADD FiscalHalfName NVARCHAR(3)
GO

-- Update Tables
USE EDSOAnalytics

UPDATE VisitReview_FY21_Onwards
--SET VisitReview_FY21_Onwards.FY = Date_Convention.FiscalYear
--SET VisitReview_FY21_Onwards.FYQ = Date_Convention.FiscalQuarter
--SET VisitReview_FY21_Onwards.Year = Date_Convention.Year
--SET VisitReview_FY21_Onwards.FiscalQuarterName = Date_Convention.FiscalQuarterName
SET VisitReview_FY21_Onwards.FiscalHalfName = Date_Convention.FiscalHalfName
FROM VisitReview_FY21_Onwards
LEFT JOIN EDSOAnalytics..MS_Dates AS Date_Convention
			ON Date_Convention.DAte = VisitReview_FY21_Onwards.Month

*/