USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Subscr_CoverDesc]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Subscr_CoverDesc]
AS 
    UPDATE
        eas
    SET eas.Coverage = c.CoverDescr, eas.CoverDesc = c.CoverDescr
    FROM
        tblEDI_App_Subscr AS eas
        INNER JOIN tblRates AS r
            ON eas.CoverID = r.CoverID
               AND eas.PlanId = r.PlanId
               AND eas.SubGroupID = r.GroupID
        INNER JOIN tblCoverage AS c
            ON r.CoverID = c.CoverID
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Not currently being used anywhere.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_App_Subscr_CoverDesc'
GO
