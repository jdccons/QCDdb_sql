USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_Trx_Cnts]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_Trx_Cnts]
as
/*  count beginning subscribers  */
SELECT 'Beginning Subscribers' AS CalcType, COUNT(SubSSN) RcdCnt
FROM tblSubscr
WHERE SubStatus = 'GRSUB'
	AND SubCancelled = 1
UNION
/*  count deletes  */
SELECT 'Subscriber Terminations' AS CalcType, COUNT(SubSSN) RcdCnt
FROM tblSubscr AS s
LEFT OUTER JOIN tpa_data_exchange_sub AS r
	ON s.SubSSN = r.SSN
WHERE (s.SubCancelled = 1)
	AND (s.SubStatus = 'GRSUB')
	AND (r.SSN IS NULL)
UNION
/*  count adds  */
SELECT 'Adds' AS CalcType, COUNT(r.SSN)  RcdCnt
FROM (
	SELECT SubSSN
	FROM tblSubscr
	WHERE SubStatus = 'GRSUB'
		AND SubCancelled = 1
	) s
RIGHT OUTER JOIN (
	SELECT SSN
	FROM tpa_data_exchange_sub
	INNER JOIN tblGrp g
		ON tpa_data_exchange_sub.GRP_ID = g.GroupID
	WHERE RCD_TYPE = 'S'
		AND g.GRCancelled = 0
	) r
	ON s.SubSSN = r.SSN
WHERE s.SubSSN IS NULL
UNION
/*  count ending subscribers  */
SELECT 'Ending Subscribers' AS CalcType, COUNT(SSN) RcdCnt
FROM tpa_data_exchange_sub r
INNER JOIN tblGrp g
	ON r.GRP_ID = g.GroupID
WHERE r.RCD_TYPE = 'S';
GO
