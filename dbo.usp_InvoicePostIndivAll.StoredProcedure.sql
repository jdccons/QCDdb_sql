USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePostIndivAll]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  individual interfaces  */
		CREATE PROCEDURE [dbo].[usp_InvoicePostIndivAll] 
			(
			@InvoiceDate AS DATETIME
			, @UserName AS NVARCHAR(20)
			)
		AS
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		/* ===============================================================================
			Object:			usp_InvoicePostIndivAll
			Version:		4
			Author:			John Criswell
			Create date:	2014-09-11	 
			Description:	Takes invoices from staging table
							and puts them in ARTRANH_local
							as sales receipts;
							
										
									
			Change Log:
			-------------------------------------------------------------------------------
			Change Date		Version		Changed by		Reason
			2015-01-20		4			JCriswell		Added where clause to all sections
														i.e. where art.CustomerClassKey = 'INDIV'
			2016-01-11		5			J Criswell		Added IFStatus = U to where clause for sales receipts
			
			
		=================================================================================== */
		/*  declarations  */
		DECLARE @LastOperation VARCHAR(128)
			, @ErrorMessage VARCHAR(8000)
			, @ErrorSeverity INT
			, @ErrorState INT
		DECLARE @SysDocID AS INTEGER
			, @NextSysDocId AS INTEGER
			, @BeginSysDocId AS INTEGER
			, @EndSysDocId AS INTEGER
			, @TranNo AS INTEGER
			, @NextTranNo AS INTEGER

		------------------------------------------------------------------------------
		BEGIN TRY
			BEGIN TRANSACTION

			/*  generate SysDocIds  */
			SELECT @LastOperation = 'generate SysDocIds';

			SET @SysDocID = (SELECT QCDdataSQL2005_uat.dbo.udf_GetNextSysDocID());

			IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL
				DROP TABLE #SysDoc;

			SELECT IDENTITY(INT, 1, 1) AS [ID]
				, @SysDocID SysDocID
				, 0 AS NextSysDocID
				, ih.[TRANS NO]
				, [CUST KEY]
			INTO #SysDoc
			FROM (
				SELECT [TRANS NO]
					, [CUST KEY]
				FROM tblInvHdr
				WHERE [CUST CLASS] = 'INDIV'
				) ih;

			UPDATE a
			SET NextSysDocID = (b.SysDocId + b.Id)
			FROM #SysDoc a
			INNER JOIN #SysDoc b
				ON a.ID = b.ID;

			/*  create invoice transacitons  */
			SELECT @LastOperation = 'insert invoice headers into transaction table ';
			INSERT INTO ARTRANH_local (
				CustomerKey, DocumentNumber, ApplyTo, Spare, Spare2, Spare3, 
				TerritoryKey, SalespersonKey, CustomerClassKey, OrderNumber, 
				ShipToKey, CheckBatch, TransactionType, DocumentDate, AgeDate, 
				DocumentAmt, SysDocID, RecUserID, RecDate, RecTime
				)
			SELECT ih.[CUST KEY], ih.[TRANS NO], ih.[TRANS NO], ih.SPARE, ih.
				SPARE2, ih.SPARE3, ih.[TERRITORY KEY], ih.[SALESP    KEY], ih.
				[CUST CLASS], '' AS OrderNumber, '' AS ShipToKey, '' AS CheckBatch, 'I' 
				AS TransactionType, ih.[INV DATE], ih.[INV DATE] AS [AGE DATE], il.
				INVOICETOTAL AS INVOICETOTAL, sd.NextSysDocId AS SysDocId, 
				@UserName AS RecUser, CONVERT(VARCHAR(10), GETDATE(), 101) AS 
				RecDate, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS 
				RecTime
			FROM tblInvHdr ih
			INNER JOIN #SysDoc sd
				ON ih.[CUST KEY] = sd.[CUST KEY]
					AND ih.[TRANS NO] = sd.[TRANS NO]
			INNER JOIN (
				SELECT [DOCUMENT NO], SUM([UNIT PRICE] * [QTY SHIPPED]) 
					INVOICETOTAL
				FROM tblInvLin
				GROUP BY [DOCUMENT NO]
				) il
				ON ih.[TRANS NO] = il.[DOCUMENT NO]
			WHERE ih.[CUST CLASS] = 'INDIV';

			/*  create line item detail  */
			SELECT @LastOperation = 'insert invoice line item detail into transaction table';
			INSERT INTO ARLINH_local (
				CustomerKey, DocumentNumber, LocationKey, CustomerClassKey, 
				ItemKey, ItemDescription, UnitPrice, QtyOrdered, QtyShipped, 
				TaxKey, RevenueAcctKey, CostAmt, RequestDate, ShipDate, 
				DocumentDate, SysDocID, LineItemType, SPARE, SPARE2, SPARE3, 
				RecUserID, RecDate, RecTime
				)
			SELECT ih.[CUST KEY], ih.[TRANS NO], ih.[LOCATION  KEY], ih.
				[CUST CLASS], il.[ITEM KEY], il.[DESCRIPTION], il.[UNIT PRICE], 
				il.[QTY ORDERED], il.[QTY SHIPPED], il.[TAX CODE], il.[REV ACCT]
				, il.[UNIT PRICE] AS [COST AMT], ih.[INV DATE] AS [REQUEST DATE], ih
				.[INV DATE] AS [SHIP DATE], ih.[INV DATE] AS [DOCUMENT DATE], ih.
				SYSDOCID, il.LineItemTy, ih.Spare, ih.Spare2, ih.Spare3, @UserName 
				AS RecUser, CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate, LTRIM(
					RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
			FROM tblInvHdr AS ih
			LEFT OUTER JOIN tblInvLin AS il
				ON ih.[TRANS NO] = il.[DOCUMENT NO]
			WHERE ih.[CUST CLASS] = 'INDIV';
			
			/*  create SysDocIDs for sales receipts  */
			SELECT @LastOperation = 'create SysDocIds for sales receipt transactions.';

			SELECT @SysDocID = MAX(SysDocId)
			FROM ARTRANH_local
			WHERE DocumentDate = @InvoiceDate;

			IF OBJECT_ID('tempdb..#SysDocSalesRecp') IS NOT NULL
				DROP TABLE #SysDocSalesRecp;

			SELECT IDENTITY(INT, 1, 1) AS [ID]
				, @SysDocID SysDocID
				, 0 AS NextSysDocID
				, iSysDocId
			INTO #SysDocSalesRecp
			FROM (
				SELECT SysDocID AS iSysDocId
				FROM dbo.ARTRANH_local
				WHERE DocumentDate = @InvoiceDate
					AND TransactionType = 'I'
					AND CustomerClassKey = 'INDIV'
				) art;

			UPDATE a
			SET NextSysDocID = (b.SysDocId + b.Id)
			FROM #SysDoc a
			INNER JOIN #SysDoc b
				ON a.ID = b.ID;

			/*  create DocumentNumbers for sales receipts  */
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

			/*  save the last SysDocID  */
			SELECT @LastOperation = 'save NextSysDocId';

			IF EXISTS (
					SELECT 1
					FROM #SysDoc
					)
			BEGIN
				SELECT @NextSysDocID = MAX(NextSysDocID)
				FROM #SysDoc;

				UPDATE dbo.ARNEXTSY_local
				SET NextSysDocID = @NextSysDocId + 1
			END;

			/*  create sales receipt transactions  */
			SELECT @LastOperation = 'create sales receipt transactions for multiple individuals';
			INSERT INTO ARTRANH_local (
				DocumentNumber, ApplyTo, TerritoryKey, SalespersonKey, 
				CustomerKey, CustomerClassKey, OrderNumber, ShipToKey, CheckBatch
				, TransactionType, DocumentDate, AgeDate, DaysTillDue, DocumentAmt
				, DiscountAmt, FreightAmt, TaxAmt, CostAmt, CommissionHomeOvride, 
				RetentionInvoice, SysDocID, ApplySysDocID, Spare, Spare2, Spare3, 
				RecUserID, RecDate, RecTime
				)
			SELECT SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
				CONVERT(NVARCHAR(9), tn.NextTranNo) AS DocumentNumber, art.
				DocumentNumber AS ApplyTo, art.TerritoryKey, art.SalespersonKey, 
				art.CustomerKey, art.CustomerClassKey, art.OrderNumber, art.
				ShipToKey, CheckBatch, 'P' AS TransactionType, @InvoiceDate 
				DocumentDate, @InvoiceDate AgeDate, art.DaysTillDue, art.
				DocumentAmt * - 1, art.DiscountAmt, art.FreightAmt, art.TaxAmt, art.
				CostAmt, art.CommissionHomeOvride, art.RetentionInvoice, sd.
				NextSysDocID AS SysDocId, art.SysDocId AS ApplySysDocID, art.Spare, 
				art.Spare2, art.Spare3, @UserName AS RecUser, CONVERT(VARCHAR(10), 
					GETDATE(), 101) AS RecDate, LTRIM(RIGHT(CONVERT(VARCHAR(20), 
							GETDATE(), 100), 7)) AS RecTime
			FROM dbo.ARTRANH_local art
			INNER JOIN #SysDocSalesRecp sd
				ON art.SysDocID = sd.iSysDocId
			INNER JOIN #TranNo tn
				ON art.SysDocID = tn.SysDocId
			WHERE art.DocumentDate = @InvoiceDate
				AND art.TransactionType = 'I'
				AND art.CustomerClassKey = 'INDIV'
				AND art.IFStatus = 'U';


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

			RETURN 0
		END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Takes invoices from staging table and puts them in ARTRANH_local as sales receipts.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_InvoicePostIndivAll'
GO
