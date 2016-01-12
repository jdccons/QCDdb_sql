USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCntSpouses]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCntSpouses]

@SSN nvarchar(9),
@DepRel nvarchar(1)

AS

SELECT Count(DepSubID) As CntOfSpouses
FROM tblDependent
WHERE DepSubID = @SSN
AND DepRelationship = @DepRel
GO
