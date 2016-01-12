USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_IndividualInvoice_csv]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_IndividualInvoice_csv] 
				(			
							@InvoiceDate AS DateTime,
							@UserName as nvarchar(20)
				)
AS

/* ======================================================================================
  Object:			usp_IndividualInvoice_csv
  Version:			1.0
  Author:			John Criswell
  Create date:		2015-07-26 
  Description:		Runs SSIS package (SalesReceipts.dtsx) to export
					Individual invoice data to a CSV file
					
  Parameters:		@InvoiceDate DateTime
  Where Used:		
					
				
  Change Log:
  ---------------------------------------------------------------------------------------
  Change Date		Version			Changed by		Reason
  2015-11-18		1.0				JCriswell		Created	
  
	
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
			SET @LastOperation = 'Individual invoices for QuickBooks'
			DECLARE @cmd varchar(1000)
			DECLARE @ssispath varchar(1000)
			DECLARE @PackagePassword varchar(20)
			SET @ssispath = '\\dc\datafiles\QuickBooks\SSIS\QuickBooks\SalesReceipts_dev.dtsx'

			SET @PackagePassword = 'd!7kZ[Cs8Qsw~7H'
			SELECT @cmd = 'dtexec /de ' + '"' + @PackagePassword + '"' + ' /F "' + @ssispath + '"'
			SELECT @cmd = @cmd + ' /SET \Package.Variables[User::ShipDate].Properties[Value];"' + CONVERT(varchar(12), @InvoiceDate) + '"'

			EXEC master..xp_cmdshell @cmd

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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Runs SSIS package to export Individual invoices to QuickBooks...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_IndividualInvoice_csv'
GO
