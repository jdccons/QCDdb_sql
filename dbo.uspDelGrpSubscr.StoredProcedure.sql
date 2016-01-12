USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspDelGrpSubscr]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspDelGrpSubscr]

@SSN nvarchar(9)

AS

DELETE FROM tblSubscr
WHERE tblSubscr.SubSSN = @SSN
GO
