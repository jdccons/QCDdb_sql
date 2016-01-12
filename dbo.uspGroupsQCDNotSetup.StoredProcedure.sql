USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspGroupsQCDNotSetup]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGroupsQCDNotSetup]

AS

SELECT AA_GroupIDs.GroupID
FROM AA_GroupIDs 
LEFT OUTER JOIN tblGrp ON AA_GroupIDs.GroupID = tblGrp.GROUPid
WHERE (tblGrp.GROUPid IS NULL)
GO
