USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspFindRate]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspFindRate    Script Date: 11/3/2006 11:55:40 AM ******/
/* stored procedure changed to add a parameter @PlanID -- 11/01/207 */
CREATE PROCEDURE [dbo].[uspFindRate]

@GroupID nvarchar(5),
@CoverID int,
@PlanID int

 AS

Select RateID, Rate FROM tblRates 
WHERE GroupID = @GroupID 
AND CoverID = @CoverID 
AND PlanID = @PlanID
GO
