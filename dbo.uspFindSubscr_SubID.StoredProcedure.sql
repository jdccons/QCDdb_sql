USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspFindSubscr_SubID]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspFindSubscr_SubID]
@SubID nvarchar(8), @FoundSubscr int OUTPUT 

AS

SELECT @FoundSubscr = Count(tblSubscr.SubID)
FROM tblSubscr
WHERE (((tblSubscr.SubID)= @SubID ))
GO
