USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspInsertRate]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[uspInsertRate]

@PLanID nvarchar(8),
@CoverID nvarchar(5),
@CoverDesc nvarchar(25),
@Rate money,
@TierCode char(1)

 AS


INSERT INTO [tblPlanRatesGrp]([PLANgrID], [PLANcoverage], [PLANcoverageDESC], [PLANgrRATE], [TierCode])
VALUES( @PLanID, @CoverID, @CoverDesc, @Rate, @TierCode)
GO
