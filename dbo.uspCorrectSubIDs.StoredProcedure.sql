USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCorrectSubIDs]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCorrectSubIDs]

@SubID nvarchar(13), @MbrID nvarchar(13)

AS

/****** Object:  Stored Procedure QCD.uspCorrectSubIDs    Script Date: 04/13/2009 08:14:00 AM ******/

UPDATE e
SET e.EISBRID = @MbrID
FROM tmpExportAllAmerican e
WHERE e.EISBRID = @SubID
GO
