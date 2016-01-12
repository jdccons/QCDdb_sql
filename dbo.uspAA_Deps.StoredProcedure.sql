USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspAA_Deps]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAA_Deps]

AS

INSERT INTO tblEDI_App_Dep 
( DepSubID, 
DepSSN, 
DepLastName, 
DepFirstName, 
DepMiddleName, 
DepDOB, 
DepGender, 
DepRelationship )
SELECT EISSN, SUBSTRING(EIMBRID,1,9) AS DepSSN, EINAML, EINAMF, EINAMM,
SUBSTRING(EIDTBR, 1, 2) + '/' + SUBSTRING(EIDTBR, 3,2) + '/' + SUBSTRING(EIDTBR,5,4) AS DTBR, 
EISEX, EIMBRDP
FROM tmpExportAllAmerican
WHERE (((tmpExportAllAmerican.EIRECID)='M') 
AND ((SUBSTRING([EINMPLAN],8,3))='QCD')) 
OR (((tmpExportAllAmerican.EIRECID)='M') AND ((tmpExportAllAmerican.EINMPLAN)='QCDBLU-NGL')) 
OR (((tmpExportAllAmerican.EIRECID)='M') AND ((tmpExportAllAmerican.EINMPLAN)='QCDBLU-MNL'));
GO
