USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_WebsiteSyncDwnld]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_WebsiteSyncDwnld]



AS


	UPDATE [TRACENTRMTSRV].QCD.dbo.tblSubscriber
	SET lSubID = ls.SubID,
		SubscriberID = ls.SubID,
		Download = NULL,
		DownloadDate = (Convert(varchar,GetDate(),101)),
		SSN = ls.SubSSN,
		SubscriberID = ls.SubID,
		CoverID = ls.CoverID 
	FROM [TRACENTRMTSRV].QCD.dbo.tblSubscriber AS rs 
	INNER JOIN tblEDI_App_Subscr AS ls ON rs.SubID = ls.wSubID 
	WHERE ls.wUpt = 0

	
	UPDATE [TRACENTRMTSRV].QCD.dbo.tblSubscriber
	SET lSubID = ls.SubID,
		SubscriberID = ls.SubID,
		Download = NULL,
		DownloadDate = (Convert(varchar,GetDate(),101))
	FROM [TRACENTRMTSRV].QCD.dbo.tblSubscriber AS rs 
	INNER JOIN tblEDI_App_Subscr_delete AS ls ON rs.SubID = ls.wSubID 
	WHERE ls.wUpt = 0
GO
