USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCntTotalDeps]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCntTotalDeps]
@SubGroupID varchar(5)

AS

SELECT COUNT(d.DepSubID) AS CurDCnt
FROM tblSubscr AS s INNER JOIN
tblDependent AS d ON s.SubSSN = d.DepSubID
WHERE (s.SubGroupID = @SubGroupID)
GO
