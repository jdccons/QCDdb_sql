USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspFindSubscr]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspFindSubscr]
@SSN nvarchar(9)

AS

SELECT Count(tblSubscr.SubSSN) As CntOfSubscrs
FROM tblSubscr
WHERE (((tblSubscr.SubSSN)= @SSN ))
GO
