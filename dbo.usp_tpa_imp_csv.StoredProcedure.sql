USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_imp_csv]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_tpa_imp_csv]
AS /* ======================================================================================
  Object:			usp_tpa_imp_csv
  Version:			1.0
  Author:			John Criswell
  Create date:		2015-10-18 
  Description:		Runs SSIS package (tpa_data_exchange_import.dtsx) to import
					tpa file
					
  Parameters:	none
  Where Used:	fdlgAASync	
					
				
  Change Log:
  ---------------------------------------------------------------------------------------
  Change Date		Version			Changed by		Reason
  2015-10-18		1.0				J Criswell		Created	
  2014_11_11		2.0				J Criswell		this version points to a different package
													with a connection to the dev database instead of temp
	
========================================================================================= */
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

	/* t-sql to call an SSIS package with a package variable
	Webpage with reference:
	https://www.mssqltips.com/sqlservertip/1395/pass-dynamic-parameter-values-to-sql-server-integration-services/ 
	*/
	
        DECLARE @cmd VARCHAR(1000);
        DECLARE @ssispath VARCHAR(1000);
		--declare @InputDate varchar(10)
        DECLARE @PackagePassword VARCHAR(20);
        SET @ssispath = '\\dc\datafiles\Clients\Direct Care Administrators\SSIS\data_exchange\tpa_data_exchange_import_dev.dtsx';
	
        SET @PackagePassword = 'HiRainwus304';
        SELECT @cmd = 'dtexec /de ' + '"' + @PackagePassword + '"' + ' /F "' + @ssispath + '"';

        EXEC master..xp_cmdshell @cmd;
	
	 
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
	END CATCH;
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Runs SSIS package to import data from tpa...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_tpa_imp_csv'
GO
