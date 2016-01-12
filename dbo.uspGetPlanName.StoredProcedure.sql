USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspGetPlanName]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetPlanName]
@SSN nvarchar(9)

AS

SELECT RTrim(LTrim(tblPlans.PlanDesc)) As PlanName
FROM tblSubscr INNER JOIN
tblPlans ON tblSubscr.PlanID = tblPlans.PlanID
WHERE (((tblSubscr.SubSSN) = @SSN))
GO
