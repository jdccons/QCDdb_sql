USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReconPayment]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
	Object:			usp_ReconPayment
	Author:			John Criswell
	Version:		1
	Create date:	10/01/2014	 
	Description:	Reconciles payments between
					QuickBooks and Platinum 
					
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2014-10-15		JCriswell		Created
									
									
	
============================================= */
create procedure [dbo].[usp_ReconPayment] @InvoiceDate datetime

--exec usp_ReconPayment '2014-10-01 00:00:00'

as

declare @FirstDayOfMonth datetime
declare @LastDayOfMonth datetime
SET @FirstDayOfMonth = ( SELECT dbo.udf_GetFirstDayOfMonth(@InvoiceDate))
SET @LastDayOfMonth = ( SELECT  dbo.udf_GetLastDayOfMonth(@InvoiceDate))

SET NOCOUNT ON;

SELECT  isnull(qb.App , '') App,
        isnull(qb.TxnID, '') TxnID ,
        isnull(qb.TxnNumber, '')  TxnNumber ,
        isnull(qb.CustomerRef_FullName, '') CustomerRef_FullName ,
        isnull(qb.ARAccountRef_FullName, '') ARAccountRef_FullName ,
        isnull(qb.TxnDate, '') TxnDate ,
        isnull(qb.RefNumber, '') RefNumber ,
        isnull(qb.TotalAmount,0) TotalAmount ,
        isnull(qb.FullName, '') FullName ,
        isnull(qb.AccountNumber, '') AccountNumber ,
        isnull(pfw.App, '') App ,
        isnull(pfw.DocumentNumber, '') DocumentNumber ,
        isnull(pfw.DocumentDate, '') DocumentDate,
        isnull(pfw.ApplyTo, '') ApplyTo ,
        isnull(pfw.CustomerKey, '') CustomerKey ,
        isnull(pfw.CustomerClassKey, '') CustomerClassKey ,
        isnull(pfw.OrderNumber, '') OrderNumber ,
        isnull(pfw.TransactionType, '') TransactionType ,
        isnull(pfw.DocumentAmt,0) DocumentAmt ,
        isnull(cast(qb.TotalAmount as decimal(18,2)),0) - isnull(cast(pfw.DocumentAmt as decimal(18,2)),0) [Difference]
from
/*  QuickBooks  */
(
			SELECT    'QuickBooks' [App] ,
                    rp.TxnID ,
                    rp.TxnNumber ,
                    rp.CustomerRef_FullName ,
                    rp.ARAccountRef_FullName ,
                    rp.TxnDate ,
                    isnull(rp.RefNumber, '999999') RefNumber ,
                    cast(rp.TotalAmount as decimal(18,2)) TotalAmount ,
                    c.FullName ,
                    c.AccountNumber
			FROM    QuickBooks..receivepayment AS rp
                INNER JOIN QuickBooks..customer AS c ON rp.CustomerRef_FullName = c.FullName
			WHERE   rp.TxnDate between @FirstDayOfMonth and @LastDayOfMonth
) qb
                    
left outer join

/* Platinum */                    
(
		   SELECT    'PfW' [App] ,
                    isnull(art.DocumentNumber, '999999') DocumentNumber ,
                    isnull(art.ApplyTo, '') ApplyTo ,
                    art.DocumentDate,
                    art.CustomerKey ,
                    art.CustomerClassKey ,
                    isnull(art.OrderNumber, '') OrderNumber ,
                    art.TransactionType ,
                    cast((art.DocumentAmt * -1) as decimal(18,2)) DocumentAmt, 
                    Spare3
          FROM      QCDdataSQL2005_dev..ARTRANH_local art
          WHERE     art.DocumentDate between @FirstDayOfMonth and @LastDayOfMonth
          AND		art.TransactionType = 'P'
          AND		art.CustomerClassKey = 'GROUP'
                    
) pfw 
        ON qb.AccountNumber = pfw.CustomerKey
        and qb.RefNumber = pfw.DocumentNumber
        and qb.TxnDate = pfw.DocumentDate
        and qb.TotalAmount = pfw.DocumentAmt
        ORDER BY ARAccountRef_FullName, CustomerRef_FullName
GO
