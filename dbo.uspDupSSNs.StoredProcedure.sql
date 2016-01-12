USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspDupSSNs]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspDupSSNs]

AS

/*
SELECT RTrim(LTrim(tblPlans.PlanDesc)) As PlanName
FROM tblSubscr INNER JOIN
tblPlans ON tblSubscr.PlanID = tblPlans.PlanID
WHERE (((tblSubscr.SubSSN) = @SSN))
*/
 
SELECT EISSN#, COUNT(EISSN#) AS NumOccurrences
FROM ELGEXP_SQL
WHERE (EIRECID = 'P') AND (SUBSTRING(EINMPLAN, 8, 3) = 'QCD') 
OR (EIRECID = 'P') AND (EINMPLAN = 'QCDBLU-MNL')
GROUP BY EISSN#
HAVING (COUNT(EISSN#) > 1)
GO
