USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ChangeSubscrStatus]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ChangeSubscrStatus]
(@SSN nchar(9), @StatInd as Integer, @UserName nvarchar(50))
AS
/* ==============================================================
	Object:			usp_ChangeSubscrStatus
	Author:			John Criswell
	Create date:	
	Description:	Changes a subscriber's status from one value
					to another; i.e. from active to cancelled
								
							
	Change Log:
	-------------------------------------------------------------
	Change Date	Version		Changed by		Reason
	2015-11-12	1.0			J Criswell		Created
================================================================= */

/*  ------------------  declarations  --------------------  */ 
SET NOCOUNT ON;
SET XACT_ABORT ON;
    DECLARE			@LastOperation VARCHAR(128) ,
					@ErrorMessage VARCHAR(8000) ,
					@ErrorSeverity INT ,
					@ErrorState INT

	
/*  ------------------------------------------------------  */

BEGIN TRY
   BEGIN TRANSACTION
		
	SELECT @LastOperation = 'update subcancelled field on tblSubscr'
	IF @StatInd = 1 
		BEGIN
			UPDATE tblSubscr
			SET SubCancelled = 1,
			DateUpdated = GETDATE(),
			DateDeleted = '1901-01-01 00:00:00',
			TransactionType = 'CHANGED',
			User01 = 'usp_ChangeSubscrStatus',
			User02 = 'changed SubCancelled to active',
			User04 = GETDATE(),
			UserName = @UserName
			WHERE SubSSN = @SSN
		END	
		
	IF @StatInd = 2 
		BEGIN
			UPDATE tblSubscr
			SET SubCancelled = 2,
			DateDeleted = dbo.udf_GetLastDayOfMonth(GETDATE()),
			TransactionType = 'DELETED',
			User01 = 'usp_ChangeSubscrStatus',
			User02 = 'changed SubCancelled to hold',
			User04 = GETDATE(),
			UserName = @UserName
			WHERE SubSSN = @SSN
		END	
		
	IF @StatInd = 3 
		BEGIN
			UPDATE tblSubscr
			SET SubCancelled = 3,
			DateDeleted = GETDATE(),
			TransactionType = 'DELETED',
			User01 = 'usp_ChangeSubscrStatus',
			User02 = 'changed SubCancelled to deleted',
			User04 = GETDATE(),
			UserName = @UserName
			WHERE SubSSN = @SSN
		END	
		
		-- repopulate tblSubscrInquire
		-- exec uspSubscrSearch '172586845', '', 1
		exec dbo.uspSubscrSearch @SSN, '', 1	
		
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Changes the status of a subscriber...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_ChangeSubscrStatus'
GO
