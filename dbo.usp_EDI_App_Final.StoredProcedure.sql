USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Final]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Final] (
	@GroupID AS VARCHAR(5)
	, @PlanID AS INTEGER
	)
AS
/* ======================================================================================
  Object:			usp_EDI_App_Final
  Author:			John Criswell
  Create date:		2015-02-23 
  Description:		Moves data from EDI temp tables
					to permanent tables - tblSubscr,
					tblDependent
  Parameters:		GroupID varchar(5), PlanID integer
  Where Used:		frmImportProcessing (processes 
					flat files from QCD Only customers)
				
  Change Log:
  ---------------------------------------------------------------------------------------
  Change Date		Version			Changed by		Reason
  2015-02-23		1.0				JCriswell		Created	
  2015-03-06		2.0				JCriswell		changed insert into tblSubscr
													to include hardcoded 1 as SubCancelled
  2015-12-01		3.0				JCriswell		Removed several fields
	
========================================================================================= */
SET NOCOUNT ON

BEGIN
	DECLARE @FileID UNIQUEIDENTIFIER

	-- add records to permanent subscriber table
	INSERT INTO tblSubscr (
		SUBssn
		, SubID
		, PlanID
		, CoverID
		, RateID
		 /*  version 2 update */ 
		, SubCancelled
		, PLTcustKEY
		, SUBfirstNAME
		, SUBmiddleNAME
		, SUBlastNAME
		, SUBstreet1
		, SUBstreet2
		, SUBcity
		, SUBstate
		, SUBzip
		, SUBphoneHOME
		, SUBphoneWORK
		, SUBgroupID		
		/*
		  version 3 update
		, SUBemployeeName
		*/
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
		/*
		  version 3 update
		, SUBagentID1
		, SUBagentRATE1
		, SUBagentID2
		, SUBagentRATE2
		, GRExecSalesDirID
		, GRExecSalesDirRate		
		*/
		, SUBmissing
		, DateCreated
		, DateUpdated
		, SUBbankDraftNo
		, SUBCOBRA
		, SUBLOA
		, SUBflyerPRTdte
		, Flag
		, SUBgender
		, SubAge
		)
	SELECT e.SubSSN
		, e.SubID
		, e.PlanID
		, e.CoverID
		, e.RateID		
		/*  version 2 updated  */
		, 1 AS SubCancelled
		, e.PltCustKey
		, UPPER([SUBfirstNAME]) AS FirstName
		, UPPER([SUBmiddleNAME]) AS MI
		, UPPER([SUBlastNAME]) AS LastName
		, e.SubStreet1
		, e.SubStreet2
		, e.SubCity
		, e.SubState
		, e.SubZip
		, e.SubPhoneHome
		, e.SubPhoneWork
		, e.SubGroupID		
		/*
		, e.SUBemployeeName
		*/
		, e.SUBdob
		, e.DepCnt
		, e.SubStatus
		, e.PreexistingDate
		, e.SubEffDate
		, e.SubClassKey
		, e.SubExpDate
		, e.SubCardPrt
		, e.SubCardPrtDte
		, e.SubNotes
		, e.SubContBeg
		, e.SubContEnd
		, e.SubPymtFreq
		, UPPER([SUB_LUname]) AS LU_Name
		, e.SubGeoID		
		/*
		, e.SUBagentID1
		, e.SUBagentRATE1
		, e.SUBagentID2
		, e.SUBagentRATE2
		, e.GRExecSalesDirID
		, e.GRExecSalesDirRate
		*/
		, e.SUBmissing
		, e.DateCreated
		, e.DateUpdated
		, e.SUBbankDraftNo
		, e.SUBCOBRA
		, e.SUBLOA
		, e.SUBflyerPRTdte
		, e.Flag
		, CASE e.SubGender WHEN '' THEN 'O' WHEN NULL THEN 'O' ELSE e.
				SubGender END gender
		, e.SubAge
	FROM tblEDI_App_Subscr e
	WHERE (
			(
				(e.TransactionType) IS NULL
				OR (e.TransactionType) <> 'T'
				)
			);

	-- add records to permanent dependent table
	INSERT INTO tblDependent (
		DepSSN
		, DepSubID
		, DepFirstName
		, DepMiddleName
		, DepLastName
		, DepDOB
		, DepAge
		, DepGender
		, DepRelationship
		, DepEffDate
		, PreexistingDate
		)
	SELECT de.DepSSN
		, de.DepSubID
		, UPPER(de.DepFirstName) AS FirstName
		, UPPER(de.DepMiddleName) AS MI
		, UPPER(de.DepLastName) AS LastName
		, de.DepDOB
		, de.DepAge
		, CASE DepGender WHEN '' THEN 'O' WHEN NULL THEN 'O' ELSE de.
				DepGender END AS Gender
		, de.DepRelationship
		, de.DepEffDate
		, de.PreexistingDate
	FROM tblEDI_App_Subscr AS se
	RIGHT OUTER JOIN tblEDI_App_Dep AS de
		ON se.SubSSN = de.DepSubID
			--where   ( se.TransactionType = 'T' )
END
GO
