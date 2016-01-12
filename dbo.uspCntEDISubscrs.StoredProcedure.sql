USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCntEDISubscrs]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Created by:  John Criswell
-- Created date: 01/03/2011
-- Purpose:	Counts the number of subscribers in
--          tblEDI_App_Subscr after a new group
--          has been imported into the table
-- Modifications:
-- <Date> <Programmer> <Change>
-- =============================================

CREATE PROCEDURE [dbo].[uspCntEDISubscrs]
@SubGroupID varchar(5)

AS

BEGIN

SELECT		COUNT(SubSSN) ImpSCnt 
FROM		dbo.tblEDI_App_Subscr
WHERE		SubGroupID = @SubGroupID

END
GO
