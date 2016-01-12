USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspMarkCardPrinted]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [dbo].[uspMarkCardPrinted]

@strSSN nvarchar(9)

 AS


UPDATE tblSubscr
	SET SUBcardPRT = 1, SUBcardPRTdte = Convert(datetime, (Convert(varchar,GetDate(),101)))
WHERE SUBssn = @strSSN
GO
