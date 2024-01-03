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