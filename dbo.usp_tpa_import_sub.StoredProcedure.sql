USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_import_sub]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_tpa_import_sub]
@ReturnParm VARCHAR(255) OUTPUT 
as
/* ==============================================================
	Object:			usp_tpa_import_sub
	Author:			John Criswell
	Create date:	10/16/2015 
	Description:	imports subs from tpa_data_exchange table
			into the tpa_data_exchange_sub table
								
							
	Change Log:
	-------------------------------------------------------------
	Change Date	Version		Changed by		Reason
	2015-10-16	1.0			J Criswell		Created.

================================================================= */
/*  ------------------  declarations  --------------------  */ 
SET NOCOUNT ON;
SET XACT_ABORT ON;
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT

	
/*  ------------------------------------------------------  */
BEGIN TRY
   BEGIN TRANSACTION
		-- copy subscribers from data exchange table to subscriber data exchange table
		SELECT  @LastOperation = 'truncate tpa_data_exchange_sub'
		DELETE FROM tpa_data_exchange_sub


		SELECT  @LastOperation = 'populate tpa_data_exchange_sub'
		INSERT INTO tpa_data_exchange_sub (
			GRP_TYPE, RCD_TYPE, SSN, SUB_ID, DEP_SSN, LAST_NAME, FIRST_NAME, MI, 
			DOB, GRP_ID, [PLAN], COV, EFF_DT, PREX_DT, GENDER, ADDR1, ADDR2, CITY, 
			STATE, ZIP, EMAIL, PHONE_HOME, PHONE_WORK, NO_DEP, REL, CARD_PRT, 
			CARD_PRT_DT, MBR_ST, DT_UPDT
			)
		SELECT GRP_TYPE, RCD_TYPE, SSN, SUB_ID, DEP_SSN, LAST_NAME, FIRST_NAME, 
			MI, DOB, GRP_ID, [PLAN], COV, EFF_DT, PREX_DT, GENDER, ADDR1, ADDR2, 
			CITY, STATE, ZIP, EMAIL, PHONE_HOME, PHONE_WORK, NO_DEP, REL, 
			CARD_PRT, CARD_PRT_DT, MBR_ST, DT_UPDT
		FROM tpa_data_exchange
		WHERE (RCD_TYPE = 'S')
		AND (GRP_TYPE) = 4;
		
		/*  update EIMBRID on tpa_data_exchange_sub  */
		SELECT  @LastOperation = 'populate tpa_data_exchange_sub'
		UPDATE tpa_data_exchange_sub
		SET MBR_ID = SSN + '00'

	COMMIT TRANSACTION
	SET @ReturnParm = 'Procedure succeeded'
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Imports subscriber data into tpa subscriber table...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_tpa_import_sub'
GO
