USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspMbrID]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspMbrID    Script Date: 3/26/2009 6:06:51 AM ******/


/****** Object:  Stored Procedure dbo.uspMbrID    Script Date: 11/3/2006 11:55:40 AM ******/
/* stored procedure changed to add a parameter @PlanID -- 11/01/207 */
CREATE PROCEDURE [dbo].[uspMbrID]

@TID int,
@SubscriberID nvarchar(11)

 AS

UPDATE tmpExportAllAmerican
SET EIMBRID = @SubscriberID
WHERE TID = @TID
GO
