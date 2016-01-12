USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Ind]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Ind]
@ReturnParm VARCHAR(255) OUTPUT 
AS


/* ================================================================
	Object:		    usp_EDI_App_Ind	
	Author:			John Criswell
	Create date:	10/12/2013	 
	Description:	Fetches all individual
					subscribers and dependents
					from website and inserts them into 
					temporary tables
	Parameters:		None
	Where use:		frmOnlineEnrollmentProcessing
					(used to download individual,
					initial, and maintenance subscribers
					from the website; this procedure
					process individual subscribers)
					
	Change Log:
	---------------------------------------------------------------
	Change Date		Version		Changed by		Reason
	2015-02-23		2.0			JCriswell		Added error handling
	
	
=================================================================== */

SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE	@LastOperation varchar(128), 
		@ErrorMessage varchar(8000), 
		@ErrorSeverity int, 
		@ErrorState int

------------------------------------------------------------------------------
BEGIN TRY
	BEGIN TRANSACTION

	/*   ---   get web data   ---   */
	-- fetch indiv subscribers
	SELECT	@LastOperation = 'fetch individual subscribers'
	IF EXISTS (SELECT
		1
	FROM
		[TRACENTRMTSRV].QCD.dbo.vwIndSub
	WHERE
		(Download = 'Yes'
		AND MembershipStatus IN ( 'Added', 'Changed', 'Deleted' )))
	    
	TRUNCATE TABLE tblSubscriber_temp

	/*  insert the new individual subscribers into a local table  */
	INSERT  INTO tblSubscriber_temp
			( SSN, EIMBRID, SubscriberID, GroupID, PlanID, CoverID, LastName,
			  FirstName, MiddleInitial, Street1, Street2, City, State, Zip,
			  PhoneWork, PhoneHome, Email, DOB, DepCnt, Gender, Age,
			  EffectiveDate, PreexistingDate, EmploymentStatus, Occupation_Title,
			  MaritalStatus, CardPrinted, CardPrintedDate, MembershipStatus,
			  DateCreated, DateChanged, DateDeleted, Download, DownloadDate,
			  wSubID, AmtPaid )
			SELECT
				SSN, EIMBRID, SubscriberID, GroupID, PlanID, CoverID, LastName,
				FirstName, MiddleInitial, Street1, Street2, City, State, Zip,
				PhoneWork, PhoneHome, Email, DOB, DepCnt, Gender, Age,
				EffectiveDate, PreexistingDate, EmploymentStatus, Occupation_Title,
				MaritalStatus, CardPrinted, CardPrintedDate, MembershipStatus,
				DateCreated, DateChanged, DateDeleted, Download, DownloadDate,
				wSubID, AmtPaid
			FROM
				[TRACENTRMTSRV].QCD.dbo.vwIndSub AS inds
			WHERE
				( Download = 'Yes' )
				AND ( MembershipStatus IN ( 'Added', 'Changed', 'Deleted' ) )

	/*  ---  fetch individual depdendents   ---  */
	SELECT	@LastOperation = 'fetch individual depdendents'
	IF EXISTS (SELECT
		1
	FROM
		[TRACENTRMTSRV].QCD.dbo.vwDepDwnInd)
	    
	TRUNCATE TABLE tblDependent_temp

	INSERT  INTO tblDependent_temp
			( SubSSN, EIMBRID, DepSSN, FirstName, MiddleInitial, LastName, DOB,
			  Age, Relationship, Gender, EffDate, PreexistingDate )
			SELECT
				SubSSN, EIMBRID, DepSSN, FirstName, MiddleInitial, LastName, DOB,
				Age, Relationship, Gender, EffDate, PreexistingDate
			FROM
				[TRACENTRMTSRV].QCD.dbo.vwDepDwnInd AS indd

	/*   move individuals to EDI_App_Subscr   */
	SELECT	@LastOperation = 'move individuals to EDI_App_Subscr'
	IF EXISTS (SELECT
		1
	FROM
		tblEDI_App_Subscr)
	            
	TRUNCATE TABLE tblEDI_App_Subscr

	INSERT  INTO tblEDI_App_Subscr
			( SubSSN, EIMBRID, SubID, SubStatus, SubGroupID, PlanID, CoverID,
			  SubLastName, SubFirstName, SubMiddleName, SUB_LUname, SubStreet1,
			  SubStreet2, SubCity, SubState, SubZip, SubPhoneHome, SubPhoneWork,
			  SUBdob, DepCnt, SubGender, SubAge, SubEffDate, PreexistingDate,
			  SubMaritalStatus, SubCardPrt, SubCardPrtDte, TransactionType,
			  DateCreated, DateUpdated, DateDeleted, wSubID, wUpt, AmtPaid )
			SELECT
				t.SSN, 
				t.EIMBRID, 
				ISNULL(t.SubscriberID,'') SubscriberID, 
				'INDIV' AS [Status], 
				RTRIM(t.GroupID) GroupID,
				t.PlanID, 
				t.CoverID, 
				RTRIM(t.LastName) LastName, 
				RTRIM(t.FirstName) FirstName, 
				RTRIM(t.MiddleInitial) MiddleInitial,
				RTRIM([LastName]) + ', ' + RTRIM([FirstName]) + ' ' + SUBSTRING([MiddleInitial],1, 1) AS LU_Name,
				RTRIM(t.Street1) Street1, 
				RTRIM(LTRIM(t.Street2)) Street2, 
				RTRIM(t.City) City, 
				RTRIM(t.[State]) [State], 
				RTRIM(t.Zip) Zip,
				REPLACE(t.PhoneHome, '-', '') PhoneHome,
				REPLACE(t.PhoneWork, '-', '') PhoneWork, 
				t.DOB, 
				t.DepCnt,
				RTRIM(t.Gender) Gender, 
				t.Age, t.EffectiveDate, t.PreexistingDate,
				RTRIM(t.MaritalStatus) MaritalStatus, 
				t.CardPrinted, t.CardPrintedDate,
				RTRIM(t.MembershipStatus) MembershipStatus, 
				t.DateCreated, t.DateChanged, t.DateDeleted,
				t.wSubID, 
				1 AS setU, 
				t.AmtPaid
			FROM
				tblSubscriber_temp t
			WHERE
				( ( ( t.EIMBRID ) IN ( 'INDIV' )) );

	--update fields from tblSubscr 
	SELECT	@LastOperation = 'update fields from tblSubscr'
	UPDATE
		eas
	SET eas.SubID = s.SubID, 
		eas.SubCardPrt = s.SUBcardPRT,
		eas.SubCardPrtDte = s.SUBcardPRTdte, 
		eas.SubNotes = s.SUBnotes
	FROM
		tblEDI_App_Subscr eas
			INNER JOIN tblSubscr s
				ON eas.SubSSN = s.SubSSN

	--update rate id's for individuals
	SELECT	@LastOperation = 'update rate ids for individuals'
	UPDATE
		eas
	SET eas.RateID = r.RateID
	FROM
		tblEDI_App_Subscr AS eas
		INNER JOIN tblRates AS r
			ON eas.CoverID = r.CoverID
			   AND eas.PlanID = r.PlanID
			   AND eas.SubGroupID = r.GroupID
			   AND eas.SubStatus = 'INDIV'  

	/*   ---   move individual dependents to EDI_App_Dep   ---   */
	SELECT	@LastOperation = 'move individual dependents to EDI_App_Dep'
	IF EXISTS (SELECT
		1
	FROM
		tblEDI_App_Dep)
	   
	TRUNCATE TABLE tblEDI_App_Dep

	INSERT  INTO tblEDI_App_Dep
			( DEPssn, EIMBRID, DEPsubID, DEPfirstNAME, DEPlastNAME, DEPmiddleNAME,
			  DepDOB, DepAge, DepRelationship, DEPgender, DepEffDate,
			  PreexistingDate )
			SELECT
				td.DepSSN, td.EIMBRID, td.SubSSN, td.FirstName, td.LastName,
				td.MiddleInitial, td.DOB, td.Age, td.Relationship,
				SUBSTRING(td.[Gender], 1, 1) AS DepGender, td.EffDate,
				td.PreexistingDate
			FROM
				tblDependent_temp td
				INNER JOIN tblSubscriber_temp ts
					ON td.SubSSN = ts.SSN
			WHERE
				( ( ( ts.MembershipStatus ) = 'Added'
					OR ( ts.MembershipStatus ) = 'Changed'
				  )
				  AND ( ( ts.GroupID ) IN ( 'INDV1', 'INDV2' ) )
				);

	/*  clean up data on EDI_App_Subscr  */
	--fix dep cnts
	SELECT	@LastOperation = 'fix dep cnts'
	UPDATE
		s
	SET s.DepCnt = depcnt.DepCnt
	FROM
		tblEDI_App_Subscr s
		INNER JOIN ( SELECT
						SubSSN, dbo.udf_EDI_App_Subscr_DepCnt(SubSSN) DepCnt
					 FROM
						tblEDI_App_Subscr ) depcnt
			ON s.SubSSN = depcnt.SubSSN
	        
	--fix CoverIDs
	SELECT	@LastOperation = 'fix CoverIDs'
	UPDATE
		s
	SET s.CoverID = c.CoverId
	FROM
		tblEDI_App_Subscr s
		INNER JOIN ( SELECT
						s.SubSSN, gct.TierCnt,
						dbo.udf_EDI_App_Subscr_CoverID(s.SubSSN, gct.TierCnt) CoverID
					 FROM
						tblEDI_App_Subscr AS s
						INNER JOIN tblGrp g
							ON s.SubGroupID = g.GroupID
						INNER JOIN vw_Group_Coverage_Tiers gct
							ON g.GroupID = gct.GroupID ) c
			ON s.SubSSN = c.SubSSN

	--add the coverage description for the export file to the TPA
	SELECT	@LastOperation = 'add the coverage description for the export file to the TPA'
	UPDATE
		eas
	SET eas.Coverage = c.CoverDescr, eas.CoverDesc = c.CoverDescr
	FROM
		tblEDI_App_Subscr AS eas
		INNER JOIN tblRates AS r
			ON eas.CoverID = r.CoverID
			   AND eas.PlanId = r.PlanId
			   AND eas.SubGroupID = r.GroupID
		INNER JOIN tblCoverage AS c
			ON r.CoverID = c.CoverID

	COMMIT TRANSACTION
	SET @ReturnParm = 'Procedure succeeded'
END TRY

-- Error Handler
BEGIN CATCH 
    IF @@TRANCOUNT > 0 
        ROLLBACK
        
	SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
            + @LastOperation ,
            @ErrorSeverity = ERROR_SEVERITY() ,
            @ErrorState = ERROR_STATE()
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    EXEC usp_CallProcedureLog 
	@ObjectID       = @@PROCID,
	@AdditionalInfo = @LastOperation;
    SET @ReturnParm = 'Procedure Failed'
END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Fetches all individual subscribers and dependents from website and inserts them into temporary tables' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_App_Ind'
GO
