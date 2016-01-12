USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePostIndiv]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InvoicePostIndiv]
	(
      @InvoiceDate AS DATETIME,
      @UserName AS nvarchar(20)
    )
AS 
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
/* =============================================
	Object:			usp_InvoicePostIndiv
	Version:		3.0
	Author:			John Criswell
	Create date:	2014-10-02	 
	Description:	Takes invoice for a single 
					individual from staging table
					and puts it in ARTRANH_local
					and ARLIN_local	as an invoice
					and a sales receipt;  the invoice
					will be an 'I' transaction and the 
					sales receipt will be a 'P' transaction
					
								
							
	Change Log:
	--------------------------------------------
	Change Date	Version		Changed by		Reason
	2014-10-02	1.0			J Criswell		Created	
	2015-11-19	2.0			J Criswell		Changed the where clause so that
											more than one individual invoice
											is posted to the transaction table
	2015-11-20	3.0			J Criswell		Added art.IFStatus = 'U' to where clause
											on sales receipt/payment transaction.
	
============================================= */ 

 /*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    DECLARE @SysDocID AS INTEGER,
			@TranNo AS INTEGER         
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION
		if exists(SELECT 1
					FROM tblInvHdr
					WHERE [CUST CLASS] = 'INDIV'
						AND [INV DATE] BETWEEN dbo.udf_GetFirstDayOfMonth(@InvoiceDate)
							AND dbo.udf_GetLastDayOfMonth(@InvoiceDate)
					)
		BEGIN
			SET @SysDocID = ( SELECT dbo.udf_GetNextSysDocId())
			UPDATE  dbo.ARNEXTSY_local
			SET NextSysDocID = @SysDocId + 1
		
			/*  invoice header */
			SELECT  @LastOperation = 'insert invoice headers into transaction table '
			INSERT INTO ARTRANH_local ( CustomerKey, DocumentNumber, ApplyTo,
										Spare, Spare2, Spare3, TerritoryKey,
										SalespersonKey, CustomerClassKey,
										OrderNumber, ShipToKey, CheckBatch,
										TransactionType, DocumentDate, AgeDate,
										DocumentAmt, SysDocID, ApplySysDocID, RecUserID, RecDate,
										RecTime )
					SELECT	ih.[CUST KEY], 
							ih.[TRANS NO], 
							ih.[TRANS NO], 
							ih.SPARE, ih.SPARE2, ih.SPARE3, 
							ih.[TERRITORY KEY],
							ih.[SALESP    KEY], 
							ih.[CUST CLASS], '' AS OrderNumber,
							'' AS ShipToKey, '' AS CheckBatch,
							'I' AS TransactionType, 
							ih.[INV DATE],
							ih.[INV DATE] AS [AGE DATE],
							il.INVOICETOTAL AS INVOICETOTAL,
							@SysDocID AS SysDocId, 
							@SysDocID AS ApplySysDocID,
							@UserName AS RecUser,
							CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
							LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
							AS RecTime
						FROM tblInvHdr ih                               
						INNER JOIN ( SELECT [DOCUMENT NO],
											SUM([UNIT PRICE] * [QTY SHIPPED]) INVOICETOTAL
										FROM tblInvLin
										GROUP BY [DOCUMENT NO]
								   ) il
							ON ih.[TRANS NO] = il.[DOCUMENT NO]
						WHERE ih.[CUST CLASS] = 'INDIV'
						AND ih.[INV DATE] BETWEEN dbo.udf_GetFirstDayOfMonth(@InvoiceDate) 
									AND dbo.udf_GetLastDayOfMonth(@InvoiceDate);
	        
			SELECT  @LastOperation = 'insert invoice line item detail into transaction table'
	        
	        /*  invoice line item detail */
			INSERT INTO ARLINH_local ( CustomerKey, DocumentNumber, LocationKey,
									   CustomerClassKey, ItemKey, ItemDescription,
									   UnitPrice, QtyOrdered, QtyShipped, TaxKey,
									   RevenueAcctKey, CostAmt, RequestDate,
									   ShipDate, DocumentDate, SysDocID,
									   LineItemType, RecUserID, RecDate, RecTime )
					SELECT ih.[CUST KEY], ih.[TRANS NO], ih.[LOCATION  KEY],
							ih.[CUST CLASS], il.[ITEM KEY], il.[DESCRIPTION],
							il.[UNIT PRICE], il.[QTY ORDERED], il.[QTY SHIPPED],
							il.[TAX CODE], il.[REV ACCT],
							il.[UNIT PRICE] AS [COST AMT],
							ih.[INV DATE] AS [REQUEST DATE],
							ih.[INV DATE] AS [SHIP DATE],
							ih.[INV DATE] AS [DOCUMENT DATE], ih.SYSDOCID,
							il.LineItemTy, @UserName AS RecUser,
							CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
							LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
							AS RecTime
						FROM tblInvHdr AS ih 
						LEFT OUTER JOIN tblInvLin AS il
							ON ih.[TRANS NO] = il.[DOCUMENT NO]
						WHERE ih.[CUST CLASS] = 'INDIV'
						AND ih.[INV DATE] BETWEEN dbo.udf_GetFirstDayOfMonth(@InvoiceDate) 
									AND dbo.udf_GetLastDayOfMonth(@InvoiceDate);
									
			/*  ---  create sales receipt transaction  ---  */
			SELECT  @LastOperation = 'create sales receipt transactions for individual one off subscribers' 
	        
	        SET @SysDocID = ( SELECT dbo.udf_GetNextSysDocId())
			UPDATE  dbo.ARNEXTSY_local
			SET NextSysDocID = @SysDocId + 1
		
			SET @TranNo = (SELECT dbo.udf_GetNextTranNo())

			UPDATE ARONE_R9_local
			SET NextTransaction = @TranNo + 1	
			
			/*
			
			code update needed -
			
			this code segment was modified to process all the individual one offs
			instead of only one.  as it stands, this coded generates only one
			document number (@TranNo) and one SysDocID (@SysDocID) for every
			one off individual in the batch.
			
			need to add a temporary tables which contain separate document 
			numbers and SysDocIDs for each individual in the batch;  these
			temporary tables will need to be joined to the insert statement
			at the bottom.
			
				/*  generate DocumentNumbers */
				SELECT @LastOperation = 'create TranNos for sales receipt transactions ';

				IF OBJECT_ID('tempdb..#TranNo') IS NOT NULL
					DROP TABLE #TranNo;

				SELECT @TranNo = NextTransaction
				FROM dbo.ARONE_R9_local;

				SELECT IDENTITY(INT, 1, 1) AS [ID]
					, @TranNo TranNo
					, 0 AS NextTranNo
					, SysDocId
				INTO #TranNo
				FROM (
					SELECT SysDocId
					FROM dbo.ARTRANH_local
					WHERE DocumentDate = @InvoiceDate
						AND TransactionType = 'I'
						AND CustomerClassKey = 'INDIV'
					) art;

				UPDATE a
				SET NextTranNo = (b.TranNo + b.Id)
				FROM #TranNo a
				INNER JOIN #TranNo b
					ON a.ID = b.ID;

				/*  generate SysDocIds  */
				SELECT @LastOperation = 'generate SysDocIds';

				SET @SysDocID = (
						SELECT QCDdataSQL2005_uat.dbo.udf_GetNextSysDocId()
						);

				IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL
					DROP TABLE #SysDoc;

				SELECT IDENTITY(INT, 1, 1) AS [ID]
					, @SysDocID SysDocID
					, 0 AS NextSysDocID
					, ih.[TRANS NO]
					, [CUST KEY]
				INTO #SysDoc
				FROM (
					
					need a select statement here that pulls
					all the individual one off transactions
					from ARTRANH_local that were create from
					above
					
					) ih;

				/*  save the NextSysDocID  */
				UPDATE a
				SET NextSysDocID = (b.SysDocId + b.Id)
				FROM #SysDoc a
				INNER JOIN #SysDoc b
					ON a.ID = b.ID;
			
			*/        
	                
			INSERT INTO ARTRANH_local ( DocumentNumber, ApplyTo, TerritoryKey,
										SalespersonKey, CustomerKey,
										CustomerClassKey, OrderNumber, ShipToKey,
										CheckBatch, TransactionType, DocumentDate,
										AgeDate, DaysTillDue, DocumentAmt,
										DiscountAmt, FreightAmt, TaxAmt, CostAmt,
										CommissionHomeOvride, RetentionInvoice,
										SysDocID, ApplySysDocID, Spare, Spare2,
										Spare3, RecUserID, RecDate, RecTime )
	                
	                
					SELECT  SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) 
							+ CONVERT(NVARCHAR(9), @TranNo) AS DocumentNumber,
							art.DocumentNumber AS ApplyTo, art.TerritoryKey,
							art.SalespersonKey, art.CustomerKey,
							art.CustomerClassKey, art.OrderNumber, art.ShipToKey,
							CheckBatch, 'P' AS TransactionType,
							art.DocumentDate, 
							art.DocumentDate As AgeDate,
							art.DaysTillDue, 
							art.DocumentAmt * -1, 
							art.DiscountAmt,
							art.FreightAmt, art.TaxAmt, art.CostAmt,
							art.CommissionHomeOvride, art.RetentionInvoice,
							@SysDocID AS SysDocId,
							art.SysDocId AS ApplySysDocID, art.Spare, art.Spare2,
							art.Spare3, @UserName AS RecUser,
							CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
							LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
							AS RecTime
						FROM dbo.ARTRANH_local art
						WHERE art.CustomerClassKey = 'INDIV'
						AND art.DocumentDate BETWEEN dbo.udf_GetFirstDayOfMonth(@InvoiceDate) AND dbo.udf_GetLastDayOfMonth(@InvoiceDate)
						AND art.TransactionType = 'I'
						AND art.IFStatus = 'U';					
	    END    
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
        RETURN 1
    END CATCH
GO
