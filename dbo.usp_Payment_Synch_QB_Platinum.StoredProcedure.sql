USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_Payment_Synch_QB_Platinum]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Payment_Synch_QB_Platinum]
    (
      @InvoiceDate DATETIME
    )
AS 

/* =============================================
	Object:			usp_Payment_Synch_QB_Platinum
	Author:			John Criswell
	Version:		4
	Create date:		 
	Description:	in the event customer 
					payments are entered directly
					into QuickBooks, this stored
					procedure will insert these
					payments into ARTRANH_local	
					and synchronize ARTRANH_local
					to QuickBooks			
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2014-09-28		JCriswell		Changed logic to include groups
									in addition to individuals
	
	
============================================= */
    BEGIN TRY
        BEGIN TRANSACTION
	----------------------------------------------      
	/*   declarations  */
        DECLARE @LastOperation VARCHAR(128) ,
            @ErrorMessage VARCHAR(8000) ,
            @ErrorSeverity INT ,
            @ErrorState INT  
        	
        DECLARE @SysDocID AS INTEGER ,
            @NextSysDocId AS INTEGER 
        
	---------------------------------------------
        
		/*  generate SysDocIds  */
        SELECT  @LastOperation = 'generate SysDocIds'
        
        SET @SysDocID = ( SELECT dbo.udf_GetNextSysDocId()
                        )
        IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL 
            DROP TABLE #SysDoc
 
		SELECT  @LastOperation = 'find out if any records need to be synched ' 		
        SELECT  IDENTITY( INT,1,1 ) AS [ID] ,
                @SysDocID SysDocID ,
                0 AS NextSysDocID ,
                pmt.AccountNumber ,
                pmt.RefNumber
        INTO    #SysDoc
        FROM    (
				/*  reconcile payments */
				SELECT qb.RefNumber, qb.AccountNumber
				FROM 
					(
				/*  QuickBooks */ 
				SELECT ISNULL(rp.RefNumber, '999999') RefNumber, c.AccountNumber
					FROM QuickBooks.dbo.receivepayment AS rp
					LEFT OUTER JOIN QuickBooks.dbo.customer AS c
						ON rp.CustomerRef_FullName = c.FullName
					LEFT OUTER JOIN vw_Customer AS cust
						ON c.AccountNumber = cust.CustomerKey
					WHERE MONTH(rp.TxnDate) = MONTH(@InvoiceDate)
						AND  YEAR(rp.TxnDate) = YEAR(@InvoiceDate)
					) qb
					LEFT OUTER JOIN 
					(        
				/* Platinum-Access */ 
				SELECT CASE WHEN DocumentNumber = '' THEN '999999'
							WHEN DocumentNumber IS NULL THEN '999999'
							ELSE DocumentNumber
					   END AS DocumentNumber, CustomerKey
					FROM ARTRANH_local
					WHERE MONTH(DocumentDate)  = MONTH(@InvoiceDate)
						AND     YEAR(DocumentDate) = YEAR(@InvoiceDate)
						AND TransactionType != 'I'  
					) plt
						ON qb.RefNumber = plt.DocumentNumber
						   AND qb.AccountNumber = plt.CustomerKey
					WHERE plt.DocumentNumber IS NULL
				/*  end of payment reconciliation */
                ) pmt
    
        SELECT  @LastOperation = 'update temp table with NextSysDocIDs ' 	
        UPDATE  a
        SET     NextSysDocID = ( b.SysDocId + b.Id )
        FROM    #SysDoc a
                INNER JOIN #SysDoc b ON a.ID = b.ID 
       
		IF EXISTS(SELECT 1 FROM #SysDoc)
        BEGIN       
			SELECT  @LastOperation = 'save NextSysDocId'
	      	SELECT  @NextSysDocId = MAX(NextSysDocId)
			FROM    #SysDoc;
	        	        
			UPDATE  dbo.ARNEXTSY_local
			SET     NextSysDocID = @NextSysDocId
		
			SELECT  @LastOperation = 'Insert new group and individual payments into ARTRANH_local'
			INSERT  INTO ARTRANH_local
                ( DocumentNumber ,
                  CustomerKey ,
                  OrderNumber ,
                  CustomerClassKey ,
                  DocumentDate ,
                  AgeDate ,
                  DocumentAmt ,
                  TerritoryKey ,
                  TransactionType ,
                  SysDocID ,
                  Spare ,
                  Spare2 ,
                  Spare3 ,
                  RecUserID ,
                  RecDate ,
                  RecTime
                )
            /*  reconcile payments  */
			SELECT qb.RefNumber AS DocumentNumber, qb.AccountNumber AS CustomerKey,
					qb.TxnID AS OrderNumber,
					CASE WHEN qb.ARAccountRef_FullName = 'Accts Rec-QCD Only' THEN 'GROUP'
						 WHEN qb.ARAccountRef_FullName = 'Accts Rec-All American'
						 THEN 'GROUP'
						 WHEN qb.ARAccountRef_FullName = 'Accts Rec-Individual'
						 THEN 'INDIV'
					END AS CustomerClass, qb.TxnDate AS CheckDate, qb.TxnDate AS AgeDate,
					qb.TotalAmount * -1 AS CheckAmt, '' AS GRGeoID, 'P' AS TransactionType,
					sd.NextSysDocID AS SysDocId ,
					'' AS Spare, '' AS Spare2,
					CASE WHEN qb.ARAccountRef_FullName = 'Accts Rec-QCD Only'
						 THEN 'QCD Only'
						 WHEN qb.ARAccountRef_FullName = 'Accts Rec-All American'
						 THEN 'All American'
						 WHEN qb.ARAccountRef_FullName = 'Accts Rec-Individual'
						 THEN 'Individual'
					END AS Spare3, 'QCD db' AS RecUserID,
					CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
					LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
			FROM 
				(
				/*  QuickBooks */ 
				SELECT ISNULL(rp.RefNumber, '999999') RefNumber, c.AccountNumber, rp.TxnID,
						rp.ARAccountRef_FullName, rp.TxnDate, rp.TotalAmount
					FROM QuickBooks.dbo.receivepayment AS rp
					LEFT OUTER JOIN QuickBooks.dbo.customer AS c
						ON rp.CustomerRef_FullName = c.FullName
					LEFT OUTER JOIN vw_Customer AS cust
						ON c.AccountNumber = cust.CustomerKey
					WHERE MONTH(rp.TxnDate) = MONTH(@InvoiceDate)
						AND  YEAR(rp.TxnDate) = YEAR(@InvoiceDate) 
				) qb
			LEFT OUTER JOIN 
				(        
				/* Platinum-Access */ 
				SELECT CASE WHEN DocumentNumber = '' THEN '999999'
							WHEN DocumentNumber IS NULL THEN '999999'
							ELSE DocumentNumber
					   END AS DocumentNumber, CustomerKey
					FROM ARTRANH_local
					WHERE MONTH(DocumentDate)  = MONTH(@InvoiceDate)
						AND YEAR(DocumentDate) = YEAR(@InvoiceDate)
						AND TransactionType != 'I'   
					) plt
				ON qb.RefNumber = plt.DocumentNumber
				   AND qb.AccountNumber = plt.CustomerKey
			INNER JOIN [#SysDoc] AS sd 
				ON qb.AccountNumber = sd.AccountNumber
                        AND qb.RefNumber = sd.RefNumber 
				WHERE plt.DocumentNumber IS NULL;
			/*  end of payment reconciliation */
		END         
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
    END CATCH;
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Inserts payments into ARTRANH_local and synchronizes to QuickBooks.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_Payment_Synch_QB_Platinum'
GO
