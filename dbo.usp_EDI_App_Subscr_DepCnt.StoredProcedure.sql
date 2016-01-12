USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Subscr_DepCnt]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Subscr_DepCnt]
AS 
/* =============================================
	Object:			usp_EDI_App_Subscr_DepCnt
	Author:			John Criswell
	Create date:	09/29/2013	 
	Description:	Corrects the dependent counts
					on tblEDI_App_Subscr by 
					counting the depdenents on the
					dependent table.  
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */
UPDATE
    s
SET s.DepCnt = depcnt.DepCnt
FROM
    tblEDI_App_Subscr s
    INNER JOIN ( SELECT
                    SubSSN, dbo.udf_EDI_App_Subscr_DepCnt(SubSSN) DepCnt
                 FROM
                    tblEDI_App_Subscr ) depcnt
        ON s.SubSSN = depcnt.SubSSN
GO
