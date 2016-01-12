USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspTierType]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspTierType]

@GroupID nvarchar(5),
@PlanID int

AS

SELECT Count(tblCoverage.CoverID) As CntOfCoverages
FROM (tblRates INNER JOIN tblPlans ON tblRates.PlanID = tblPlans.PlanID) 
INNER JOIN tblCoverage ON tblRates.CoverID = tblCoverage.CoverID
WHERE (((tblRates.GroupID)= @GroupID ) AND ((tblPlans.PlanID)= @PlanID ))
GO
