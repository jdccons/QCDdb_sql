USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspDepImport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspDepImport    Script Date: 4/4/2009 10:05:48 AM ******/

/****** Object:  Stored Procedure dbo.uspDepImport    Script Date: 3/18/2009 7:59:59 PM ******/

CREATE PROCEDURE [dbo].[uspDepImport]

AS

INSERT INTO tblDependent ( DEPssn
, DEPsubID
, EIMBRID
, DEPfirstNAME
, DEPmiddleNAME
, DEPlastNAME
, DEPdob
, DEPage
, DEPgender
, DEPrelationship
, DepEffDate
, PreexistingDate
 )
SELECT tblEDI_App_Dep.DEPssn
, tblEDI_App_Dep.DEPsubID
, tblEDI_App_Dep.EIMBRID
, UPPER([DEPfirstNAME]) AS FirstName
, UPPER([DEPmiddleNAME]) AS MI
, UPPER([DEPlastNAME]) AS LastName
, tblEDI_App_Dep.DEPdob
, tblEDI_App_Dep.DEPage
, (CASE 
	WHEN DepGender Is Null
	THEN 'O'
	ELSE DepGender
	END) As Gender
, tblEDI_App_Dep.DEPrelationship
, tblEDI_App_Dep.DepEffDate
, tblEDI_App_Dep.PreexistingDate
FROM tblEDI_App_Subscr 
RIGHT JOIN tblEDI_App_Dep ON tblEDI_App_Subscr.SUBssn = tblEDI_App_Dep.DEPsubID
GO
