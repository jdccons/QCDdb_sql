USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_Refresh_Temp]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Refresh_Temp]
AS
/* ============================================================
	Object:			usp_Refresh_Temp
	Author:			John Criswell
	Create date:	2015-10-13	 
	Description:	Copies data from prod to temp		
							
	Change Log:
	-----------------------------------------------------------
	Change Date		Versions	Changed by		Reason
	2015-10-13		1.0			J Criswell		Created.
	2015-10-14		2.0			J Criswell		Added group table.
	2015-10-15		3.0			J Criswell		Added rates table.
	2015-10-18		4.0			J Criswell		Added assign EIMBRID
	2015-10-23		5.0			J Criswell		Error handling code
	2015-11-10		6.0			J Criswell		Added an insert for group agents
	
=============================================================== */
/*  declarations  */
DECLARE @LastOperation VARCHAR(128), @ErrorMessage VARCHAR(8000), 
	@ErrorSeverity INT, @ErrorState INT

BEGIN TRY
	BEGIN TRANSACTION
	
	/*  drop foreign keys  */
	SELECT @LastOperation = 'drop foreign keys'
	PRINT @LastOperation	
	
	SELECT @LastOperation = 'drop FK_tblSubscr_tblGrp'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(
					N'[dbo].[FK_tblSubscr_tblGrp]')
				AND parent_object_id = OBJECT_ID(
					N'[dbo].[tblSubscr]')
			)
		ALTER TABLE [dbo].[tblSubscr]
	DROP CONSTRAINT [FK_tblSubscr_tblGrp]
	PRINT @LastOperation
	
	-- FK_tblSubscr_tblRates
	SELECT @LastOperation = 'drop FK_tblSubscr_tblRates'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(
					N'[dbo].[FK_tblSubscr_tblRates]')
				AND parent_object_id = OBJECT_ID(
					N'[dbo].[tblSubscr]')
			)
		ALTER TABLE [dbo].[tblSubscr]
	DROP CONSTRAINT [FK_tblSubscr_tblRates]
	PRINT @LastOperation
	
	-- FK_tblSubscr_tblRates_GrpID_PlanID_CoverID]
	SELECT @LastOperation = 'drop FK_tblSubscr_tblRates_GrpID_PlanID_CoverID'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(
					N'[dbo].[FK_tblSubscr_tblRates_GrpID_PlanID_CoverID]'
				)
				AND parent_object_id = OBJECT_ID(N'[dbo].[tblSubscr]')
			)
		ALTER TABLE [dbo].[tblSubscr]
	DROP CONSTRAINT [FK_tblSubscr_tblRates_GrpID_PlanID_CoverID]
	PRINT @LastOperation

	-- FK_tblDependent_tblSubscr
	SELECT @LastOperation = 'drop FK_tblDependent_tblSubscr'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(
					N'[dbo].[FK_tblDependent_tblSubscr]')
				AND parent_object_id = OBJECT_ID(
					N'[dbo].[tblDependent]')
			)
		ALTER TABLE [dbo].[tblDependent]
	DROP CONSTRAINT [FK_tblDependent_tblSubscr]
	PRINT @LastOperation
	
	-- FK_tblRates_tblCoverage
	SELECT @LastOperation = 'drop FK_tblRates_tblCoverage'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(
					N'[dbo].[FK_tblRates_tblCoverage]')
				AND parent_object_id = OBJECT_ID(N'[dbo].[tblRates]')
			)
		ALTER TABLE [dbo].[tblRates]
	DROP CONSTRAINT [FK_tblRates_tblCoverage]
	PRINT @LastOperation
	
	-- FK_tblRates_tblPlans
	SELECT @LastOperation = 'drop FK_tblRates_tblPlans'
	IF EXISTS (
			SELECT *
			FROM sys.foreign_keys
			WHERE object_id = OBJECT_ID(N'[dbo].[FK_tblRates_tblPlans]')
				AND parent_object_id = OBJECT_ID(N'[dbo].[tblRates]')
			)
		ALTER TABLE [dbo].[tblRates]
	DROP CONSTRAINT [FK_tblRates_tblPlans]
	PRINT @LastOperation


	/*  end of drop foreign keys  */

	-- groups
	SELECT @LastOperation = 'transfer groups to temp'
	DELETE
	FROM tblGrp;

	SET IDENTITY_INSERT tblGrp ON;
	INSERT INTO tblGrp (
		ID, GroupID, GRName, GRGeoID, GRStreet1, GRStreet2, GRCity, GRState
		, GRZip, GRPhone1, GRPhone2, GRFax, GRMainCont, GRSrvCont, 
		GRMarkDir, GRContBeg, GRContEnd, GRClassKey, [GRAgent%], 
		GRNotes, GRClientSvcRepID, GREE, GRAnnvDate, GRFirstInvAmt, 
		GRSubLabelsPrinted, DateCreated, DateUpdated, GRCancelled, 
		GRAcctMgr, GRCardStock, GRMailCard, GRInvSort, GREmail, 
		GRMainContTitle, GRSrvConTitle, GRInitialSubscr, GRHold, 
		GRCancelledDate, GRReinstatedDate, Ins, GroupType, 
		InvoiceType, OrthoCoverage, OrthoLifeTimeLimit, 
		WaitingPeriod, RecUserID, RecDate, RecTime, User01, User02, 
		User03, User04, User05, User06, User07, User08, User09, 
		DateModified
		)
	SELECT ID, GroupID, GRName, GRGeoID, GRStreet1, GRStreet2, GRCity, 
		GRState, GRZip, GRPhone1, GRPhone2, GRFax, GRMainCont, 
		GRSrvCont, GRMarkDir, GRContBeg, GRContEnd, GRClassKey, 
		[GRAgent%], GRNotes, GRClientSvcRepID, GREE, GRAnnvDate, 
		GRFirstInvAmt, GRSubLabelsPrinted, DateCreated, DateUpdated, 
		GRCancelled, GRAcctMgr, GRCardStock, GRMailCard, GRInvSort, 
		GREmail, GRMainContTitle, GRSrvConTitle, GRInitialSubscr, 
		GRHold, GRCancelledDate, GRReinstatedDate, Ins, GroupType, 
		InvoiceType, OrthoCoverage, OrthoLifeTimeLimit, 
		WaitingPeriod, RecUserID, RecDate, RecTime, User01, User02, 
		User03, User04, User05, User06, User07, User08, User09, 
		DateModified
	FROM QCDdataSQL2005..tblGrp AS tblGrp_1;
	SET IDENTITY_INSERT tblGrp OFF;
	PRINT @LastOperation

	-- subscribers
	SELECT @LastOperation = 'transfer subscribers to temp'
	DELETE
	FROM tblSubscr;

	SET IDENTITY_INSERT tblSubscr ON;
	INSERT INTO tblSubscr (
		ID, SubSSN, SubID, EIMBRID, SubStatus, SubGroupID, PltCustKey, 
		PlanID, CoverID, RateID, SubCancelled, Sub_LUName, SubLastName
		, SubFirstName, SubMiddleName, SubStreet1, SubStreet2, SubCity
		, SubState, SubZip, SubPhoneWork, SubPhoneHome, SubEmail, 
		SubDOB, DepCnt, SubGender, SubAge, SubMaritalStatus, 
		SubEffDate, SubExpDate, PreexistingDate, SubCardPrt, 
		SubCardPrtDte, SubNotes, TransactionType, SubContBeg, 
		SubContEnd, SubPymtFreq, SubGeoID, SubBankDraftNo, Flag, 
		UserName, DateCreated, DateUpdated, DateDeleted, 
		SubFlyerPrtDte, SubRate, SubCOBRA, SubLOA, SubMissing, 
		CreateDate, AmtPaid, wSubID, User01, User02, User03
		, User04, User05, User06, User07, User08, User09, Email
		)
	SELECT ID, SubSSN, SubID, EIMBRID, SubStatus, SubGroupID, PltCustKey, 
		PlanID, CoverID, RateID, SubCancelled, Sub_LUName, SubLastName
		, SubFirstName, SubMiddleName, SubStreet1, SubStreet2, SubCity
		, SubState, SubZip, SubPhoneWork, SubPhoneHome, SubEmail, 
		SubDOB, DepCnt, SubGender, SubAge, SubMaritalStatus, 
		SubEffDate, SubExpDate, PreexistingDate, SubCardPrt, 
		SubCardPrtDte, SubNotes, TransactionType, SubContBeg, 
		SubContEnd, SubPymtFreq, SubGeoID, SubBankDraftNo, Flag, 
		UserName, DateCreated, DateUpdated, DateDeleted, 
		SubFlyerPrtDte, SubRate, SubCOBRA, SubLOA, SubMissing, 
		CreateDate, AmtPaid, wSubID, User01, User02, User03
		, User04, User05, User06, User07, User08, User09, Email
	FROM QCDdataSQL2005..tblSubscr AS tblSubscr_1;
	SET IDENTITY_INSERT tblSubscr OFF;
	PRINT @LastOperation

	-- dependents
	SELECT @LastOperation = 'transfer dependents to temp'
	DELETE
	FROM tblDependent;

	SET IDENTITY_INSERT tblDependent ON;
	INSERT INTO tblDependent (
		ID, SubID, DepSubID, DepSSN, EIMBRID, DepFirstName, DepMiddleName, 
		DepLastName, DepDOB, DepAge, DepRelationship, DepGender, 
		DepEffDate, PreexistingDate, CreateDate, User01, 
		User02, User03, User04, User05, User06, User07, User08, User09
		)
	SELECT ID, SubID, DepSubID, DepSSN, EIMBRID, DepFirstName, 
		DepMiddleName, DepLastName, DepDOB, DepAge, DepRelationship, 
		DepGender, DepEffDate, PreexistingDate, CreateDate, 
		User01, User02, User03, User04, User05, User06, 
		User07, User08, User09
	FROM QCDdataSQL2005..tblDependent AS tblDependent_1;
	SET IDENTITY_INSERT tblDependent OFF;
	PRINT @LastOperation
	
	-- rates
	SET IDENTITY_INSERT tblRates ON;
	SELECT @LastOperation = 'transfer rates to temp'
	DELETE
	FROM tblRates;
	INSERT INTO tblRates (RateID, GroupID, PlanID, CoverID, Rate)
	SELECT RateID, GroupID, PlanID, CoverID, Rate
	FROM QCDdataSQL2005..tblRates AS tblRates_1
	SET IDENTITY_INSERT tblRates OFF;
	PRINT @LastOperation
	
	SET IDENTITY_INSERT tblGrpAgt ON;
	SELECT @LastOperation = 'transfer group agents to temp'
	INSERT INTO tblGrpAgt (
		ID 
		, AgentId
		, GroupId
		, [Primary]
		, AgentRate
		, CommOwed
		, Sort
		, DateModified
		)
	SELECT ID
		, AgentId
		, GroupId
		, [Primary]
		, AgentRate
		, CommOwed
		, Sort
		, DateModified
	FROM QCDdataSQL2005..tblGrpAgt AS tblGrpAgt_1
	SET IDENTITY_INSERT tblGrpAgt OFF;
	PRINT @LastOperation



	/* create foreign keys  */	
	SELECT @LastOperation = 'create foreign keys'
	PRINT @LastOperation
	-- FK_tblSubscr_tblGrp
	SELECT @LastOperation = 'create FK_tblSubscr_tblGrp'
	ALTER TABLE [dbo].[tblSubscr]
		WITH CHECK ADD CONSTRAINT [FK_tblSubscr_tblGrp] FOREIGN KEY ([SubGroupID]
				) REFERENCES [dbo].[tblGrp]([GroupID])
	ALTER TABLE [dbo].[tblSubscr] CHECK CONSTRAINT [FK_tblSubscr_tblGrp]
	PRINT @LastOperation

	-- FK_tblSubscr_tblRates
	SELECT @LastOperation = 'create FK_tblSubscr_tblRates'
	ALTER TABLE [dbo].[tblSubscr]
		WITH NOCHECK ADD CONSTRAINT [FK_tblSubscr_tblRates] FOREIGN KEY ([RateID]
				) REFERENCES [dbo].[tblRates]([RateID]) ON
	UPDATE CASCADE
	ALTER TABLE [dbo].[tblSubscr] CHECK CONSTRAINT [FK_tblSubscr_tblRates]
	PRINT @LastOperation
	
	-- FK_tblSubscr_tblRates_GrpID_PlanID_CoverID
	SELECT @LastOperation = 'create FK_tblSubscr_tblRates_GrpID_PlanID_CoverID'
	ALTER TABLE [dbo].[tblSubscr]
		WITH CHECK ADD CONSTRAINT 
			[FK_tblSubscr_tblRates_GrpID_PlanID_CoverID] FOREIGN KEY ([SubGroupID], [PlanID], [CoverID]
				) REFERENCES [dbo].[tblRates]([GroupID], [PlanID], 
				[CoverID])
	ALTER TABLE [dbo].[tblSubscr] CHECK CONSTRAINT 
		[FK_tblSubscr_tblRates_GrpID_PlanID_CoverID]
	PRINT @LastOperation
	
	-- FK_tblDependent_tblSubscr
	SELECT @LastOperation = 'create FK_tblDependent_tblSubscr'
	ALTER TABLE [dbo].[tblDependent]
		WITH CHECK ADD CONSTRAINT [FK_tblDependent_tblSubscr] FOREIGN KEY ([DepSubID]
				) REFERENCES [dbo].[tblSubscr]([SubSSN]) ON
	UPDATE CASCADE
		ON
	DELETE CASCADE
	ALTER TABLE [dbo].[tblDependent] CHECK CONSTRAINT 
		[FK_tblDependent_tblSubscr]
	PRINT @LastOperation
		
	-- FK_tblRates_tblCoverage
	SELECT @LastOperation = 'create FK_tblRates_tblCoverage'
	ALTER TABLE [dbo].[tblRates]
		WITH CHECK ADD CONSTRAINT [FK_tblRates_tblCoverage] FOREIGN KEY ([CoverID]
				) REFERENCES [dbo].[tblCoverage]([CoverID]) ON
	UPDATE CASCADE
	ALTER TABLE [dbo].[tblRates] CHECK CONSTRAINT 
		[FK_tblRates_tblCoverage]
	PRINT @LastOperation

	-- FK_tblRates_tblPlans
	SELECT @LastOperation = 'create FK_tblRates_tblPlans'
	ALTER TABLE [dbo].[tblRates]
		WITH CHECK ADD CONSTRAINT [FK_tblRates_tblPlans] FOREIGN KEY ([PlanID]
				) REFERENCES [dbo].[tblPlans]([PlanID]) ON
	UPDATE CASCADE
	ALTER TABLE [dbo].[tblRates] CHECK CONSTRAINT [FK_tblRates_tblPlans]
	PRINT @LastOperation
	
	/*  end of create foreign keys  */
	
	/*  assign EIMBRIDs  */
	
	/*  update EIMBRID on tblSubscr  */
	SELECT @LastOperation = 'assign EIMBRID to subscribers'
	UPDATE tblSubscr
	SET EIMBRID = SubSSN + '00'
	, User01 = 'refresh temp from prod'
	, User02 = 'set EIMBRID'
	, User04 = GETDATE()	
	PRINT @LastOperation

	
	/*  update EIMBRID on tblDependent  */
	SELECT @LastOperation = 'assign EIMBRID to dependents'
	UPDATE d
	SET EIMBRID = m.EIMBRID
	, User01 = 'refresh temp from prod'
	, User02 = 'set EIMBRID'
	, User04 = GETDATE()
	FROM tblDependent d
	INNER JOIN (
			SELECT ID, DepSubID + '0' + CONVERT(NVARCHAR(2), RANK() OVER (
						PARTITION BY DepSubID ORDER BY ISNULL(DepDOB, '1901-01-01 00:00:00'), 
							DepLastName, DepFirstName
						)) EIMBRID
			FROM tblDependent
			) m
	ON d.ID = m.ID
	PRINT @LastOperation
	
	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	SELECT @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: ' + 
		@LastOperation, @ErrorSeverity = ERROR_SEVERITY(), 
		@ErrorState = ERROR_STATE()

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState
			)
END CATCH
GO
