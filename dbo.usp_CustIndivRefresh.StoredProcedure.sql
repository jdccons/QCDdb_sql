USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CustIndivRefresh]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CustIndivRefresh] 

					(
					@SubID		NCHAR(8),
					@UserName	NVARCHAR(20)	
					)
AS
/* ================================================================
  Object:			usp_CustIndivRefresh
  Author:			John Criswell
  Current Version:	2
  Create date:		12/31/2015	 
  Description:		Adds a single individual subscriber to ARCUST		
					
					
  Parameters:		@SubID		nchar(8)
					@UserName	nvarchar(20)
					
  Where Used:		frmIndivSubscr
					
				
  Change Log:
  -----------------------------------------------------------------
  Change Date		Version		Changed by		Reason
  2015-12-31		1.0			J Criswell		Created
  2015-12-31		2.0			J Criswell		Modified code to include transaction
												processing and error handling
	
	
=================================================================== */
/*  ------------------  declarations  --------------------  */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @LastOperation VARCHAR(128)
	, @ErrorMessage VARCHAR(8000)
	, @ErrorSeverity INT
	, @ErrorState INT

/*  ------------------------------------------------------  */
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
		/*  do an update  */
		SET @LastOperation = 'update the individual customer'		
			UPDATE arc
			SET CustomerName = ic.CustomerName
				, TerritoryKey = ic.TerritoryKey
				, CustomerAddress1 = ic.CustomerAddress1
				, CustomerAddress2 = ic.CustomerAddress2
				, CustomerCity = ic.CustomerCity
				, CustomerState = ic.CustomerState
				, CustomerZipCode = ic.CustomerZipCode
				, ContactName = ic.ContactName
				, EmailAddress = ic.EmailAddress
				, ContactPhone = ic.ContactPhone
				, TelexNumber = ic.TelexNumber
				, CustomerKey = ic.CustomerKey
				, CustomerClassKey = ic.CustomerClassKey
				, CreditHold = ic.CreditHold
				, LocationKey = ic.LocationKey
				, Rsrv1 = case when ic.CreditHold = 'Y' then 3 when ic.CreditHold = 'N' then 1 else 1 end
				--, Spare = ic.Spare  SubID (join is on SubID)
				, Spare2 = ic.Spare2
				, Spare3 = ic.Spare3
				, RecUserID = @UserName
				, RecDate = CONVERT(VARCHAR(10), GETDATE(), 101)
				, RecTime = LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))				
			FROM ARCUST_local arc
			INNER JOIN vw_IndividualCustomer ic
				ON arc.Spare = ic.Spare
			WHERE ic.CustomerClassKey = 'INDIV'
			AND ic.Spare = @SubID


			/*  create new individual record in ARCUST_local */
			SET @LastOperation = 'create new individual record in ARCUST_local'
				INSERT INTO ARCUST_local (
				CustomerKey
				, CustomerName
				, CustomerAddress1
				, CustomerAddress2
				, CustomerAddress3
				, CustomerCity
				, CustomerState
				, CustomerZipCode
				, ContactName
				, EmailAddress
				, ContactPhone
				, TelexNumber
				, CustomerClassKey
				, CreditHold
				, LocationKey
				, Rsrv1
				, Spare
				, Spare2
				, Spare3
				, RecUserID
				, RecDate
				, RecTime
				, GroupType
				)
			SELECT ic.CustomerKey
				, ic.CustomerName
				, ic.TerritoryKey
				, ic.CustomerAddress1
				, ic.CustomerAddress2
				, ic.CustomerCity
				, ic.CustomerState
				, ic.CustomerZipCode
				, ic.ContactName
				, ic.EmailAddress
				, ic.ContactPhone
				, ic.TelexNumber
				, ic.CustomerClassKey
				, ic.CreditHold
				, ic.LocationKey
				, 1 as Rsrv1
				, ic.Spare
				, ic.Spare2
				, ic.Spare3
				, @UserName RecUserID
				, CONVERT(VARCHAR(10), GETDATE(), 101) RecDate
				, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) RecTime
				, 9 As GroupType
			FROM vw_IndividualCustomer AS ic
				LEFT OUTER JOIN ARCUST_local arc
					ON ic.Spare = arc.Spare 
			WHERE ((ic.Spare = @SubID)
			AND (arc.Spare IS NULL))	
	COMMIT TRANSACTION
	RETURN 1
END TRY


BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	SELECT @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: ' + 
		@LastOperation
		, @ErrorSeverity = ERROR_SEVERITY()
		, @ErrorState = ERROR_STATE()

	RAISERROR (
			@ErrorMessage
			, @ErrorSeverity
			, @ErrorState
			)

	EXEC usp_CallProcedureLog @ObjectID = @@PROCID
		, @AdditionalInfo = @LastOperation;

	RETURN 0
END CATCH
END;
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'maintains individual records in ARCUST_local' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_CustIndivRefresh'
GO
