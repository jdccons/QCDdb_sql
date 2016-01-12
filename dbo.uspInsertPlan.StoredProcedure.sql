USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspInsertPlan]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[uspInsertPlan]

@PlanID nvarchar(8),
@PlanDesc nvarchar(20),
@grGroups nvarchar(8)


 AS


INSERT INTO [QCDdataSQL].[dbo].[tblPlanGrp]([PLANgrID], [PLANdesc], [PLANgrGROUPS])
VALUES(@PlanID, @PlanDesc, @grGroups)
GO
