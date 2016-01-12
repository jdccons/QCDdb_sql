USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_QB_Invoice]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QB_Invoice] (@InvoiceDate datetime)
AS
/* =============================================
	Object:			usp_QB_Invoice
	Author:			John Criswell
	Create date:	2014-09-08	 
	Description:	Takes invoices from QB
					and puts them in ARTRANH_local;
					this applies only to new invoices
					for any given billing month					
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */ 
DECLARE @BeginDate DATETIME
DECLARE @EndDate DATETIME
SET @BeginDate = (SELECT dbo.udf_GetFirstDayOfMonth(@InvoiceDate))
SET @EndDate = (SELECT dbo.udf_GetLastDayOfMonth(@InvoiceDate) ) 
                          
/*  sync up QCDdataSQL2005_dev..ARTRANH_local with QuickBooks..invoice */
/*  generate SysDocIds  */
DECLARE @SysDocID AS INTEGER
SET @SysDocID = ( SELECT QCDdataSQL2005_dev.dbo.udf_GetNextSysDocId()   
                )
IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL
    DROP TABLE #SysDoc
 
 SELECT IDENTITY( INT,1,1 ) AS [ID] ,
        @SysDocID SysDocID ,
        0 AS NextSysDocID ,
        qb.AccountNumber
 INTO   #SysDoc
 FROM   ( SELECT    c.AccountNumber
          FROM      QuickBooks..invoice i
                    INNER JOIN QuickBooks..customer c ON i.CustomerRef_FullName = c.FullName
          WHERE     i.TxnDate BETWEEN @BeginDate
                              AND     @EndDate
        ) qb
        LEFT OUTER JOIN ( SELECT    CustomerKey
                          FROM      QCDdataSQL2005_dev..ARTRANH_local art
                          WHERE     TransactionType = 'I'
                                    AND DocumentDate BETWEEN @BeginDate
                                                     AND     @EndDate
                        ) p ON RTRIM(qb.AccountNumber) = RTRIM(p.CustomerKey)
 WHERE  p.CustomerKey IS NULL
 ORDER BY qb.AccountNumber;
 
UPDATE a
SET NextSysDocID  = (b.SysDocId + b.Id)
FROM #SysDoc a
INNER JOIN #SysDoc b
	ON a.ID = b.ID 
 
/*  insert data from QuickBooks..invoice into ARTRANH_local*/	
INSERT  INTO QCDdataSQL2005_dev..ARTRANH_local
        ( DocumentNumber ,
          CustomerKey ,
          CustomerClassKey ,
          OrderNumber ,
          TransactionType ,
          DocumentDate ,
          DocumentAmt ,
          SysDocID ,
          RecUserID ,
          RecDate ,
          RecTime
        )
        SELECT  qb.RefNumber AS DocumentNumber ,
                qb.AccountNumber AS CustomerKey ,
                'INDIV' AS CustomerClassKey ,
                qb.TxnNumber AS OrderNumber ,
                'I' AS TransactionType ,
                qb.TxnDate AS DocumentDate ,
                qb.Subtotal AS DocumentAmt ,
                sd.NextSysDocID AS SysDocID ,
                'QCD db' AS RecUser ,
                CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate ,
                LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS RecTime
        FROM    ( SELECT    c.AccountNumber ,
                            i.TxnDate ,
                            i.RefNumber ,
                            i.Subtotal ,
                            i.TxnNumber
                  FROM      QuickBooks..invoice i
                            INNER JOIN QuickBooks..customer c ON i.CustomerRef_FullName = c.FullName
                  WHERE     i.TxnDate BETWEEN @BeginDate
                                      AND     @EndDate  
                  
                ) qb -- QuickBooks
        LEFT OUTER JOIN ( SELECT    CustomerKey
                          FROM      QCDdataSQL2005_dev..ARTRANH_local art
                          WHERE     TransactionType = 'I'
                                    AND DocumentDate BETWEEN @BeginDate
                                                     AND
                                                      @EndDate
                                ) p -- Platinum
        ON RTRIM(qb.AccountNumber) = RTRIM(p.CustomerKey)
        INNER JOIN #SysDoc sd
			ON RTRIM(qb.AccountNumber)  = RTRIM(sd.AccountNumber)
        WHERE   p.CustomerKey IS NULL
        ORDER BY qb.AccountNumber
        
        DECLARE @NextSysDocId AS INTEGER
        SELECT  @NextSysDocId = MAX(NextSysDocId)
        FROM    #SysDoc;
        UPDATE  dbo.ARNEXTSY_local
        SET     NextSysDocID = @NextSysDocId;
GO
