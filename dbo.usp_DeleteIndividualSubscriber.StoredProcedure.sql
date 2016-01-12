USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteIndividualSubscriber]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteIndividualSubscriber] 
			(
			@SubID AS nchar(8),
			@UserName nvarchar(20)
			)

AS
/* ==================================================================================
	Object:			usp_DeleteIndividualSubscriber
	Author:			John Criswell
	Create date:	2015-02-23	 
	Description:	Deletes a single individual subscriber
					from tblSubscr
					
	Change Log:
	--------------------------------------------
	Change Date			Version		Changed by		Reason
	2015-02-23			1.0			J Criswell		Created
	2015-12-30			2.0			J Criswell		Changed logic to update Rsrv1 and
													Rsrv2 to 3 and DELETED instead of
													deleting the record
	
	
====================================================================================== */
IF EXISTS (
			SELECT 1
			FROM tblSubscr
			WHERE (((tblSubscr.SubID) = @SubID))
		   )
BEGIN
	UPDATE tblSubscr
	SET SubCancelled = 3
		, TransactionType = 'DELETED'
		, UserName = @UserName
		, DateDeleted = GETDATE()
		, User01 = 'usp_DeleteIndividualSubscriber'
		, User02 = 'frmIndivSubscr'
		, User04 = GETDATE()
	WHERE (((tblSubscr.SubID) = @SubID))

	RETURN 1
END
ELSE
	RETURN 0
GO
