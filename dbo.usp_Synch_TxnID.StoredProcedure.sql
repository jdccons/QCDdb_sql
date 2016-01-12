USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_Synch_TxnID]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--use QCDdataSQL2005_dev;
--go
--exec usp_Synch_TxnID '2015-10-01 00:00:00';


CREATE PROCEDURE [dbo].[usp_Synch_TxnID]
    (
      @InvoiceDate DATETIME                                                                                   
    )
AS 

/* =============================================
	Object:			usp_Sync_TxnID
	Version:		5
	Author:			John Criswell
	Create date:	2014-09-21	 
	Description:	Synchronizes the QuickBooks TxnID
					on receivepayments table
					and the salesreceipts table with
					DocumentNumber, CustomerKey and DocumentDate
					on ARTRANH_local;
					
								
							
	Change Log:
	--------------------------------------------
	Change Date		Version			Changed by		Reason
	2014-10-28		3.0				JCriswell		Changed the logic of the update
													to include IFStatus on ARTRANH_local
	2015-12-03		4.0				JCriswell		Changed QuickBooks select to include sales
													receipts from individuals
	2015-12-08		5.0				JCriswell		Changed the where clause on Access payments
													so that it pull non-interfaced and pending
													interface transactions.
	
	
============================================= */

	/*  declarations  */
	DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    DECLARE @FirstDayOfMonth DATETIME ,
        @LastDayOfMonth DATETIME
        
        ------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION	
    
    SET @FirstDayOfMonth = ( SELECT dbo.udf_GetFirstDayOfMonth(@InvoiceDate))
    SET @LastDayOfMonth = ( SELECT  dbo.udf_GetLastDayOfMonth(@InvoiceDate))
    
    SELECT  @LastOperation = 'update ARTRANH_local with TxnIds '
        
    UPDATE art
    SET OrderNumber = pmt.TxnID, 
    IFStatus = 'I'
    FROM ARTRANH_local [art]
    INNER JOIN (    
					
					SELECT *
                    FROM 
                    /*  Access payments */ 
                    ( SELECT RTRIM(CASE WHEN DocumentNumber = ''
                                             THEN '999999'
                                             WHEN DocumentNumber IS NULL
                                             THEN '999999'
                                             ELSE DocumentNumber
                                        END) AS DocumentNumber,
                                RTRIM(CustomerKey) CustomerKey, DocumentDate,
                                ( DocumentAmt * -1 ) DocumentAmt
                            FROM ARTRANH_local
                            WHERE (IFStatus != 'I'  -- un-interfaced or pending interface (v5 change)
                                AND (DocumentDate between @FirstDayOfMonth and @LastDayOfMonth)
                                AND (TransactionType = 'P'))
                    ) plt  -- Platinum/Access
                    INNER JOIN 
                    /*  QuickBooks payments  */
                    ( 	
						/*  Group receive payments  */
						SELECT CASE WHEN rp.RefNumber = '' THEN '999999' WHEN rp.RefNumber IS 
									NULL THEN '999999' ELSE RTRIM(rp.RefNumber) END 
							RefNumber, RTRIM(cqb.AccountNumber) AccountNumber, rp.
							TxnDate, rp.TotalAmount, rp.TxnID
						FROM QuickBooks.dbo.receivepayment AS rp
						LEFT OUTER JOIN QuickBooks.dbo.customer cqb
							ON rp.CustomerRef_FullName = cqb.FullName
						LEFT OUTER JOIN QCDdataSQL2005_dev.dbo.vw_Customer AS ca
							ON cqb.AccountNumber = ca.CustomerKey
						WHERE rp.TxnDate BETWEEN @FirstDayOfMonth
								AND @LastDayOfMonth
						
						UNION
						/*  individual sales receipts  */
						SELECT
								/*  with reference to sales receipts, must match the check number to the document number  */ 
								CASE 
									WHEN sr.CheckNumber = '' THEN '999999' 
									WHEN sr.CheckNumber IS NULL THEN '999999' 
									ELSE RTRIM(sr.CheckNumber) 
									END AS RefNumber, 
						RTRIM(cqb.AccountNumber) AccountNumber, sr.
							TxnDate, sr.TotalAmount, sr.TxnID
						FROM QuickBooks.dbo.salesreceipt sr
						LEFT OUTER JOIN QuickBooks.dbo.customer cqb
							ON sr.CustomerRef_FullName = cqb.FullName
						LEFT OUTER JOIN QCDdataSQL2005_dev.dbo.vw_Customer AS ca
							ON cqb.AccountNumber = ca.CustomerKey
						WHERE sr.TxnDate BETWEEN @FirstDayOfMonth
								AND @LastDayOfMonth
					) qb  -- QuickBooks
                        ON plt.DocumentNumber = qb.RefNumber
                           AND plt.CustomerKey = qb.AccountNumber
                           AND plt.DocumentDate = qb.TxnDate
               ) pmt
        ON RTRIM(CASE WHEN [art].DocumentNumber = '' THEN '999999'
                      WHEN [art].DocumentNumber IS NULL THEN '999999'
                      ELSE [art].DocumentNumber
                 END) = [pmt].DocumentNumber
           AND [art].CustomerKey = [pmt].CustomerKey
           AND [art].DocumentDate = [pmt].DocumentDate
        WHERE [art].DocumentDate between @FirstDayOfMonth and @LastDayOfMonth;
            
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
