USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspFindSubscr_SSN]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspFindSubscr_SSN]
@SSN nvarchar(9), @FoundSubscr int OUTPUT 

AS

SELECT @FoundSubscr = Count(tblSubscr.SubSSN)
FROM tblSubscr
WHERE (((tblSubscr.SubSSN)= @SSN ))
GO
