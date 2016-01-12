USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspEffDateCleanup]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspEffDateCleanup]

AS

-- detects discrepancies in effective dates
-- between QCD and GroupLink
CREATE TABLE #MNLEffDates
	(EIMBRID nvarchar(13) Null,
	EINMPLAN nvarchar(10) Null,
	QCDEffDate nvarchar(10),
	MNLEffDate nvarchar(10))

-- inserts all of the mismatched effdates into a temp table
INSERT INTO #MNLEffDates (EIMBRID, EINMPLAN, QCDEffDate, MNLEffDate)
SELECT  
tmpExportAllAmerican.EIMBRID,
tmpExportAllAmerican.EINMPLAN, 
tmpExportAllAmerican.EIDTCVEF AS QCDEffDate,
AA_Member_EffDate.EIDTCVEF AS MNLEffDate
FROM AA_Member_EffDate INNER JOIN tmpExportAllAmerican 
ON (tmpExportAllAmerican.EINMPLAN = AA_Member_EffDate.EINMPLAN) 
AND (AA_Member_EffDate.EIMBRID = tmpExportAllAmerican.EIMBRID)
WHERE (((AA_Member_EffDate.EIDTCVEF)<>[tmpExportAllAmerican].[EIDTCVEF]))

-- updates tmpExportAllAmerican to reflect the Group Link effective dates
UPDATE e
SET e.EIDTCVEF = m.MNLEffDate
FROM tmpExportAllAmerican e
INNER JOIN #MNLEffDates m
ON e.EIMBRID = m.EIMBRID
AND e.EINMPLAN = m.EINMPLAN
GO
