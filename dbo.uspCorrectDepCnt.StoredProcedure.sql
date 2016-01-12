USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCorrectDepCnt]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		John Criswell
-- Create date: 9/25/2009
-- Description:	Corrects Dep Cnts
-- =============================================
CREATE PROCEDURE [dbo].[uspCorrectDepCnt]
AS 
    BEGIN
        UPDATE tblSubscr
		SET tblSubscr.DepCnt = ISNULL(vwGrpDepCnt.DepCnt, 0)
		FROM tblSubscr
		LEFT OUTER JOIN vwGrpDepCnt
			ON tblSubscr.SubSSN = vwGrpDepCnt.DepSubID;
    END
GO
