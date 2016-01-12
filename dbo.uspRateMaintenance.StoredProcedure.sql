USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspRateMaintenance]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspRateMaintenance]

@GroupID nvarchar(5),
@CoverID int,
@PlanID int,
@Rate float

 AS

IF (Select Count(*) FROM tblRates 
WHERE GroupID = @GroupID 
AND CoverID = @CoverID
AND PlanID = @PlanID) > 0 
Begin
	-- Update existing record
	UPDATE tblRates SET Rate = @Rate WHERE GroupID = @GroupID AND CoverID = @CoverID AND PlanID = @PlanID
End
Else
	-- Insert new record
	INSERT INTO tblRates (GroupID, CoverID, PlanID,  Rate)
	VALUES (@GroupID, @CoverID, @PlanID,  @Rate)
GO
