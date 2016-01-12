USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_QCDOnlyInvoice]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QCDOnlyInvoice]
	
	(
	@InvoiceDate DateTime = NULL,
	@Class nvarchar(10) = NULL
	)
	
AS
	SET NOCOUNT ON 
	
	SELECT        Customer, [Transaction Date], RefNumber, [PO Number], Terms, Class, [Template Name], [To Be Printed], [Ship Date], [BillTo Line1], [BillTo Line2], [BillTo Line3], 
                         [BillTo Line4], [BillTo City], [BillTo State], [BillTo PostalCode], [BillTo Country], [ShipTo Line1], [ShipTo Line2], [ShipTo Line3], [ShipTo Line4], [ShipTo City], 
                         [ShipTo State], [ShipTo PostalCode], [ShipTo Country], Phone, Fax, Email, [Contact Name], [First Name], [Last Name], Rep, [Due Date], [Ship Method], 
                         [Customer Message], Memo, Item, Quantity, [Description], Price, [Is Pending], [Item Line Class], [Service Date], FOB, [Customer Acct No], [Sales Tax Item], 
                         [To Be E-Mailed], Other, Other1, Other2, [AR Account], [Sales Tax Code]
FROM            dbo.vw_PFWInvoices
WHERE        ([Ship Date] = @InvoiceDate) AND (Item = @Class)
GO
