USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_final_dep]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_tpa_final_dep]
(			@UserName nvarchar(50),
			@Path nvarchar(50),
			@File nvarchar(50)

)
AS
/* ==============================================================
	Object:			usp_tpa_final_dep
	Author:			John Criswell
	Create date:	10/18/2015 
	Description:	final insert into tblDependent from tpa file
								
							
	Change Log:
	-------------------------------------------------------------
	Change Date	Version		Changed by		Reason
	2015-10-17	1.0			J Criswell		Created.
	2015-10-19	2.0			J Criswell		Modified logic for relationship value
	2015-10-22	3.0			J Criswell		Added code to terminate dependents
	2015-10-23	4.0			J Criswell		Added and update to terminate deps;
											DepCancelled=3
	2015-11-10	5.0			J Criswell		Remove output parameter and replaced with a 
											return parameter
	2015-11-10	6.0			J Criswell		Added UserName parameter
	2015-11-30	7.0			J Criswell		Added parameters (Path and File - they are not really used)
================================================================= */
/*  ------------------  declarations  --------------------  */ 
SET NOCOUNT ON;
SET XACT_ABORT ON;
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT

	DECLARE @DT_UPDT AS DATETIME
/*  ------------------------------------------------------  */

BEGIN TRY
   BEGIN TRANSACTION
		/*  variable assignments  */
		SET @DT_UPDT = (SELECT MAX(DT_UPDT) FROM tpa_data_exchange_dep);
		
		-- update all non-key fields for current dependents
		SELECT @LastOperation = 'update all non-key tblDependent fields'

		IF EXISTS (
					-- matched dependents between qcd & tpa
					SELECT d.SubSSN
					FROM vw_GrpDep d
					INNER JOIN tpa_data_exchange_dep r
						ON d.EIMBRID = r.MBR_ID				
					WHERE d.GrpCancel = 'Active'
					AND d.GrpType = 'All American'
					AND d.SubCancel = 'Active'
					AND d.DepCancel = 'Active' 
					AND r.MBR_ST IN (1,2)				
				)
			UPDATE d
			SET d.DepLastName = ISNULL(r.LAST_NAME, ''), 
				d.DepFirstName = ISNULL(r.FIRST_NAME, ''), 
				d.DepMiddleName = ISNULL(r.MI, ''), 
				d.DepDOB = ISNULL(r.DOB, '1901-01-01 00:00:00'), 
				d.DepGender = ISNULL(r.GENDER, ''), 
				d.DepRelationship = 
					CASE 
						WHEN r.REL = 0 THEN ''
						WHEN r.REL = 1 THEN 'S'
						WHEN r.REL = 2 THEN 'C'
						WHEN r.REL = 3 THEN 'O'
						ELSE ''
					END, 
				d.SubID = r.SUB_ID, 
				d.ModifyDate = GETDATE(), 
				d.DepAge = dbo.fAgeCalc(ISNULL(d.DepDOB, '1901-01-01 00:00:00')), 
				d.DepEffDate = ISNULL(r.EFF_DT, '1901-01-01 00:00:00'), 
				d.PreexistingDate = ISNULL(r.PREX_DT, '1901-01-01 00:00:00'), 
				d.User01 = 'usp_tpa_final_dep', 
				d.User02 = 'update dependents from tpa file', 
				d.User04 = GETDATE(),
				d.UserName = @UserName
			FROM tblDependent d
				INNER JOIN tblSubscr s
					ON d.DepSubID = s.SubSSN
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
				INNER JOIN tpa_data_exchange_dep r
					ON d.EIMBRID = r.MBR_ID				
			WHERE g.GRCancelled = 0
			AND g.GroupType = 4
			AND ISNULL(d.DepCancelled, 1) = 1
			AND ISNULL(s.SubCancelled, 1) = 1 
			AND r.MBR_ST IN (1,2); 

		/*  add new dependents */
		SELECT  @LastOperation = 'add new dependents'
		IF EXISTS (
					/*  dep mis-match  */
					SELECT r.MBR_ID
					FROM tpa_data_exchange_dep r  -- tpa deps
					INNER JOIN tblGrp g
						ON r.GRP_ID = g.GroupID
					LEFT OUTER JOIN						
						(
						-- qcd deps
						SELECT d.EIMBRID
						FROM vw_GrpDep d
						WHERE d.GrpCancel = 'Active'
							AND d.GrpType = 'All American'
							AND d.SubCancel = 'Active'
							AND d.DepCancel = 'Active'
						) m
						ON ISNULL(r.MBR_ID, '') = ISNULL(m.EIMBRID, '')
					WHERE m.EIMBRID IS NULL
					AND r.MBR_ST IN (1,2)
		)
		
		/*  new dependents  */
		INSERT INTO tblDependent (
			DepSubID, SubID, DepSSN, EIMBRID, DepLastName, DepFirstName, 
			DepMiddleName, DepDOB, DepEffDate, PreexistingDate, DepGender, 
			DepRelationship, CreateDate, User01, User02, User04, Depcancelled,
			TransactionType, DateCreated, UserName
			)
			/*  dep mis-match */
			SELECT r.SSN, r.SUB_ID, r.DEP_SSN, r.MBR_ID, r.LAST_NAME, r.
				FIRST_NAME, ISNULL(r.MI, '') AS MI, r.DOB, r.EFF_DT, r.PREX_DT, r.GENDER, 
				CASE 
					WHEN r.REL = 0 THEN ''
					WHEN r.REL = 1 THEN 'S'
					WHEN r.REL = 2 THEN 'C'
					WHEN r.REL = 3 THEN 'O'
					ELSE ''
				END AS REL, 
				r.DT_UPDT, 'usp_tpa_final_dep' AS User01, 
				'insert new dependents from tpa file' AS User02, GETDATE() AS User04,
				1 AS DepCancelled,
				'ADDED' AS TransactionType,
				GETDATE() AS DateCreated,
				@UserName
			FROM tpa_data_exchange_dep r  -- tpa deps
			INNER JOIN tblGrp g
				ON r.GRP_ID = g.GroupID
			LEFT OUTER JOIN
				-- qcd deps
				(
				SELECT d.EIMBRID
				FROM vw_GrpDep d
				WHERE d.GrpCancel = 'Active'
					AND d.GrpType = 'All American'
					AND d.SubCancel = 'Active'
					AND d.DepCancel = 'Active'
				) m
			ON ISNULL(r.MBR_ID, '') = ISNULL(m.EIMBRID, '')
			WHERE m.EIMBRID IS NULL
			AND r.MBR_ST IN (1,2)
		
		/*  terminations  */		
		
		-- tpa identified terms
		SELECT  @LastOperation = 'tpa identified dependent terminations'
		IF EXISTS
		(
				SELECT r.SSN
				FROM tpa_data_exchange_dep r
					INNER JOIN tblDependent d
						ON r.MBR_ID = d.EIMBRID
				WHERE r.RCD_TYPE = 'D'
					AND r.MBR_ST = 3
					AND r.GRP_TYPE = 4
					AND ISNULL(d.DepCancelled,1) = 1			
		)
		UPDATE d
			SET d.DepLastName = ISNULL(r.LAST_NAME, '')
				, d.DepFirstName = ISNULL(r.FIRST_NAME, '')
				, d.DepMiddleName = ISNULL(r.MI, '')
				, d.DepDOB = ISNULL(r.DOB, '1901-01-01 00:00:00')
				, d.DepGender = ISNULL(r.GENDER, '')
				, d.DepRelationship = ISNULL(r.REL, '')
									--CASE 
									--	WHEN r.REL = 0 THEN '' 
									--	WHEN r.REL = 1 THEN 'S' 
									--	WHEN r.REL = 2 THEN 'C' 
									--	WHEN r.REL = 3 THEN 'O' 
									--	ELSE '' 
									--END
				, d.SubID = r.SUB_ID
				, d.ModifyDate = GETDATE()
				, d.DepAge = dbo.fAgeCalc(ISNULL(r.DOB, '1901-01-01 00:00:00'))
				, d.DepEffDate = ISNULL(r.EFF_DT, '1901-01-01 00:00:00')
				, d.PreexistingDate = ISNULL(r.PREX_DT, '1901-01-01 00:00:00')
				, d.User01 = 'usp_tpa_final_dep'
				, d.User02 = 'tpa identified dependent termination'
				, d.User04 = GETDATE()
				, d.DepCancelled = 3
				, d.TransactionType = 'DELETED'
				, d.DateDeleted = dbo.udf_GetLastDayOfMonth(@DT_UPDT)
				, d.UserName = @UserName			
			FROM tpa_data_exchange_dep r
					INNER JOIN tblDependent d
						ON r.MBR_ID = d.EIMBRID
			WHERE r.RCD_TYPE = 'D'
				AND r.MBR_ST = 3
				AND r.GRP_TYPE = 4
				AND ISNULL(d.DepCancelled,1) = 1;
		
		
		
		-- mis-match terminations
		SELECT  @LastOperation = 'mis-match dependent terminations'
		IF EXISTS 	(
					SELECT qcd.SSN
						, qcd.SUB_ID
						, qcd.DEP_SSN
						, qcd.MBR_ID
						, qcd.GRP_ID
					FROM (
						-- qcd deps
						SELECT d.SubSSN AS SSN
							, d.SubID AS SUB_ID
							, d.DepSSN AS DEP_SSN
							, d.EIMBRID AS MBR_ID
							, d.SubGroupID AS GRP_ID
						FROM vw_GrpDep AS d
						WHERE d.GrpCancel = 'Active'
							AND d.SubCancel = 'Active'
							AND d.GrpType = 'All American'
						) qcd
					LEFT OUTER JOIN (
						-- tpa deps
						SELECT *
						FROM tpa_data_exchange_dep
						WHERE GRP_TYPE = 4
							AND (MBR_ST IN (1, 2))
						) dca
						ON qcd.MBR_ID = dca.MBR_ID
					WHERE dca.MBR_ID IS NULL
					)
			UPDATE d
			SET d.DepLastName = ISNULL(dd.LAST_NAME, '')
				, d.DepFirstName = ISNULL(dd.FIRST_NAME, '')
				, d.DepMiddleName = ISNULL(dd.MI, '')
				, d.DepDOB = ISNULL(dd.DOB, '1901-01-01 00:00:00')
				, d.DepGender = ISNULL(dd.GENDER, '')
				, d.DepRelationship = ISNULL(dd.REL, '')
									--CASE 
									--	WHEN dd.REL = 0 THEN '' 
									--	WHEN dd.REL = 1 THEN 'S' 
									--	WHEN dd.REL = 2 THEN 'C' 
									--	WHEN dd.REL = 3 THEN 'O' 
									--	ELSE '' 
									--END
				, d.SubID = dd.SUB_ID
				, d.ModifyDate = GETDATE()
				, d.DepAge = dbo.fAgeCalc(ISNULL(dd.DOB, '1901-01-01 00:00:00'))
				, d.DepEffDate = ISNULL(dd.EFF_DT, '1901-01-01 00:00:00')
				, d.PreexistingDate = ISNULL(dd.PREX_DT, '1901-01-01 00:00:00')
				, d.User01 = 'usp_tpa_final_dep'
				, d.User02 = 'mis-match dependent termination'
				, d.User04 = GETDATE()
				, d.DepCancelled = 3
				, d.TransactionType = 'DELETED'
				, d.DateDeleted = dbo.udf_GetLastDayOfMonth(@DT_UPDT)
				, d.UserName = @UserName			
			FROM tblDependent d
			INNER JOIN 
			(
				/* mis-matches */
				SELECT qcd.RCD_TYPE
					, qcd.SSN
					, qcd.SUB_ID
					, qcd.DEP_SSN
					, qcd.NO_DEP
					, qcd.MBR_ID
					, qcd.GRP_ID
					, qcd.LAST_NAME
					, qcd.FIRST_NAME
					, qcd.MI
					, qcd.DOB
					, qcd.EFF_DT
					, qcd.PREX_DT
					, qcd.GENDER
					, qcd.REL
					FROM 	
						(
						/*  qcd deps  */
						SELECT 'D' AS RCD_TYPE
							, d.SubSSN AS SSN
							, d.SubID AS SUB_ID
							, d.DepSSN AS DEP_SSN
							, 0 AS NO_DEP
							, d.EIMBRID AS MBR_ID
							, d.SubGroupID AS GRP_ID
							, d.DepLastName AS LAST_NAME
							, d.DepFirstName AS FIRST_NAME
							, d.DepMiddleName AS MI
							, d.DepDOB AS DOB
							, d.DepEffDate AS EFF_DT
							, d.DepPrexDate AS PREX_DT
							, d.DepGender AS GENDER
							, d.DepRel AS REL
						FROM vw_GrpDep AS d
						WHERE d.GrpCancel = 'Active'
							AND d.SubCancel = 'Active'
							AND d.GrpType = 'All American'
						) qcd
						LEFT OUTER JOIN 
						(
						-- tpa deps
						SELECT *
						FROM tpa_data_exchange_dep
						WHERE GRP_TYPE = 4
							AND (MBR_ST IN (1, 2))
						) dca
				ON qcd.MBR_ID = dca.MBR_ID
				WHERE dca.MBR_ID IS NULL
			) dd
			ON d.EIMBRID = dd.MBR_ID;
	COMMIT TRANSACTION
	RETURN 1
END TRY

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
    RETURN 0
END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Processes data received from tpa and updates tblDependent...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_tpa_final_dep'
GO
