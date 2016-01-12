USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspUpdateCoverage]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspUpdateCoverage    Script Date: 11/3/2006 11:55:40 AM ******/
CREATE PROCEDURE [dbo].[uspUpdateCoverage]

@CoverID int,
@CoverCode varchar(5),
@CoverDesc varchar(20)

 AS


UPDATE tblCoverage Set CoverCode = @CoverCode, CoverDescr = @CoverDesc WHERE CoverID = @CoverID
GO
