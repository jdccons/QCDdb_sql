USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CleanUpSubscr]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  clean up tblSubscr  */
CREATE PROCEDURE [dbo].[usp_CleanUpSubscr]
AS


/* change values to upper case  */
UPDATE tblSubscr
SET SubFirstName = UPPER(SubFirstName)
	, SubLastName = UPPER(SubLastName)
	, SubMiddleName = UPPER(SubMiddleName)
	, SubStreet1 = UPPER(SubStreet1)
	, SubStreet2 = UPPER(SubStreet2)
	, SubCity = UPPER(SubCity)
	, PltCustKey = UPPER(PltCustKey);

/* create values for begin and end contract dates for group subscribers  */
UPDATE tblSubscr
SET SubContBeg = CAST(g.GRContBeg AS DATE)
	, SubContEnd = CAST(g.GRContEnd AS DATE)
FROM tblSubscr s
INNER JOIN tblGrp g
	ON s.SubGroupID = g.GroupID
WHERE g.GroupType IN (1, 4);



/*  create EIMBRIDs  */
UPDATE tblSubscr
SET EIMBRID = SubSSN + '00';
GO
