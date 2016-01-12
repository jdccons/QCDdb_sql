USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePostGroup]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InvoicePostGroup]
    (
      @InvoiceDate DATETIME ,
      @GroupType AS NVARCHAR(12)
    )
AS 

/* ======================================================================================
	Object:			usp_InvoicePostGroup
	Version:		4
	Author:			John Criswell
	Create date:	9/8/2014	 
	Description:	Posts bulk invoices for groups;
					inserts records into final transaction tables;
					SysDocIds are assigned in
					this stage to each invoice - one for
					each invoice in each group.  Group invoices are first
					inserted into ARTRANH_local
					and then into ARLINH_local.
					Subscribers and their dependents for each group
					are inserted into ARLINH_local 
					
						
	Change Log:
	-------------------------------------------------------------------------------------
	Change Date			Version		Changed by		Reason
	2015-01-12			2.0			JCriswell		Added Spare, Spare2, and Spare3 to
													insert into ARLINH_local
	2015-01-20			3.0			JCriswell		Added statement to where clause
													i.e. where [CUST CLASS] = 'GROUP'
	2015-03-06			4.0			JCriswell		Bug when inserting into ARLINH_local;
													now pulling Spare, Spare2, and Spare3 from
													tblInvLin instead of tblInvHdr.  Now
													SubID, SubSSN, and GroupType are populating
													ARLINH_local correctly.
	
========================================================================================= */

/*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    DECLARE @SysDocID AS INTEGER ,
        @NextSysDocId AS INTEGER ,
        @BeginSysDocId AS INTEGER ,
        @EndSysDocId AS INTEGER ,
        @NextTranNo AS INTEGER             
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION
		/*  generate SysDocIds  */
        SELECT  @LastOperation = 'generate SysDocIds'
		
        SET @SysDocID = ( SELECT dbo.udf_GetNextSysDocId())
        
        IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL 
            DROP TABLE #SysDoc
 
        SELECT  IDENTITY( INT,1,1 ) AS [ID] ,
                @SysDocID SysDocID ,
                0 AS NextSysDocID ,
                ih.[TRANS NO] ,
                [CUST KEY]
        INTO    #SysDoc
        FROM    ( SELECT    [TRANS NO] ,
                            [CUST KEY]
                  FROM      tblInvHdr
                  WHERE SPARE3 = @GroupType
                  AND [CUST CLASS] = 'GROUP'
                ) ih;
        
        UPDATE  a
        SET     NextSysDocID = ( b.SysDocId + b.Id )
        FROM    #SysDoc a
                INNER JOIN #SysDoc b ON a.ID = b.ID; 
                
        SELECT  @LastOperation = 'save NextSysDocId';
        
        SELECT  @NextSysDocId = MAX(NextSysDocId)
        FROM    #SysDoc;
        
        UPDATE  dbo.ARNEXTSY_local
        SET     NextSysDocID = @NextSysDocId;
	
        SELECT  @LastOperation = 'insert invoice headers into transaction table ';
			
        INSERT  INTO ARTRANH_local
                ( CustomerKey ,
                  DocumentNumber ,
                  ApplyTo ,
                  Spare ,
                  Spare2 ,
                  Spare3 ,
                  TerritoryKey ,
                  SalespersonKey ,
                  CustomerClassKey ,
                  OrderNumber ,
                  ShipToKey ,
                  CheckBatch ,
                  TransactionType ,
                  DocumentDate ,
                  AgeDate ,
                  DocumentAmt ,
                  SysDocID ,
                  RecUserID ,                  
                  RecDate ,
                  RecTime
                )
                SELECT  ih.[CUST KEY] ,
                        ih.[TRANS NO] ,
                        ih.[TRANS NO] ,
                        ih.SPARE ,
                        ih.SPARE2 ,
                        ih.SPARE3 ,
                        ih.[TERRITORY KEY] ,
                        ih.[SALESP    KEY] ,
                        ih.[CUST CLASS] ,
                        '' AS OrderNumber ,
                        '' AS ShipToKey ,
                        '' AS CheckBatch ,
                        'I' AS TransactionType ,
                        ih.[INV DATE] ,
                        ih.[INV DATE] AS [AGE DATE] ,
                        ISNULL(il.INVOICETOTAL, 0) AS INVOICETOTAL ,
                        sd.NextSysDocId AS SysDocId ,
                        'QCD db' AS RecUser ,
                        CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate ,
                        LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
                FROM    tblInvHdr ih
                        INNER JOIN #SysDoc sd ON ih.[CUST KEY] = sd.[CUST KEY]
                                                 AND ih.[TRANS NO] = sd.[TRANS NO]
                        LEFT OUTER JOIN ( SELECT [DOCUMENT NO] ,
                                            SUM([UNIT PRICE] * [QTY SHIPPED]) INVOICETOTAL
                                     FROM   tblInvLin
                                     GROUP BY [DOCUMENT NO]
                                   ) il ON ih.[TRANS NO] = il.[DOCUMENT NO]
                WHERE ih.[CUST CLASS] = 'GROUP';
        
        SELECT  @LastOperation = 'insert invoice line item detail into transaction table';
        -- insert subscribers and dependents into ARLINH_local
        INSERT  INTO ARLINH_local
                ( CustomerKey ,
                  DocumentNumber ,
                  LocationKey ,
                  CustomerClassKey ,
                  ItemKey ,
                  ItemDescription ,
                  UnitPrice ,
                  QtyOrdered ,
                  QtyShipped ,
                  TaxKey ,
                  RevenueAcctKey ,
                  CostAmt ,
                  RequestDate ,
                  ShipDate ,
                  DocumentDate ,
                  SysDocID ,
                  Spare ,
                  Spare2 ,
                  Spare3 ,
                  LineItemType ,
                  RecUserID ,
                  RecDate ,
                  RecTime
                )
                SELECT  ih.[CUST KEY] ,
                        ih.[TRANS NO] ,
                        ih.[LOCATION  KEY] ,
                        ih.[CUST CLASS] ,
                        il.[ITEM KEY] ,
                        il.[DESCRIPTION] ,
                        il.[UNIT PRICE] ,
                        il.[QTY ORDERED] ,
                        il.[QTY SHIPPED] ,
                        il.[TAX CODE] ,
                        il.[REV ACCT] ,
                        il.[UNIT PRICE] AS [COST AMT] ,
                        ih.[INV DATE] AS [REQUEST DATE] ,
                        ih.[INV DATE] AS [SHIP DATE] ,
                        ih.[INV DATE] AS [DOCUMENT DATE] ,
                        ih.SYSDOCID ,
                        il.[SPARE] Spare ,						-- version 4.0 change
                        il.[SPARE2] Spare2 ,					--
                        il.[SPARE3] Spare3 ,					--
                        il.LineItemTy ,
                        'QCD db' AS RecUser ,
                        CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate ,
                        LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
                FROM    tblInvHdr AS ih
                        LEFT OUTER JOIN tblInvLin AS il ON ih.[TRANS NO] = il.[DOCUMENT NO]
                WHERE   ih.[SPARE3] = @GroupType
                AND		ih.[CUST CLASS] = 'GROUP';
        
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Posts bulk invoices for groups.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_InvoicePostGroup'
GO
