USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_DelEDISubscr]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DelEDISubscr]
/* =============================================
	Object:			usp_DelEDISubscr			
	Author:			John Criswell
	Create date:    2013-12-26		 
	Description:	For EDI subscribers, they are
					all deleted and replaced with
					with the group's entire census
					
	Parameters;		@GroupID as varchar(9)				
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2013-12-27      John Criswell   added delete subs 
                                    where SubSSNs match
	
	
============================================= */
@GroupID varchar(9)
AS

SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE	@LastOperation varchar(128), 
		@ErrorMessage varchar(8000), 
		@ErrorSeverity int, 
		@ErrorState int
------------------------------------------------------------------------------
BEGIN TRY
BEGIN TRANSACTION

/*   delete all existing subscribers in a group  */
SELECT	@LastOperation = 'delete existing group subscribers'
IF EXISTS (SELECT
    1
FROM
    tblSubscr
WHERE
    (SubGroupID = @GroupID))
    
DELETE FROM tblSubscr WHERE SubGroupID = @GroupID

/*  delete all existing subscribers where the SSNs match
    this was included in case someone moves from one group
    to another
*/
SELECT	@LastOperation = 'delete existing subscribers where the SSNs match'
IF EXISTS (select edi.subssn from tblEDI_App_Subscr edi
				inner join tblSubscr s
					on edi.SubSSN = s.SubSSN)
DELETE s
FROM tblSubscr s
	INNER JOIN tblEDI_App_Subscr edi
		ON s.SubSSN = edi.SubSSN

COMMIT TRANSACTION
END TRY

BEGIN CATCH 
  IF @@TRANCOUNT > 0
     ROLLBACK

  SELECT	@ErrorMessage = ERROR_MESSAGE() + ' Last Operation: ' + @LastOperation, 
			@ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
  RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'For EDI subscribers, they are all deleted and replaced with with the groups entire census.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_DelEDISubscr'
GO
