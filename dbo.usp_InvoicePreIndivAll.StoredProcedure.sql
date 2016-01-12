USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePreIndivAll]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InvoicePreIndivAll] 
	(
	@InvoiceDate AS DATETIME
	, @CustomerKey AS NVARCHAR(5)
	, @UserName AS NVARCHAR(20)
	)
AS 
/* ============================================================================================
	Object:			usp_InvoicePreIndivAll
	Author:			John Criswell
	Version:		6
	Create date:	9/8/2014	 
	Description:	Creates bulk invoices for
					individuals.  
					
							
	Change Log:
	-----------------------------------------------------------------------------------------------
	Change Date		Version			Changed by		Reason
	2014-10-15		3				JCriswell		Changed the price on the invoice
													from the rate on tblRate to the actual
													rate on tblSubscr.SubRate
	2015-01-05		4				JCriswell		Fixed an issue with code to insert an
													expiration date.  The TranNo was incorrect.
													It was getting its first digit from GetDate()
													when it should have been getting it from @InvoiceDate
	2015-01-05		5				JCriswell		Corrected an issue on the LineItemType for
													dependent records.
	
===================================================================================================== */
/*  declarations  */
DECLARE @LastOperation VARCHAR(128)
	, @ErrorMessage VARCHAR(8000)
	, @ErrorSeverity INT
	, @ErrorState INT
DECLARE @maxrow AS INTEGER
DECLARE @i AS INTEGER

------------------------------------------------------------------------------
BEGIN TRY
	BEGIN TRANSACTION

	SELECT @LastOperation = 'generate new tran nos'

	--create a temp table with an ID (IDENTITY), CustKey and TranNo
	/*   -----------------------------------------------------   */
	IF OBJECT_ID('tempdb..#TranNo') IS NOT NULL
		DROP TABLE #TranNo

	CREATE TABLE #TranNo (
		ID INTEGER IDENTITY
		, CustKey NVARCHAR(5) NULL
		, TranNo INTEGER NULL
		)

	--dump the monthly individuals in the temp table
	/*   -----------------------------------------------------   */
	INSERT INTO #TranNo (CustKey)
	SELECT ic.CustomerKey
	FROM vw_IndividualCustomer ic
	LEFT OUTER JOIN vw_IndivAgt ia
		ON ic.Spare = ia.SubscrId
	WHERE isnull(ia.LEVEL, 1) = 1
		AND ic.CreditHold = 'N'
		AND ic.Rsrv2 = 'INDVM';

	--cycle through the table assigning TranNos to each record
	/*   -----------------------------------------------------   */
	SELECT @maxrow = @@rowcount
		, @i = 1;

	WHILE @i <= @maxrow
	BEGIN
		UPDATE #TranNo
		SET TranNo = dbo.udf_GetNextTranNo()
		WHERE ID = @i

		UPDATE dbo.ARONE_R9_local
		SET NextTransaction = dbo.udf_GetNextTranNo()
		WHERE R9Key = 'R9'

		SET @i = @i + 1
	END

	SELECT @LastOperation = 
		'insert data into tblInvHdrPreliminary from tblSubscr '

	--append records to temp table - tblInvHdrPreliminary
	/*   -----------------------------------------------------   */
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
	SELECT ISNULL(ic.CustomerKey, '') PltCustKey
		, ic.CustomerName Sub_LUName
		, ic.CustomerAddress1 SubStreet1
		, ISNULL(ic.CustomerAddress2, '') AS SubStreet2
		, ic.CustomerCity SubCity
		, ic.CustomerState SubState
		, ic.CustomerZipCode SubZip
		, '' AS TransNo
		, @InvoiceDate AS InvoiceDte
		, ISNULL(ic.TerritoryKey, '') SubGeoID
		, ia.AGENTid
			, @UserName AS RecUser
		, CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate
		, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS 
		RecTime
		, s.SubRate SubRate
		, ISNULL(s.SUBbankDraftNo, '') SubBankDraftNo
		, s.SubStatus
		, s.SubID AS Spare
		, s.SubSSN AS Spare2
		, 'Individual' Spare3
	FROM tblSubscr s
	INNER JOIN vw_IndividualCustomer ic
		ON s.SubID = ic.Spare
	LEFT OUTER JOIN vw_IndivAgt ia
		ON s.SubID = ia.SubscrID
	INNER JOIN tblRates r
		ON s.RateID = r.RateID
	WHERE ic.CreditHold = 'N'
		AND ic.Rsrv2 = 'INDVM'
		AND isnull(ia.[Level], 1) = 1
	ORDER BY ic.CustomerKey;

	SELECT @LastOperation = 
		'updpate tblInvHdrPreliminary with TranNos '

	--update tblInvHdrPreliminary with the TranNos
	/*   -----------------------------------------------------   */
	UPDATE i
	SET TranNo = [t].TranNo
	FROM tblInvHdrPreliminary i
	INNER JOIN #TranNo [t]
		ON i.CustKey = [t].CustKey;

	SELECT @LastOperation = 'insert data into header staging table '

	--append records from tblInvHdrPreliminary to tblInvHdr        
	/*   -----------------------------------------------------   */
	DELETE
	FROM tblInvHdr;

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
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), Tranno) AS TranNo
		, Invdate
		, Checkno
		, Checkamt
		, Territkey
		, Salespkey
		, Custclass
		, Spare
		, Spare2
		, Spare3
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), Tranno) AS [INVOICE NO]
			, @UserName AS RecUser
		, CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate
		, LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)) AS 
		RecTime
		, Sysdocid
	FROM tblInvHdrPreliminary;

	SELECT @LastOperation = 
		'insert records in tblInvLin for the individual subscriber with his SSN '

	--creates records in tblInvLin for the individual subscriber with his SSN
	/*   -----------------------------------------------------   */
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
		CONVERT(NVARCHAR(9), i.Tranno) AS TranNo
		, s.PltCustKey
		, s.SubSSN
		, s.SUB_LUname AS [Desc]
		, 1 AS QtyOrdered
		, 1 AS QtyShipped
		, '5100' AS Acct
		, '2000' AS Dept
		, s.SubRate
		, s.SubID As Spare
			, s.SubSSN As Spare2
			, 'Individual' As Spare3
	FROM dbo.tblInvHdrPreliminary i
	INNER JOIN tblSubscr s
		ON i.Custkey = s.PltCustKey
	INNER JOIN tblRates r
		ON s.RateID = r.RateID;

	SELECT @LastOperation = 
		'inserts an expiration date record in ARLINH_local for the individual subscriber '

	--creates an expiration date record in ARLINH_local for the individual subscriber				
	/*   -----------------------------------------------------   */
	INSERT INTO tblInvLin (
		[DOCUMENT NO]
		, [CUST KEY]
		, [DESCRIPTION]
		, LineItemTy
			, [SPARE]
			, [SPARE2]
			, [SPARE3]
		)
	SELECT SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), ihp.Tranno) AS TranNo
		, ihp.CustKey
		, (
			'Contract Ending: ' + CONVERT(VARCHAR(10), s.[SubContEnd], 101)
			) AS Descr
		, 2 AS LineType
		, s.SubID As Spare
			, s.SubSSN As Spare2
			, 'Individual' As Spare3
	FROM tblInvHdrPreliminary ihp
	INNER JOIN tblSubscr s
		ON ihp.Custkey = s.PltCustKey;

	SELECT @LastOperation = 
		'inserts dependent records in tblInvLin for the individual subscriber '

	--creates dependent records in tblInvLin for the individual subscriber
	/*   -----------------------------------------------------   */
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
	SELECT CONVERT(NVARCHAR(2), CONVERT(INTEGER, RANK() OVER (
					PARTITION BY s.SubID ORDER BY RTRIM(COALESCE(
								NULLIF(RTRIM(d.[DepLastName]), '') 
								+ ', ', '') + COALESCE(NULLIF(RTRIM(d
										.[DepFirstName]), '') + ' ', 
								'') + COALESCE(d.[DepMiddleName], ''
							))
					)) + 2) AS LineItemType
		, SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10, 1) + 
		CONVERT(NVARCHAR(9), i.Tranno) AS TranNo
		, s.PltCustKey
		, d.DepSSN
		, (d.[DEPlastNAME] + ', ' + d.[DEPfirstNAME]) AS 
		[Desc]
		, 1 AS QtyOrdered
		, 1 AS QtyShipped
		, '5100' AS Acct
		, '2000' AS Dept
			, s.SubID As Spare
			, s.SubSSN As Spare2
			, 'Individual' As Spare3
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Creates invoices for all individual subscribers.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_InvoicePreIndivAll'
GO
