USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ARCUST_local]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ARCUST_local] (@UserName nvarchar(20))
AS
	
	/* =============================================
		Object:			usp_ARCUST_local
		Author:			John Criswell
		Version:		3
		Create date:	9/1/2014	 
		Description:	Syncs customers between vw_Customer
						and ARCUST_local
						 
						
								
		Change Log:
		--------------------------------------------
		Change Date		Version		Changed by		Reason
		1/12/2015		2.0			JCriswell		Added RecUserID, RecDate
													and RecTime to update and
													insert
		12/22/2015		3.0			J Criswell		Changed the process to handle
													individual customers separately
													from the group customers.
		
	============================================= */
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

		/*  update the individual customers  */   
		UPDATE arc
		SET CustomerName = c.CustomerName
			, TerritoryKey = c.TerritoryKey
			, CustomerAddress1 = c.CustomerAddress1
			, CustomerAddress2 = c.CustomerAddress2
			, CustomerCity = c.CustomerCity
			, CustomerState = c.CustomerState
			, CustomerZipCode = c.CustomerZipCode
			, ContactName = c.ContactName
			, EmailAddress = c.EmailAddress
			, ContactPhone = c.ContactPhone
			, TelexNumber = c.TelexNumber
			, CustomerKey = c.CustomerKey
			, CustomerClassKey = c.CustomerClassKey
			, CreditHold = c.CreditHold
			, LocationKey = c.LocationKey
			, Rsrv1 = CASE WHEN c.CreditHold = 'Y' THEN 3 ELSE 1 END
			/*, Spare = c.Spare  -- SubID (join is on SubID)*/
			, Spare2 = c.Spare2
			, Spare3 = c.Spare3
			, RecUserID = @UserName
			, RecDate = CONVERT(VARCHAR(10), GETDATE(), 101)
			, RecTime = LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
		FROM ARCUST_local arc
		INNER JOIN vw_Customer c
			ON arc.Spare = c.Spare -- Spare = SubID
		WHERE arc.CustomerClassKey = 'INDIV'



		/*  update the group customers  */
		UPDATE arc
		SET CustomerName = c.CustomerName
			, TerritoryKey = c.TerritoryKey
			, CustomerAddress1 = c.CustomerAddress1
			, CustomerAddress2 = c.CustomerAddress2
			, CustomerCity = c.CustomerCity
			, CustomerState = c.CustomerState
			, CustomerZipCode = c.CustomerZipCode
			, ContactName = c.ContactName
			, EmailAddress = c.EmailAddress
			, ContactPhone = c.ContactPhone
			, TelexNumber = c.TelexNumber
			, CustomerKey = c.CustomerKey
			, CustomerClassKey = c.CustomerClassKey
			, CreditHold = c.CreditHold
			, LocationKey = c.LocationKey
			, Rsrv1 = CASE WHEN c.CreditHold = 'Y' THEN 3 ELSE 1 END
			, Spare = c.Spare
			, Spare2 = c.Spare2
			, Spare3 = c.Spare3
			, RecUserID = @UserName
			, RecDate = CONVERT(VARCHAR(10), GETDATE(), 101)
			, RecTime = LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
		FROM ARCUST_local arc
		INNER JOIN vw_Customer c
			ON arc.CustomerKey = c.CustomerKey
		WHERE arc.CustomerClassKey = 'GROUP'


		/*  inserts new records for the individual customers */        
		INSERT  INTO ARCUST_local
				( CustomerKey ,
				  CustomerName ,
				  CustomerAddress1 ,
				  CustomerAddress2 ,
				  CustomerAddress3 ,
				  CustomerCity ,
				  CustomerState ,
				  CustomerZipCode ,
				  ContactName ,
				  EmailAddress ,
				  ContactPhone ,
				  TelexNumber ,
				  CustomerClassKey ,
				  CreditHold ,
				  LocationKey,
				  Rsrv1 ,
				  Spare ,
				  Spare2 ,
				  Spare3 ,
				  RecUserID ,
				  RecDate ,
				  RecTime
				)
				SELECT  c.CustomerKey ,
						c.CustomerName ,
						c.TerritoryKey ,
						c.CustomerAddress1 ,
						c.CustomerAddress2 ,
						c.CustomerCity ,
						c.CustomerState ,
						c.CustomerZipCode ,
						c.ContactName ,
						c.EmailAddress ,
						c.ContactPhone ,
						c.TelexNumber ,
						c.CustomerClassKey ,
						c.CreditHold ,
						c.LocationKey ,
						1 Rsrv1 ,
						c.Spare ,
						c.Spare2 ,
						c.Spare3 ,
						@UserName RecUserID ,
						CONVERT(VARCHAR(10), GETDATE(), 101) RecDate ,
						LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) RecTime
				FROM    vw_Customer AS c
						LEFT OUTER JOIN ARCUST_local AS arc 
							ON arc.Spare = c.Spare
				WHERE c.CustomerClassKey = 'INDIV'
				AND   ( arc.Spare IS NULL )

		/*  inserts new records for the group customers */        
		INSERT  INTO ARCUST_local
				( CustomerKey ,
				  CustomerName ,
				  CustomerAddress1 ,
				  CustomerAddress2 ,
				  CustomerAddress3 ,
				  CustomerCity ,
				  CustomerState ,
				  CustomerZipCode ,
				  ContactName ,
				  EmailAddress ,
				  ContactPhone ,
				  TelexNumber ,
				  CustomerClassKey ,
				  CreditHold ,
				  LocationKey,
				  Rsrv1,
				  Spare ,
				  Spare2 ,
				  Spare3 ,
				  RecUserID ,
				  RecDate ,
				  RecTime
				)
				SELECT  c.CustomerKey ,
						c.CustomerName ,
						c.TerritoryKey ,
						c.CustomerAddress1 ,
						c.CustomerAddress2 ,
						c.CustomerCity ,
						c.CustomerState ,
						c.CustomerZipCode ,
						c.ContactName ,
						c.EmailAddress ,
						c.ContactPhone ,
						c.TelexNumber ,
						c.CustomerClassKey ,
						c.CreditHold ,
						c.LocationKey ,
						1 As Rsrv1,
						c.Spare ,
						c.Spare2 ,
						c.Spare3 ,
						@UserName RecUserID ,
						CONVERT(VARCHAR(10), GETDATE(), 101) RecDate ,
						LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) RecTime
				FROM    vw_Customer AS c
						LEFT OUTER JOIN ARCUST_local AS arc 
							ON arc.CustomerKey = c.CustomerKey
				WHERE c.CustomerClassKey = 'GROUP'
				AND   ( arc.CustomerKey IS NULL );

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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Syncs customers between vw_Customer and ARCUST_local.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_ARCUST_local'
GO
