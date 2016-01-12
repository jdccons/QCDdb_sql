USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspAddCoverage]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspAddCoverage    Script Date: 11/3/2006 11:55:40 AM ******/
CREATE PROCEDURE [dbo].[uspAddCoverage]

@CoverCode varchar(5),
@CoverDesc varchar(20)

 AS

INSERT INTO tblCoverage (CoverCode, CoverDescr)
VALUES (@CoverCode, @CoverDesc)
GO
