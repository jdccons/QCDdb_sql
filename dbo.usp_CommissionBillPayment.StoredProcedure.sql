USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CommissionBillPayment]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CommissionBillPayment]
AS
TRUNCATE TABLE dbo.tblCommissionBillPayment

INSERT INTO tblCommissionBillPayment (
	TxnID, TimeCreated, TimeModified, EditSequence, TxnNumber, 
	PayeeEntityRef_ListID, PayeeEntityRef_FullName, AccountNumber, 
	APAccountRef_ListID, TxnDate, BankAccountRef_ListID, 
	BankAccountRef_FullName, Amount, CurrencyRef_ListID, 
	CurrencyRef_FullName, ExchangeRate, AmountInHomeCurrency, 
	RefNumber, Memo, Address_Addr1, Address_Addr2, Address_City, 
	Address_State, Address_PostalCode, Address_Country, Address_Note, 
	IsToBePrinted, STATUS
	)
SELECT convert(VARCHAR(20), bpc.TxnID) TxnID
	, bpc.TimeCreated
	, bpc.TimeModified
	, convert(VARCHAR(15), bpc.EditSequence) EditSequence
	, bpc.TxnNumber
	, convert(varchar(30), bpc.PayeeEntityRef_ListID) PayeeEntityRef_ListID
	, convert(varchar(50), bpc.PayeeEntityRef_FullName) PayeeEntityRef_FullName
	, convert(varchar(5), v.AccountNumber) AccountNumber
	, convert(varchar(30), bpc.APAccountRef_ListID) APAccountRef_ListID
	, bpc.TxnDate
	, convert(varchar(30), bpc.BankAccountRef_ListID) BankAccountRef_ListID
	, convert(varchar(30), bpc.BankAccountRef_FullName) BankAccountRef_FullName
	, bpc.Amount
	, convert(varchar(30), bpc.CurrencyRef_ListID) CurrencyRef_ListID
	, convert(varchar(30), bpc.CurrencyRef_FullName) CurrencyRef_FullName
	, bpc.ExchangeRate
	, bpc.AmountInHomeCurrency
	, convert(varchar(15), bpc.RefNumber) RefNumber
	, bpc.Memo
	, convert(varchar(50), bpc.Address_Addr1) Address_Addr1
	, convert(varchar(50), bpc.Address_Addr2) Address_Addr2
	, convert(varchar(50), bpc.Address_City) Address_City
	, convert(varchar(2), bpc.Address_State) Address_State
	, convert(varchar(12), bpc.Address_PostalCode) Address_PostalCode
	, convert(varchar(50), bpc.Address_Country) Address_Country
	, bpc.Address_Note
	, bpc.IsToBePrinted
	, bpc.STATUS
FROM QuickBooks.dbo.billpaymentcheck AS bpc
INNER JOIN QuickBooks.dbo.vendor AS v
	ON bpc.PayeeEntityRef_FullName = v.NAME
GO
