USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_clean_up_ARTRANH_local]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_clean_up_ARTRANH_local]
as
UPDATE art
SET Spare = s.SubID
	, Spare2 = s.SubSSN
	, Spare3 = 'Individual'
FROM ARTRANH_local art
INNER JOIN tblSubscr s
	ON art.CustomerKey = s.PltCustKey
WHERE SubStatus = 'INDIV';

--SELECT DISTINCT Spare3
--FROM ARTRANH_local art
--INNER JOIN tblGrp g
--	ON art.CustomerKey = g.GroupID;

UPDATE art
SET Spare3 = 'QCD Only'
FROM ARTRANH_local art
INNER JOIN tblGrp g
	ON art.CustomerKey = g.GroupID
WHERE g.GroupType = 1;

UPDATE art
SET Spare3 = 'All American'
FROM ARTRANH_local art
INNER JOIN tblGrp g
	ON art.CustomerKey = g.GroupID
WHERE g.GroupType = 4;

--SELECT *
--FROM ARTRANH_local
--WHERE CustomerKey = 'ELS56'
--	AND Spare3 IS NULL;

--SELECT *
--FROM tblSubscr
--WHERE PltCustKey = 'ELS56';

--SELECT *
--FROM ARCUST_local
--WHERE CustomerKey = 'ELS56';

--SELECT DISTINCT art.CustomerKey
--	, arc.CustomerName
--	, art.Spare3 AS Type
--FROM ARTRANH_local AS art
--INNER JOIN ARCUST_local AS arc
--	ON art.CustomerKey = arc.CustomerKey
--WHERE ((arc.CreditHold) = 'N')
--ORDER BY art.CustomerKey;
IF EXISTS (
		SELECT *
		FROM tempdb.dbo.sysobjects o
		WHERE o.xtype IN ('U')
			AND o.id = object_id(N'tempdb..#temp')
		)
	DROP TABLE #temp;

SELECT DISTINCT CustomerKey
INTO #temp
FROM ARTRANH_local art
LEFT OUTER JOIN tblSubscr s
	ON art.CustomerKey = s.PltCustKey
WHERE art.CustomerClassKey = 'INDIV'
	AND s.PltCustKey IS NULL;

UPDATE arc
SET CreditHold = 'Y'
FROM ARCUST_local arc
INNER JOIN #temp t
	ON arc.CustomerKey = t.CustomerKey;

--SELECT *
--FROM ARTRANH_local
--WHERE Spare3 = 'Individual'
--	AND DocumentDate BETWEEN CAST('2015-10-01 00:0:00' AS DATETIME)
--		AND CAST('2015-10-31 00:0:00' AS DATETIME);
GO
