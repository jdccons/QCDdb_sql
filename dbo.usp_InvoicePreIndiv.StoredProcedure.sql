USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePreIndiv]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InvoicePreIndiv] 
	(
	@InvoiceDate AS DATETIME
	, @CustomerKey AS NVARCHAR(5)
	, @UserName AS NVARCHAR(20)
	)
AS 
/* ===================================================================================
	Object:			usp_InvoicePreIndiv
	Version:		7
	Author:			John Criswell
	Create date:	9/21/2014	
	Parameters:		InvoiceDate	datetime
					CustomerKey	nvarchar(5)
					DocumentNumber nvarchar(10)
					 
	Description:	This is the pre-process for a single
					individual;  populates tblInvHdr
					and tblInvLin.  The post-process will
					populate ARTRANH_local and ARLIN_local
					
					
					
					
							
	Change Log:
	-------------------------------------------------------------------------------------
	Change Date		Version		Changed by		Reason
	2014-11-11		5			JCriswell		the subscriber billing rate was
												coming from tblRates.  This works
												for group subscribers; individuals
												have actual rates which are stored
												in the SubRate field on tblSubscr;
												changed the rate to SubRate.tblSubscr
	2015-01-12		6			JCriswell		Changed the logic for document number;
												will no longer be passed from the UI
												as a parameter.  Now, will fetch the
												next transaction number from the 
												stored procedure.
	2015-11-20		7			JCriswell		Resolved issue with insert into
												tblHdrPreliminary; it was creating two
												records per customer because of multiple
												agents				
	
========================================================================================= */
/*  declarations  */
DECLARE @LastOperation VARCHAR(128)
	, @ErrorMessage VARCHAR(8000)
	, @ErrorSeverity INT
	, @ErrorState INT
DECLARE @NextTransactionNumber AS NVARCHAR(16)

------------------------------------------------------------------------------
BEGIN TRY
	BEGIN TRANSACTION

	SELECT @LastOperation = 
		'insert data into tblInvHdrPreliminary from tblSubscr '

	-- get the current transaction number
	SET @NextTransactionNumber = (
			SELECT dbo.udf_GetCurrentTranNo()
			) --198412

	-- save the transaction number
	UPDATE dbo.ARONE_R9_local
	SET NextTransaction = dbo.udf_GetNextTranNo()
	WHERE R9Key = 'R9';

	TRUNCATE TABLE dbo.tblInvHdrPreliminary

	INSERT INTO tblInvHdrPreliminary (
		Custkey
		, Custname
		, Custaddr1
		, Custaddr2
		, Custcity
		, Custstate
		, Custzip
		, Tranno
		, Invdate
		, Territkey
		, Salespkey
		, RecUserID
		, RecDate
		, RecTime
		, Checkamt
		, Checkno
		, Custclass
		, Spare
		, Spare2
		, Spare3
		)
	SELECT @CustomerKey AS CustKey
		, s.SUB_LUname AS Custname
		, s.SubStreet1
		, ISNULL(s.SubStreet2, '') AS SubStreet2
		, s.SubCity
		, s.SubState
		, s.SubZip
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), @NextTransactionNumber) AS Tranno
		--@DocumentNumber AS TransNo, 
		, @InvoiceDate AS InvoiceDte
		, ISNULL(s.SubGeoID, '') SubGeoID
		, ia.AgentID
		, @UserName AS RecUser
		, CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate
		, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS 
		RecTime
		, s.SubRate
		, ISNULL(s.SUBbankDraftNo, '') SubBankDraftNo
		, s.SubStatus
		, s.SubID AS Spare
		, s.SubSSN AS Spare2
		, 'Individual' AS Spare3
	FROM tblSubscr s
	INNER JOIN tblIndivAgt ia
		ON s.SubID = ia.SubscrID
	WHERE s.PltCustKey = @CustomerKey
		AND ia.AgentId = (
			SELECT TOP (1) AgentID
			FROM tblIndivAgt
			WHERE tblIndivAgt.PltCustKey = @CustomerKey
			ORDER BY AgentRate DESC
			);

	SELECT @LastOperation = 'insert data into header staging table '

	DELETE
	FROM tblInvHdr
	WHERE [CUST KEY] = @CustomerKey;

	--append records from tblInvHdrPreliminary to tblInvHdr        
	INSERT INTO tblInvHdr (
		[CUST KEY]
		, [CUST NAME]
		, [ADDRESS 1]
		, [ADDRESS 2]
		, CITY
		, [STATE]
		, [ZIP CODE]
		, ATTENTION
		, [TRANS NO]
		, [INV DATE]
		, [CHECK NO]
		, [CHECK AMTR]
		, [TERRITORY KEY]
		, [SALESP    KEY]
		, [CUST CLASS]
		, SPARE
		, SPARE2
		, SPARE3
		, [INVOICE NO]
		, RecUserID
		, RecDate
		, RecTime
		, SYSDOCID
		)
	SELECT Custkey
		, Custname
		, Custaddr1
		, Custaddr2
		, Custcity
		, Custstate
		, Custzip
		, CustAttn
		, Tranno
		, Invdate
		, Checkno
		, Checkamt
		, Territkey
		, Salespkey
		, Custclass
		, Spare
		, Spare2
		, Spare3
		, Tranno AS [INVOICE NO]
		, @UserName AS RecUser
		, CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate
		, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS 
		RecTime
		, Sysdocid
	FROM tblInvHdrPreliminary;

	SELECT @LastOperation = 
		'insert subscriber data into line item staging table ';

	--creates records in tblInvLin for the individual subscriber and his SSN
	INSERT INTO tblInvLin (
		LineItemTy
		, [DOCUMENT NO]
		, [CUST KEY]
		, [ITEM KEY]
		, [DESCRIPTION]
		, [QTY ORDERED]
		, [QTY SHIPPED]
		, [REV ACCT]
		, [REV SUB]
		, [UNIT PRICE]
		, [SPARE]
		, [SPARE2]
		, [SPARE3]
		)
	SELECT '1' AS LineType
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), @NextTransactionNumber) AS 
		[DOCUMENT NO]
		,
		--@DocumentNumber AS TranNo,
		s.PltCustKey
		, s.SubSSN
		, s.SUB_LUname AS [Desc]
		, 1 AS QtyOrdered
		, 1 AS QtyShipped
		, '5100' AS Acct
		, '2000' AS Dept
		, i.Checkamt
		, s.SubID AS Spare
		, s.SubSSN AS Spare2
		, 'Individual' AS Spare3
	FROM dbo.tblInvHdrPreliminary i
	INNER JOIN tblSubscr s
		ON i.Custkey = s.PltCustKey;

	SELECT @LastOperation = 
		'create expiration dates in line item detail '

	--creates an expiration date record in ARLIN for the individual subscriber				
	INSERT INTO tblInvLin (
		[CUST KEY]
		, [DOCUMENT NO]
		, [DESCRIPTION]
		, LineItemTy
		, [SPARE]
		, [SPARE2]
		, [SPARE3]
		)
	SELECT @CustomerKey AS PltCustKey
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), @NextTransactionNumber) AS 
		[DOCUMENT NO]
		,
		--@DocumentNumber AS TransNo,
		(
			'Contract Ending: ' + CONVERT(VARCHAR(10), s.
				[SUBcontEND], 101)
			) AS Descr
		, 2 AS LineType
		, s.SubID AS Spare
		, s.SubSSN AS Spare2
		, 'Individual' AS Spare3
	FROM tblInvHdrPreliminary ihp
	INNER JOIN tblSubscr s
		ON ihp.Custkey = s.PltCustKey;

	SELECT @LastOperation = 'insert dependents in line item detail '

	--creates dependent records in tblInvLin for the individual subscriber
	INSERT INTO tblInvLin (
		LineItemTy
		, [DOCUMENT NO]
		, [CUST KEY]
		, [ITEM KEY]
		, [DESCRIPTION]
		, [QTY ORDERED]
		, [QTY SHIPPED]
		, [REV ACCT]
		, [REV SUB]
		, [SPARE]
		, [SPARE2]
		, [SPARE3]
		)
	SELECT 3 AS LineType
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), @NextTransactionNumber) AS 
		[DOCUMENT NO]
		,
		--@DocumentNumber AS TransNo,
		s.PltCustKey
		, d.DepSSN
		, (d.[DEPlastNAME] + ', ' + d.[DEPfirstNAME]) AS 
		[Desc]
		, 1 AS QtyOrdered
		, 1 AS QtyShipped
		, '5100' AS Acct
		, '2000' AS Dept
		, s.SubID AS Spare
		, s.SubSSN AS Spare2
		, 'Individual' AS Spare3
	FROM dbo.tblInvHdrPreliminary i
	INNER JOIN tblSubscr s
		ON i.CustKey = s.PltCustKey
	INNER JOIN dbo.tblDependent d
		ON s.SubSSN = d.DepSubID;

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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Creates an invoice for a single individual.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_InvoicePreIndiv'
GO
