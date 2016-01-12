USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Subscr_CoverID]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Subscr_CoverID]
AS
/* =============================================
	Object:			usp_EDI_App_Subscr_CoverID
	Author:			John Criswell
	Create date:	09/29/2013	 
	Description:	Corrects CoverIDs on
					EDI_App_Subscr based on the
					rules for coverages
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */
UPDATE s
SET s.CoverID = c.CoverId
FROM tblEDI_App_Subscr s
INNER JOIN
(SELECT
    s.SubSSN,    
    gct.TierCnt, 
    dbo.udf_EDI_App_Subscr_CoverID(s.SubSSN, gct.TierCnt) CoverID
FROM
    tblEDI_App_Subscr AS s
    INNER JOIN tblGrp g
        ON s.SubGroupID = g.GroupID
    INNER JOIN vw_Group_Coverage_Tiers gct
		ON g.GroupID = gct.GroupID) c
ON s.SubSSN = c.SubSSN
GO
