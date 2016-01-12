USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspMbrID_Subscr]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspMbrID_Subscr    Script Date: 4/22/2009 10:54:39 AM ******/
--this stored procedure will record the MemberID
--that is assigned to a subscriber

CREATE PROCEDURE [dbo].[uspMbrID_Subscr]

@SSN nvarchar(9),
@SubscriberID nvarchar(11)

AS

UPDATE tblSubscr
SET EIMBRID = @SubscriberID
WHERE SubSSN = @SSN
GO
