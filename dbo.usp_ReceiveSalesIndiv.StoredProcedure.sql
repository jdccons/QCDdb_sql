USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReceiveSalesIndiv]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ReceiveSalesIndiv]
    (
      @DocumentNumber NVARCHAR(16)
    )
AS /* =============================================
	Object:			usp_ReceiveSalesIndiv
	Author:			John Criswell
	Create date:	9/8/2014	 
	Description:	Creates a receive sale transaction
					for a single individual 
					
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */

 /*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    
    DECLARE @NextSysDocId AS INTEGER
    DECLARE @NextTranNo AS INTEGER               
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION

        SELECT  @LastOperation = 'generate new tran nos and new SysDocId' 



        SELECT  @NextSysDocId = NextSysDocId
        FROM    dbo.ARNEXTSY_local;

        UPDATE  dbo.ARNEXTSY_local
        SET     NextSysDocID = NextSysDocID + 1

        SELECT  @NextTranNo = NextTransaction
        FROM    dbo.ARONE_R9_local;

        UPDATE  dbo.ARONE_R9_local
        SET     NextTransaction = @NextTranNo + 1

        DECLARE @InvoiceDate AS DATETIME
        SELECT  @InvoiceDate = DocumentDate
        FROM    ARTRANH_local
        WHERE   DocumentNumber = @DocumentNumber;


        SELECT  @LastOperation = 'create receive sale transaction' 
        INSERT  INTO ARTRANH_local
                ( DocumentNumber ,
                  ApplyTo ,
                  TerritoryKey ,
                  SalespersonKey ,
                  CustomerKey ,
                  CustomerClassKey ,
                  OrderNumber ,
                  ShipToKey ,
                  CheckBatch ,
                  TransactionType ,
                  DocumentDate ,
                  AgeDate ,
                  DaysTillDue ,
                  DocumentAmt ,
                  DiscountAmt ,
                  FreightAmt ,
                  TaxAmt ,
                  CostAmt ,
                  CommissionHomeOvride ,
                  RetentionInvoice ,
                  SysDocID ,
                  ApplySysDocID ,
                  Spare ,
                  Spare2 ,
                  Spare3 ,
                  RecUserID ,
                  RecDate ,
                  RecTime
                )
                SELECT  SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10,
                                  1) + CONVERT(NVARCHAR(9), @NextTranNo) AS DocumentNumber ,
                        DocumentNumber AS ApplyTo ,
                        TerritoryKey ,
                        SalespersonKey ,
                        CustomerKey ,
                        CustomerClassKey ,
                        OrderNumber ,
                        ShipToKey ,
                        CheckBatch ,
                        'P' AS TransactionType ,
                        DocumentDate ,
                        AgeDate ,
                        DaysTillDue ,
                        DocumentAmt * -1 ,
                        DiscountAmt ,
                        FreightAmt ,
                        TaxAmt ,
                        CostAmt ,
                        CommissionHomeOvride ,
                        RetentionInvoice ,
                        @NextSysDocId AS SysDocId ,
                        SysDocID AS ApplySysDocID ,
                        Spare ,
                        Spare2 ,
                        Spare3 ,
                        'QCD db' AS RecUser ,
                        CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate ,
                        LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
                FROM    ARTRANH_local AS ARTRANH_local_1
                WHERE   ( DocumentNumber = @DocumentNumber )
       
        COMMIT TRANSACTION
    END TRY

    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK

        SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
                + @LastOperation ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE()
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
GO
