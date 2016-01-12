USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReconInvoice]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_ReconInvoice] (@InvoiceDate datetime)
as
/* =============================================
	Object:			usp_ReconInvoice
	Author:			John Criswell
	Version:		1
	Create date:	2014-10-18	 
	Description:	reconciliation of invoices; 
					compares QuickBooks invoices
					to PfW invoices; identifies
					the differences		
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */
/*  reconcile invoice to ARTRANH */
SELECT  isnull(qb.App , 'QuickBooks') App,
        isnull(qb.TxnID, '') TxnID ,
        isnull(qb.TxnNumber, '')  TxnNumber ,
        isnull(qb.CustomerRef_FullName, '') CustomerRef_FullName ,
        isnull(qb.ARAccountRef_FullName, '') ARAccountRef_FullName ,
        isnull(qb.TxnDate, '') TxnDate ,
        isnull(qb.RefNumber, '') RefNumber ,
        isnull(qb.Subtotal,0) SubTotal ,
        isnull(qb.FullName, '') FullName ,
        isnull(qb.AccountNumber, '') AccountNumber ,
        isnull(pfw.App, 'PfW') App ,
        isnull(pfw.DocumentNumber, '') DocumentNumber ,
        isnull(pfw.ApplyTo, '') ApplyTo ,
        isnull(pfw.CustomerKey, '') CustomerKey ,
        isnull(pfw.CustomerClassKey, '') CustomerClassKey ,
        isnull(pfw.OrderNumber, '') OrderNumber ,
        isnull(pfw.TransactionType, '') TransactionType ,
        isnull(pfw.DocumentAmt,0) DocumentAmt ,
        (isnull(cast(qb.Subtotal as decimal(18,2)),0) - isnull(cast(pfw.DocumentAmt as decimal(18,2)), 0)) [Difference]
FROM    ( 
			/* txns from QuickBooks */
			SELECT    'QuickBooks' [App] ,
                    i.TxnID ,
                    i.TxnNumber ,
                    i.CustomerRef_FullName ,
                    i.ARAccountRef_FullName ,
                    i.TxnDate ,
                    i.RefNumber ,
                    cast(i.Subtotal as decimal(18,2)) Subtotal ,
                    c.FullName ,
                    c.AccountNumber
          FROM      QuickBooks..invoice AS i
                    INNER JOIN QuickBooks..customer AS c ON i.CustomerRef_FullName = c.FullName
          WHERE     MONTH(i.TxnDate) = month(@InvoiceDate)
                    AND YEAR(i.TxnDate) = year(@InvoiceDate)
        ) qb     
        
        FULL OUTER JOIN 
        
        ( 
			/*  txns from PfW  */
			SELECT    'PfW' [App] ,
                    art.DocumentNumber ,
                    art.ApplyTo ,
                    art.CustomerKey ,
                    art.CustomerClassKey ,
                    art.OrderNumber ,
                    art.TransactionType ,
                    cast(art.DocumentAmt as decimal(18,2)) DocumentAmt, 
                    Spare3
          FROM      QCDdataSQL2005_dev..ARTRANH_local art
          WHERE     MONTH(art.DocumentDate) = month(@InvoiceDate)
                    AND YEAR(art.DocumentDate) = year(@InvoiceDate)
                    AND art.TransactionType = 'I'
                        
        ) pfw 
        ON qb.AccountNumber = pfw.CustomerKey
        and qb.RefNumber = pfw.DocumentNumber
        ORDER BY ARAccountRef_FullName, CustomerRef_FullName;
GO
