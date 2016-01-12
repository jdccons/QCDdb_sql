USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspMNL_EffDates]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspMNL_EffDates]

AS
TRUNCATE TABLE tmpMNL_EffDates

-- temp table for MNL effective dates
CREATE TABLE #MNLEFFDT
	(EIRECID nvarchar(1),
	EIMBRID nvarchar(13),
	EISBRID nvarchar(13),
	EINAML nvarchar(20),
	EINAMF nvarchar(15),
	GrpID nvarchar(5),
	EINMPLAN nvarchar(10),
	GrpEffDate datetime,
	SubEffDate datetime)
INSERT INTO #MNLEFFDT
(EIRECID
, EIMBRID
, EISBRID 
, EINAML 
, EINAMF 
, GrpID 
, EINMPLAN 
, GrpEffDate 
, SubEffDate)
SELECT EIRECID
, EIMBRID
, EISBRID
, EINAML
, EINAMF
, Right(RTrim(LTrim([EIGRPID])),Len(RTrim(LTrim([EIGRPID])))-3) AS GrpID 
, EINMPLAN
, Convert(datetime, (Left([EIDTEFF],2) + '/' + SubString([EIDTEFF],3,2) + '/' + Right([EIDTEFF],4)), 101) AS GrpEffDate
, Convert(datetime, (Left([EIDTCVEF],2) + '/' + SubString([EIDTCVEF],3,2) + '/' + Right([EIDTCVEF],4)), 101) AS SubEffDate
FROM ELGEXP_SQL
WHERE SubString([EINMPLAN],4,3) In ('WHT', 'RPL')
AND SubString([EINMPLAN],8,3) = 'MNL'

-- temp table for QCD effective dates
CREATE TABLE #QCDEFFDT
	(EIRECID nvarchar(1),
	EIMBRID nvarchar(13),
	EISBRID nvarchar(13),
	EINAML nvarchar(20),
	EINAMF nvarchar(15),
	GrpID nvarchar(5),
	EINMPLAN nvarchar(10),
	GrpEffDate datetime,
	SubEffDate datetime)
INSERT INTO #QCDEFFDT
(EIRECID
, EIMBRID
, EISBRID 
, EINAML 
, EINAMF 
, GrpID 
, EINMPLAN 
, GrpEffDate 
, SubEffDate)
SELECT EIRECID
, EIMBRID
, EISBRID
, EINAML
, EINAMF
, Right(RTrim(LTrim([EIGRPID])),Len(RTrim(LTrim([EIGRPID])))-3) AS GrpID 
, EINMPLAN
, Convert(datetime, (Left([EIDTEFF],2) + '/' + SubString([EIDTEFF],3,2) + '/' + Right([EIDTEFF],4)), 101) AS GrpEffDate
, Convert(datetime, (Left([EIDTCVEF],2) + '/' + SubString([EIDTCVEF],3,2) + '/' + Right([EIDTCVEF],4)), 101) AS SubEffDate
FROM ELGEXP_SQL
WHERE SubString([EINMPLAN],4,3) In ('WHT', 'RPL')
AND SubString([EINMPLAN],8,3) = 'QCD'

INSERT INTO tmpMNL_EffDates (EIRECID, EIMBRID, EISBRID, EINAML, EINAMF, GrpID, EINMPLAN, GrpEffDate, SubEffDate)
SELECT m.EIRECID, m.EIMBRID, m.EISBRID, m.EINAML, m.EINAMF, m.GrpID, m.EINMPLAN, m.GrpEffDate, m.SubEffDate
FROM #MNLEFFDT m
INNER JOIN #QCDEFFDT q
ON m.EIMBRID = q.EIMBRID
WHERE m.SubEffDate > q.SubEffDate
GO
