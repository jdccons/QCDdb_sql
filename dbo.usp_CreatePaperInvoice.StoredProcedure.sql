USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreatePaperInvoice]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CreatePaperInvoice]
    (
      @InvoiceDate AS DATETIME ,
      @GroupType AS NVARCHAR(12)
    )
AS
/* =============================================
	Object:			usp_CreatePaperInvoice
	Author:			John Criswell
	Create date:	2015-02-23	 
	Description:	Populates temp tables with invoice data
					to run paper invoices for groups
					
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2015-02-23		JCriswell		Created
	
	
============================================= */
    DELETE FROM ARHDR_temp
    INSERT INTO ARHDR_temp ( Custkey, Custname, CustAdd1Trim, Custaddr2,
                             CityStateZip, Tranno, Invdate, Salespkey, Spare,
                             InvTot, GroupType, GROUPid, InvoiceType )
            SELECT art.CustomerKey, arc.CustomerName,
                    RTRIM(arc.CustomerAddress1) AS CustAdd1rtrim,
                    arc.CustomerAddress2,
                    RTRIM(arc.CustomerCity) + ', ' + RTRIM(arc.CustomerState)
                    + '  ' + RTRIM(arc.CustomerZipCode) AS CityStateZip,
                    RTRIM(art.DocumentNumber) AS Tranno, art.DocumentDate,
                    art.SalespersonKey, arc.Spare, art.DocumentAmt,
                    CASE WHEN art.Spare3 = 'QCD Only' THEN 1
                         WHEN art.Spare3 = 'All American' THEN 4
                         ELSE 0
                    END GroupType, art.CustomerKey AS GroupId,
                    1 AS InvoiceType
                FROM ARTRANH_local AS art
                INNER JOIN ARCUST_local AS arc
                    ON art.CustomerKey = arc.CustomerKey
                WHERE ( art.Spare3 = @GroupType )
                    AND ( art.DocumentDate = @InvoiceDate )
                    AND ( art.TransactionType = 'I' )
                    
    INSERT INTO ARLIN_temp ( HdrId, Tranno, [Description], Name, Unitprice )
            SELECT arh.ID AS HdrID, arl.DocumentNumber, arl.[ItemKey], arl.[ItemDescription],
                    arl.UnitPrice
                FROM ARTRANH_local art
                INNER JOIN dbo.ARHDR_temp arh
					ON art.CustomerKey = arh.Custkey
					AND art.DocumentNumber = arh.Tranno
                INNER JOIN dbo.ARLINH_local arl
                    ON art.CustomerKey = arl.CustomerKey
                       AND art.DocumentNumber = arl.DocumentNumber
                             WHERE ( art.Spare3 = @GroupType )				--@GroupType = 'QCD Only'
								AND ( art.DocumentDate = @InvoiceDate )		--@InvoiceDate = '2014-08-01 00:00:00'
								AND ( art.TransactionType = 'I' )
								AND ( arl.LineItemType = '1')
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Populates temp tables with invoice data to run paper invoices for groups.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_CreatePaperInvoice'
GO
