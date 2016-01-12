USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_PrintInvoice]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PrintInvoice](@InvoiceDate DATETIME, @GroupType NVARCHAR(12))
AS


/* ==============================================
	Object:			usp_PrintInvoice
	Version:		1.0
	Author:			John Criswell
	Create date:	2015-03-10
	Description:	Prints invoicies
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Version		Reason
	2015-03-10		JCriswell		1.0			Created
	
================================================= */ 

 /*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    
    DECLARE @maxrow AS INTEGER
    DECLARE @i AS INTEGER               
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION
			DELETE FROM dbo.ARHDR_temp

			SELECT  @LastOperation = 'Insert header into temp table.'
			INSERT  INTO ARHDR_temp
					( CustKey ,
					  CustName ,
					  CustAdd1Trim ,
					  CustAddr2 ,
					  CityStateZip ,
					  Tranno ,
					  Invdate ,
					  Salespkey ,
					  Spare ,
					  InvTot ,
					  GroupType ,
					  GroupId ,
					  InvoiceType
					)
					SELECT  art.CustomerKey ,
							arc.CustomerName ,
							RTRIM(arc.CustomerAddress1) AS CustAdd1Trim ,
							arc.CustomerAddress2 ,
							RTRIM(arc.CustomerCity) + ', ' + RTRIM(arc.CustomerState)
							+ '  ' + RTRIM(arc.CustomerZipCode) AS CityStateZip ,
							RTRIM(art.DocumentNumber) AS Tranno ,
							art.DocumentDate ,
							art.SalespersonKey ,
							arc.Spare ,
							art.DocumentAmt ,
							arc.GroupType ,
							art.CustomerKey AS GroupId ,
							arc.InvoiceType
					FROM    ARTRANH_local AS art
							INNER JOIN ARCUST_local AS arc ON art.CustomerKey = arc.CustomerKey
					WHERE   ( art.DocumentDate = @InvoiceDate )
							AND ( art.Spare3 = @GroupType )
			        
			        SELECT  @LastOperation = 'Insert detail into temp table.'        
					INSERT  INTO ARLIN_temp
							( Tranno ,
							  [Description] ,
							  Unitprice
							)
							SELECT  ARLINH_local.DocumentNumber AS Tranno ,
									ARLINH_local.ItemDescription AS Description ,
									ARLINH_local.UnitPrice
							FROM    ARLINH_local
									INNER JOIN ARTRANH_local ON ARLINH_local.DocumentNumber = ARTRANH_local.DocumentNumber
																AND ARLINH_local.CustomerKey = ARTRANH_local.CustomerKey
							WHERE   ( ARTRANH_local.Spare3 = @GroupType )
									AND ( ARTRANH_local.DocumentDate = @InvoiceDate )
									AND (dbo.ARLINH_local.LineItemType = '1')
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH 
		IF @@TRANCOUNT > 0 
			ROLLBACK

		SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
				+ @LastOperation, @ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE()
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Prints invoices.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_PrintInvoice'
GO
