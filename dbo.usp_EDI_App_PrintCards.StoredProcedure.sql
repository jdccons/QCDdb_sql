USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_PrintCards]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
	Object:			usp_EDI_App_PrintCards		
	Author:			John Criswell
	Create date:	2013-10-16	 
	Description:	Adds records to a temp table
					in order to print membership
					cards from a website CRUD
					download
					
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */
CREATE PROCEDURE [dbo].[usp_EDI_App_PrintCards]
@GroupId AS VARCHAR(5), @GroupType AS INT
AS

TRUNCATE TABLE dbo.tmpEDI_Rpt

IF EXISTS(SELECT
            1
        FROM
            tblSubscr AS s
            INNER JOIN tblEDI_App_Subscr AS eas
                ON s.SubSSN = eas.SubSSN
            INNER JOIN tblGrp AS g
                ON s.SubGroupID = g.GroupID
        WHERE
            ( s.SubGroupID = @GroupID )
            AND ( g.GroupType = @GroupType ))
BEGIN            
INSERT  INTO tmpEDI_Rpt
        ( GroupID, SubSSN, SubFirstName, SubLastName, SubStreet, SubCity,
          SubState, SubZIP, GRMailCard )
        SELECT
            s.SubGroupID, s.SubSSN, s.SubFirstName, s.SubLastName,
            s.SubStreet1 + ' ' + s.SubStreet2 AS Street, s.SubCity, s.SubState,
            s.SubZip, g.GRMailCard
        FROM
            tblSubscr AS s
            INNER JOIN tblEDI_App_Subscr AS eas
                ON s.SubSSN = eas.SubSSN
            INNER JOIN tblGrp AS g
                ON s.SubGroupID = g.GroupID
        WHERE
            ( s.SubGroupID = @GroupID )
            AND ( g.GroupType = @GroupType )
        RETURN 1
END
ELSE	
	RETURN	0
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Adds records to a temp table in order to print membership cards from a website CRUD download.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_App_PrintCards'
GO
