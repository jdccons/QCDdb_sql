USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspPopTempTables]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspPopTempTables    Script Date: 3/26/2009 6:06:51 AM ******/


/****** Object:  Stored Procedure dbo.uspPopTempTables    Script Date: 11/3/2006 11:55:40 AM ******/
/* stored procedure changed to add a parameter @PlanID -- 11/01/207 */
CREATE PROCEDURE [dbo].[uspPopTempTables]

@GroupID As nvarchar(5)


AS

DELETE FROM tblSubscriber_temp

INSERT INTO tblSubscriber_temp ( SSN, SubscriberID, EIMBRID, GroupID, PlanID, CoverID, LastName, FirstName, 
MiddleInitial, Street1, Street2, City, State, Zip, PhoneWork, PhoneHome, DOB, DepCnt, Gender, Age, 
MaritalStatus, EffectiveDate, PreexistingDate, CardPrinted, CardPrintedDate, MembershipStatus, DateCreated, DateChanged, DateDeleted )
SELECT tblSubscr.SubSSN, tblSubscr.SubID, tblSubscr.EIMBRID, tblSubscr.SubGroupID, tblSubscr.PlanID, tblSubscr.CoverID, 
tblSubscr.SubLastName, tblSubscr.SubFirstName, tblSubscr.SubMiddleName, tblSubscr.SubStreet1, tblSubscr.SubStreet2, 
tblSubscr.SubCity, tblSubscr.SubState, tblSubscr.SubZip, tblSubscr.SubPhoneWork, tblSubscr.SubPhoneHome, tblSubscr.SUBdob, 
tblSubscr.DepCnt, tblSubscr.SubGender, tblSubscr.SubAge, tblSubscr.SubMaritalStatus, tblSubscr.SubEffDate, 
tblSubscr.PreexistingDate, tblSubscr.SubCardPrt, tblSubscr.SubCardPrtDte, 'Current', tblSubscr.DateCreated, 
tblSubscr.DateUpdated, tblSubscr.DateDeleted
FROM tblSubscr
WHERE (((tblSubscr.SubGroupID)= @GroupID ))

DELETE FROM tblDependent_temp

INSERT INTO tblDependent_temp ( DepSSN, EIMBRID, SubSSN, FirstName, MiddleInitial, LastName, DOB, Age, Relationship, Gender )
SELECT tblDependent.DepSSN, tblDependent.EIMBRID, tblDependent.DepSubID, tblDependent.DepFirstName, tblDependent.DepMiddleName, 
tblDependent.DepLastName, tblDependent.DepDOB, tblDependent.DepAge, tblDependent.DepRelationship, tblDependent.DepGender
FROM tblSubscr INNER JOIN tblDependent ON tblSubscr.SubSSN = tblDependent.DepSubID
WHERE (((tblSubscr.SubGroupID)= @GroupID ));
GO
