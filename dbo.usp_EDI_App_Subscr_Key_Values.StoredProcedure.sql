USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Subscr_Key_Values]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Subscr_Key_Values]

AS
/* =============================================
	Object:			usp_EDI_App_Subscr_Key_Values
	Author:			John Criswell
	Create date:	09/29/2013	 
	Description:	Transfers key values from
					tblSubscr to tblEDI_App_Subscr
					
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION

/*  website electronic enrollment
    update values on import table */

UPDATE
    eas
SET eas.SubID = s.SubID,
    eas.SubCardPrt = s.SubCardPrt,
    eas.SubCardPrtDte = s.SubCardPrtDte,
    eas.SubNotes = s.SubNotes
FROM
    tblEDI_App_Subscr eas
    INNER JOIN tblSubscr s
        ON eas.SubSSN = s.SubSSN

COMMIT TRAN;
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Not currently being used anywhere.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_App_Subscr_Key_Values'
GO
