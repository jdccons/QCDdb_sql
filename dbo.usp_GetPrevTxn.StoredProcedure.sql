USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPrevTxn]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetPrevTxn] (
	@CustomerKey NVARCHAR(20)
	, @TxnDate DATETIME
	, @DocumentAmt numeric(18,2)  -- version 2.0
	)
AS

/* ====================================================================================
	Object:			usp_GetPrevTxn
	Author:			John Criswell
	Create date:	2015-12-12	 
	Description:	Checks to see if any transactions for the customer have already
					been processed for the month.  The match is done on CustomerKey,
					Month.  If both are the same, then it
					is a duplicate and cannot be processed as a Sales Receipt
	Called from:	frmInvIndiv_One		
							
	Change Log:
	-----------------------------------------------------------------------------------
	Change Date		Versions	Changed by		Reason
	2015-12-12		1.0			J Criswell		Created
	2015-12-16		2.0			J Criswell		Changed the logic so that the match is
												done on Document Amount too.  Added a
												parameter for Document Amount.
	
	
======================================================================================= */ 
SET NOCOUNT ON;

SELECT ID
	, DocumentNumber
	, CustomerKey
	, DocumentDate
	, TransactionType
	, DocumentAmt
FROM ARTRANH_local art
WHERE CustomerKey = @CustomerKey
	AND DocumentDate BETWEEN dbo.udf_GetFirstDayOfMonth(@TxnDate) AND dbo.udf_GetLastDayOfMonth(@TxnDate)
	AND DocumentAmt = @DocumentAmt;  -- version 2.0
GO
