USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usrUpdatetblCommision]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.usrUpdateTBLCommision    Script Date: 11/3/2006 11:55:40 AM ******/

/****** Object:  Stored Procedure dbo.usrUpdateTBLCommision    Script Date: 5/5/2006 4:06:30 PM ******/
CREATE PROCEDURE [dbo].[usrUpdatetblCommision] AS

UPDATE tblCommission SET tblCommission.PayCommTo = [tblAgent].[PayCommTo]
from tblCommission
INNER JOIN tblAgent ON tblCommission.COMMagent = tblAgent.AGENTid
GO
