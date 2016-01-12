USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspSubscrImport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspSubscrImport    Script Date: 3/18/2009 7:01:33 PM ******/

/****** Object:  Stored Procedure dbo.uspSubscrImport    Script Date: 3/18/2009 9:06:36 AM ******/

CREATE PROCEDURE [dbo].[uspSubscrImport]

AS

INSERT INTO tblSubscr ( SUBssn
, SubID
, EIMBRID
, PlanID
, CoverID
, RateID
, SUBfirstNAME
, SUBmiddleNAME
, SUBlastNAME
, SUBstreet1
, SUBstreet2
, SUBcity
, SUBstate
, SUBzip
, SUBphoneWORK
, SUBphoneHOME
, SUBgroupID
, SUBdob
, DepCnt
, SUBstatus
, PreexistingDate
, SUBeffDATE
, SUBclassKEY
, SUBexpDATE
, SUBcardPRT
, SUBcardPRTdte
, SUBnotes
, SUBcontBEG
, SUBcontEND
, SUBpymtFREQ
, SUB_LUname
, SUBgeoID
, DateCreated
, DateUpdated
, SUBcancelled
, SUBbankDraftNo
, Flag
, SUBgender
, SubAge )
SELECT tblEDI_App_Subscr.SUBssn
, tblEDI_App_Subscr.SubID
, tblEDI_App_Subscr.EIMBRID
, tblEDI_App_Subscr.PlanID
, tblEDI_App_Subscr.CoverID
, tblEDI_App_Subscr.RateID
, UPPER([SUBfirstNAME]) AS FirstName
, UPPER([SUBmiddleNAME]) AS MiddleName
, UPPER([SUBlastNAME]) AS LastName
, tblEDI_App_Subscr.SUBstreet1
, tblEDI_App_Subscr.SUBstreet2
, tblEDI_App_Subscr.SUBcity
, tblEDI_App_Subscr.SUBstate
, tblEDI_App_Subscr.SUBzip
, tblEDI_App_Subscr.SUBphoneWORK
, tblEDI_App_Subscr.SUBphoneHOME
, tblEDI_App_Subscr.SUBgroupID
, tblEDI_App_Subscr.SUBdob
, tblEDI_App_Subscr.DepCnt
, tblEDI_App_Subscr.SUBstatus
, tblEDI_App_Subscr.PreexistingDate
, tblEDI_App_Subscr.SUBeffDATE
, tblEDI_App_Subscr.SUBclassKEY
, tblEDI_App_Subscr.SUBexpDATE
, tblEDI_App_Subscr.SUBcardPRT
, tblEDI_App_Subscr.SUBcardPRTdte
, tblEDI_App_Subscr.SUBnotes
, tblEDI_App_Subscr.SUBcontBEG
, tblEDI_App_Subscr.SUBcontEND
, tblEDI_App_Subscr.SUBpymtFREQ
, UPPER([SUB_LUname]) AS LU_Name
, tblEDI_App_Subscr.SUBgeoID
, tblEDI_App_Subscr.DateCreated
, tblEDI_App_Subscr.DateUpdated
, tblEDI_App_Subscr.SUBcancelled
, tblEDI_App_Subscr.SUBbankDraftNo
, tblEDI_App_Subscr.Flag
, (CASE 
	WHEN tblEDI_App_Subscr.SubGender Is Null 
	THEN 'O' 
	ELSE tblEDI_App_Subscr.SubGender
	END) As Gender
, SubAge
FROM tblEDI_App_Subscr
GO
