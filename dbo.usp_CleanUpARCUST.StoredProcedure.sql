USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CleanUpARCUST]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  clean up individual records on ARCUST_local  */
CREATE PROCEDURE [dbo].[usp_CleanUpARCUST]
AS

UPDATE ARCUST_local
SET Rsrv2 = ''
	, Rsrv1 = CASE	WHEN CreditHold = 'Y' THEN 3 
					WHEN CreditHold = 'N' THEN 1 
					ELSE 1 
			  END
WHERE CustomerClassKey = 'INDIV';

/* get rid of duplicate records  */
--SELECT *
--FROM (
--	SELECT ID
--		, CustomerName
--		, CustomerKey
--		, Spare
--		, ROW_NUMBER() OVER (
--			PARTITION BY CustomerName
--			, CustomerKey
--			, Spare ORDER BY ID
--			) AS Dup
--	FROM dbo.ARCUST_local
--	WHERE CustomerClassKey = 'INDIV'
--		AND (
--			CustomerName != ''
--			OR CustomerName IS NOT NULL
--			)
--		AND CreditHold = 'N'
--	) x
--WHERE x.Dup > 1
--ORDER BY x.CustomerKey -- 25

WITH Duplicates
AS (
		SELECT ID
		, CustomerName
		, CustomerKey
		, Spare
		, ROW_NUMBER() OVER (
			PARTITION BY CustomerName
			, CustomerKey
			, Spare ORDER BY ID
			) AS Dup
	FROM dbo.ARCUST_local
	WHERE CustomerClassKey = 'INDIV'
		AND (
			CustomerName != ''
			OR CustomerName IS NOT NULL
			)
		AND CreditHold = 'N'
	)
DELETE Duplicates
WHERE Dup > 1;

/*  individuals with no names  */
--SELECT *
--FROM ARCUST_local
--WHERE CustomerName = ''
--	AND CustomerClassKey = 'INDIV';  -- 13
	
--SELECT arc.*
--FROM ARCUST_local arc
--LEFT OUTER JOIN tblSubscr s
--	ON arc.CustomerKey = s.PltCustKey
--WHERE arc.CustomerName = ''
--	AND arc.CustomerClassKey = 'INDIV';  -- 13
	
/*  none of these individuals are in tblSubscr
	therefore, they can be deleted			*/
DELETE
FROM ARCUST_local
FROM ARCUST_local
LEFT OUTER JOIN tblSubscr AS s
	ON ARCUST_local.CustomerKey = s.PltCustKey
WHERE (ARCUST_local.CustomerName = '')
	AND (ARCUST_local.CustomerClassKey = 'INDIV');

/*  clean Rsrv1 and Rsrv2  */
UPDATE ARCUST_local
SET Rsrv1 = 1
WHERE CreditHold = 'N';

UPDATE ARCUST_local
SET Rsrv1 = 3
WHERE CreditHold = 'Y';

UPDATE ARCUST_local
SET Rsrv2 = ''
WHERE Rsrv2 IS NULL;

/*  update the GroupType field for individuals */
UPDATE ARCUST_local
SET GroupType = 9
WHERE CustomerClassKey = 'INDIV';
GO
