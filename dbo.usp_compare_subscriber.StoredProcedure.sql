USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_compare_subscriber]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_compare_subscriber]
(
@SubID AS NCHAR(8), 
@SSN AS NCHAR(9)
)

AS


SELECT 'SSN Compare' CompareType, 'QCD' AS [Database], SubSSN, SubID, SubCancelled, SubGroupID, SubLastName, 
	SubFirstName, SubMiddleName, PlanID, CoverID, SubStreet1, 
	SubStreet2, SubCity, SubState, SubZip, SubEmail, SubEffDate, 
	PreexistingDate, SubPhoneHome, SubPhoneWork, SubDOB, DepCnt
FROM tblSubscr
WHERE SubSSN = @SSN

UNION ALL

SELECT 'SSN Compare' CompareType, 'Dentist Direct' AS [Database], SSN, SUB_ID, '1' AS SubCancelled, GRP_ID, LAST_NAME, 
	FIRST_NAME, MI, [PLAN], COV, ADDR1, ADDR2, CITY, STATE, ZIP, EMAIL, 
	EFF_DT, PREX_DT, PHONE_HOME, PHONE_WORK, DOB, NO_DEP
FROM tpa_data_exchange
WHERE RCD_TYPE = 'S'
	AND SSN = @SSN

UNION ALL

SELECT 'SubID Compare' CompareType, 'QCD' AS [Database], SubSSN, SubID, SubCancelled, SubGroupID, SubLastName, 
	SubFirstName, SubMiddleName, PlanID, CoverID, SubStreet1, 
	SubStreet2, SubCity, SubState, SubZip, SubEmail, SubEffDate, 
	PreexistingDate, SubPhoneHome, SubPhoneWork, SubDOB, DepCnt
FROM tblSubscr
WHERE SubID = @SubID

UNION ALL

SELECT 'SubID Compare' CompareType, 'Dentist Direct' AS [Database], SSN, SUB_ID, '1' AS SubCancelled, GRP_ID, LAST_NAME, 
	FIRST_NAME, MI, [PLAN], COV, ADDR1, ADDR2, CITY, STATE, ZIP, EMAIL, 
	EFF_DT, PREX_DT, PHONE_HOME, PHONE_WORK, DOB, NO_DEP
FROM tpa_data_exchange
WHERE RCD_TYPE = 'S'
	AND SUB_ID = @SubID
ORDER BY CompareType, [Database]
GO
