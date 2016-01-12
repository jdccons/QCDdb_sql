USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspAA_Process]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAA_Process]
@ReturnParm VARCHAR(255) OUTPUT 

AS

/* ============================================================================
	Object:			uspAA_Process
	Version:		3
	Author:			John Criswell
	Create date:	2/1/2015	 
	Description:	Processes data in third party administrator's file.
							
	Change Log:
	---------------------------------------------------------------------------
	Change Date		Changed by		Version			Reason
	2015-03-10		JCriswell		3.0				Changed how Sub_LUName is built.
	
	
=============================================================================== */

/*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT
-----------------------------------------------        
 BEGIN TRY
        BEGIN TRANSACTION
        
			SELECT  @LastOperation = 'Delete records from import tables.'
				DELETE FROM tmpExportAllAmerican;
				DELETE FROM tblEDI_App_Subscr;
				DELETE FROM tblEDI_App_Dep;

				SELECT  @LastOperation = 'Move from ELGEXP_SQL to tmpExportAllAmerican.'
				-- Move from ELGEXP_SQL to tmpExportAllAmerican
				INSERT  INTO tmpExportAllAmerican ( EIRECID, EIMBRID, EISBRID, EISSN, EINAML,
													EINAMF, EINAMM, EIDTBR, EISEX, EISSNEXT,
													EIADD1, EIADD2, EIADD3, EICITY, EICTY,
													EISTE, EIZIP, EIZIP4, EIHEMAIL, EIWEMAIL,
													EIWPHR, EIWEXG, EIDPT, EIHPHR, EIACTDB,
													EICRDCR, EIBANK, EIACDB#, EIDTEXPR,
													EIGRPID, EISGRPID, EINMPLAN, EIDTEFF,
													EIDTCVEF, EIDTCVEN, EIMBRDP, EISPC,
													EIFACCN, EIPRVCN, EIDTPNEF, EIDTPNEN,
													EISTUSTS, EIEXTCVG, EITRNID, EIDTHIRE,
													EIDTTERM, EIPRMSC@, EIPRMCL@, EIDSCL@ )
						SELECT  EIRECID, EIMBRID, EISBRID, EISSN#, EINAML, EINAMF, EINAMM,
								EIDTBR, EISEX, EISSNEXT, EIADD1, EIADD2, EIADD3, EICITY,
								EICTY@, EISTE@, EIZIP6, EIZIP4, EIHEMAIL, EIWEMAIL, EIWPHR,
								EIWEXG, EIDPT, EIHPHR, EIACTDB@, EICRDCR@, EIBANK, EIACTDB#,
								EIDTEXPR, EIGRPID, EISGRPID, EINMPLAN, EIDTEFF, EIDTCVEF,
								EIDTCVEN, EIMBRDP@, EISPC@, EIFACCN@, EIPRVCN@, EIDTPNEF,
								EIDTPNEN, EISTUSTS, EIEXTCVG, EITRNID, EIDTHIRE, EIDTTERM,
								EIPRMSC@, EIPRMCL@, EIDSCL@
						FROM    ELGEXP_SQL

				SELECT  @LastOperation = 'Move from tmpExportAllamerican to tblEDI_App_Subscr.'
				-- Move from tmpExportAllamerican to tblEDI_App_Subscr
				INSERT  INTO tblEDI_App_Subscr ( SUBssn, EIMBRID, SUBfirstNAME, SUBmiddleNAME,
												 SUBlastNAME, SUBstreet1, SUBstreet2, SUBcity,
												 SUBstate, SUBzip, SUBphoneWORK, SUBphoneHOME,
												 SUBgroupID, SUBdob, DepCnt, SUBstatus,
												 SUBeffDATE, SUB_LUname, PlanID, CoverID,
												 SUBgender, SubAge )
						SELECT  tmpExportAllAmerican.EISSN, tmpExportAllAmerican.EIMBRID,
								LEFT(LTRIM(tmpExportAllAmerican.EINAMF), 13) AS EINAMF,
								LEFT(LTRIM([EINAMM]), 1) AS MidInit,
								LEFT(LTRIM(tmpExportAllAmerican.EINAML), 20) AS EINAML,
								tmpExportAllAmerican.EIADD1, tmpExportAllAmerican.EIADD2,
								LEFT(LTRIM(tmpExportAllAmerican.EICITY), 30) AS EICITY,
								tmpExportAllAmerican.EISTE, tmpExportAllAmerican.EIZIP,
								( CASE WHEN [EIWPHR] <> '' THEN [EIWPHR]
									   ELSE NULL
								  END ) AS PhoneWork, ( CASE WHEN [EIHPHR] <> '' THEN [EIHPHR]
															 ELSE NULL
														END ) AS PhoneHome,
								RIGHT(RTRIM([EIGRPID]), LEN(LTRIM(RTRIM([EIGRPID]))) - 3) AS GROUPid,
								CONVERT(DATETIME, CONVERT(NVARCHAR(12), LEFT([EIDTBR], 2)
								+ '-' + SUBSTRING([EIDTBR], 3, 2) + '-'
								+ ( CASE WHEN SUBSTRING([EIDTBR], 5, 1) = '0'
										 THEN '1' + RIGHT([EIDTBR], 3)
										 ELSE RIGHT([EIDTBR], 4)
									END ), 101)) AS DOB, ( CASE WHEN [Cnt] IS NULL THEN 0
																ELSE [Cnt]
														   END ) AS DepCnt, 'GRSUB' AS Status,
								CONVERT(DATETIME, CONVERT(NVARCHAR(12), LEFT([EIDTCVEF], 2)
								+ '-' + SUBSTRING([EIDTCVEF], 3, 2) + '-' + RIGHT([EIDTCVEF],
																			  4), 101)) AS CoverEffDate,
								/*  version 3.0 change */
								ISNULL(UPPER(LTRIM(RTRIM([EINAML]))),'') + ', ' + 
								ISNULL(UPPER(LTRIM(RTRIM([EINAMF]))),'') + ' ' + 
								ISNULL(UPPER(LEFT(LTRIM(RTRIM([EINAMM])), 1)),'') AS LookUpName,
								( CASE WHEN SUBSTRING([EINMPLAN], 4, 3) = 'RED' THEN 1
									   WHEN SUBSTRING([EINMPLAN], 4, 3) = 'WHT' THEN 2
									   WHEN SUBSTRING([EINMPLAN], 4, 3) = 'BLU' THEN 3
									   WHEN SUBSTRING([EINMPLAN], 4, 3) = 'RPL' THEN 4
								  END ) AS PlanID, ( CASE WHEN EIPRMCL@ = 'S' THEN '1'
														  WHEN EIPRMCL@ = 'C' THEN '2'
														  WHEN EIPRMCL@ = 'N' THEN '3'
														  WHEN EIPRMCL@ = 'P' THEN '3'
														  WHEN EIPRMCL@ = 'F' THEN '4'
													 END ) AS CoverID,
								tmpExportAllAmerican.EISEX,
								dbo.fAgeCalc(LEFT(tmpExportAllAmerican.EIDTBR, 2) + '/'
											 + SUBSTRING(tmpExportAllAmerican.EIDTBR, 3, 2)
											 + '/' + RIGHT(tmpExportAllAmerican.EIDTBR, 4)) AS SubAge
						FROM    tmpExportAllAmerican
						LEFT JOIN AA_CntOfDeps ON LTRIM(RTRIM(tmpExportAllAmerican.EISBRID)) = LTRIM(RTRIM(AA_CntOfDeps.EISBRID))
						WHERE   (
								  ( ( tmpExportAllAmerican.EIRECID ) = 'P' )
								  AND ( ( SUBSTRING([EINMPLAN], 8, 3) ) = 'QCD' )
								)
								OR (
									 ( ( tmpExportAllAmerican.EIRECID ) = 'P' )
									 AND ( ( tmpExportAllAmerican.EINMPLAN ) = 'QCDBLU-NGL' )
								   )
								OR (
									 ( ( tmpExportAllAmerican.EIRECID ) = 'P' )
									 AND ( ( tmpExportAllAmerican.EINMPLAN ) = 'QCDBLU-MNL' )
								   )
						ORDER BY tmpExportAllAmerican.EINAML

				SELECT  @LastOperation = 'Update PreexistingDates.'
				-- Update PreexistingDates
				UPDATE e
				SET e.PreexistingDate = a.SubEffDate
				FROM tblEDI_App_Subscr e
				INNER JOIN AA_Subscr_PreexistingDate a ON e.SubSSN = a.AA_SSN

				SELECT  @LastOperation = 'Fix SubEffDates.'
				-- Fix SubEffDates where the MNL effective date is > the QCD effective date
				-- They should be the same in this case
				Exec uspMNL_EffDates
				UPDATE e
				SET		e.SubEffDate = m.SubEffDate, 
						e.PreexistingDate = m.SubEffDate
				FROM tblEDI_App_Subscr e
					INNER JOIN tmpMNL_EffDates m
						ON e.EIMBRID = m.EIMBRID

				SELECT  @LastOperation = 'Update the Rate IDs.'
				-- Update the Rate ID's
				UPDATE tblEDI_App_Subscr
				SET RateID = tblRates.RateID
				FROM tblEDI_App_Subscr 
				INNER JOIN tblRates ON tblRates.CoverID = tblEDI_App_Subscr.CoverID 
				AND tblEDI_App_Subscr.SUBgroupID = tblRates.GroupID 
				AND tblEDI_App_Subscr.PlanID = tblRates.PlanID

				SELECT  @LastOperation = 'move from tmpExportAllAmerican to tblEDI_App_Dep.'
				--move from tmpExportAllAmerican to tblEDI_App_Dep
				INSERT  INTO tblEDI_App_Dep ( DEPsubID, DEPssn, EIMBRID, DEPlastNAME,
											  DEPfirstNAME, DEPmiddleNAME, DEPdob, DEPgender,
											  DEPrelationship, DepAge, DepEffDate )
						SELECT  AA_SSN.AA_SSN AS DepSubID,
								tmpExportAllAmerican.EISSN AS DepSSN,
								tmpExportAllAmerican.EIMBRID,
								tmpExportAllAmerican.EINAML AS DepLastName,
								tmpExportAllAmerican.EINAMF AS DepFirstname,
								LEFT(tmpExportAllAmerican.EINAMM, 1) AS DepMiddleName,
								LEFT(tmpExportAllAmerican.EIDTBR, 2) + '/'
								+ SUBSTRING(tmpExportAllAmerican.EIDTBR, 3, 2) + '/'
								+ RIGHT(tmpExportAllAmerican.EIDTBR, 4) AS DepDOB,
								tmpExportAllAmerican.EISEX AS DepGender,
								( CASE WHEN SUBSTRING([tmpExportAllAmerican].[EIMBRID], 10, 2) = '01'
									   THEN 'S'
									   ELSE 'C'
								  END ) AS DepRelationship,
								dbo.fAgeCalc(LEFT(tmpExportAllAmerican.EIDTBR, 2) + '/'
											 + SUBSTRING(tmpExportAllAmerican.EIDTBR, 3, 2)
											 + '/' + RIGHT(tmpExportAllAmerican.EIDTBR, 4)) AS DepAge,
								CONVERT(DATETIME, CONVERT(NVARCHAR(12), LEFT([EIDTCVEF], 2)
								+ '-' + SUBSTRING([EIDTCVEF], 3, 2) + '-' + RIGHT([EIDTCVEF],
																			  4), 101)) AS CoverEffDate
						FROM    tmpExportAllAmerican
						INNER JOIN AA_SSN ON tmpExportAllAmerican.EISBRID = AA_SSN.EISBRID
						WHERE   ( tmpExportAllAmerican.EIRECID = 'M' )
								AND ( SUBSTRING(tmpExportAllAmerican.EINMPLAN, 8, 3) = 'QCD' )
								OR ( tmpExportAllAmerican.EIRECID = 'M' )
								AND ( tmpExportAllAmerican.EINMPLAN = 'QCDBLU-NGL' )
								OR ( tmpExportAllAmerican.EIRECID = 'M' )
								AND ( tmpExportAllAmerican.EINMPLAN = 'QCDBLU-MNL' )

				SELECT  @LastOperation = 'update dependent preexistingdates.'
				-- update dependent preexistingdates
				UPDATE e
				SET e.PreexistingDate = a.SubEffDate
				FROM tblEDI_App_Dep e
					INNER JOIN AA_Dependent_PreexistingDate a 
						ON e.EIMBRID = a.EIMBRID

		COMMIT TRANSACTION
		SET  @ReturnParm = 'Procedure succeeded'
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
        SET @ReturnParm = 'Procedure Failed'
    END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Processes data in third party administrators file.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'uspAA_Process'
GO
