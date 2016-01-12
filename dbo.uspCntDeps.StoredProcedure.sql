USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCntDeps]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCntDeps]
@SSN nvarchar(9)

AS

SELECT Count(tblDependent.DEPsubID) As CntOfDeps
FROM tblDependent
WHERE (((tblDependent.DEPsubID)= @SSN ))
GO
