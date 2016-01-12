USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_NextSysDocId]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_NextSysDocId](@SysDocId INT)

AS

UPDATE dbo.ARNEXTSY_local
SET NextSysDocID = @SysDocId
GO
