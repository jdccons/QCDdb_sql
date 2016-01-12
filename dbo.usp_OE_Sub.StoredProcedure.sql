USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_Sub]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_OE_Sub] (@GroupType AS INTEGER, @TransactionType as nvarchar(20)
	)
AS
INSERT INTO tblEDI_App_Subscr_delete (
	SubSSN
	, EIMBRID
	, SubID
	, SubStatus
	, SubGroupID
	, PlanID
	, CoverID
	, SubLastName
	, SubFirstName
	, SubMiddleName
	, SUB_LUname
	, SubStreet1
	, SubStreet2
	, SubCity
	, SubState
	, SubZip
	, SUBdob
	, DepCnt
	, SubGender
	, SubAge
	, SubEffDate
	, SubMaritalStatus
	, SubCardPrt
	, SubCardPrtDte
	, TransactionType
	, DateCreated
	, DateUpdated
	, DateDeleted
	, wSubID
	)
SELECT SSN
	, EIMBRID
	, SubscriberID
	, 'GRSUB' AS [STATUS]
	, st.GroupID
	, PlanID
	, CoverID
	, LastName
	, FirstName
	, MiddleInitial
	, LastName + ', ' + FirstName + ' ' + SUBSTRING(MiddleInitial, 1, 1) AS LU_Name
	, Street1
	, Street2
	, City
	, [STATE]
	, Zip
	, DOB
	, DepCnt
	, Gender
	, Age
	, EffectiveDate
	, MaritalStatus
	, CardPrinted
	, CardPrintedDate
	, MembershipStatus
	, st.DateCreated
	, st.DateChanged
	, st.DateDeleted
	, wSubID
FROM tblSubscriber_temp AS st
INNER JOIN tblGrp g
	ON st.GroupID = g.GroupID
WHERE (g.GroupType = (@GroupType))
	AND (MembershipStatus = @TransactionType);
GO
