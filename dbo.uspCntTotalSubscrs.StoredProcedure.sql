USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCntTotalSubscrs]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCntTotalSubscrs]
@SubGroupID varchar(5)

AS

SELECT COUNT(SubSSN) AS CurSCnt FROM tblSubscr 
WHERE SubGroupID = @SubGroupID
GO
