USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteARCust]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteARCust] (
	@SubID AS NVARCHAR(8)
	, @UserName AS VARCHAR(20)
	)
AS
/* ========================================================================
	Object:			usp_DeleteARCust
	Author:			John Criswell
	Create date:	2015-02-23	 
	Description:	Deletes a single customer from
					ARCUST_local
	Change Log:
	--------------------------------------------
	Change Date		Version		Changed by		Reason
	2015-02-23		1.0			JCriswell		Created
	2015-12-30		2.0			J Criswell		Changed logic to set
												Rsrv1 to DELETED instead
												of deleting the record
	
=========================================================================== */
IF EXISTS (
			SELECT 1
			FROM ARCUST_local
			WHERE ((ARCUST_local.Spare) = @SubID )
		   )
BEGIN
	UPDATE ARCUST_local
	SET Rsrv1 = 3
		, Rsrv2 = 'DELETED'
		, RecUserID = @UserName
		, RecDate = CONVERT(VARCHAR(10), GETDATE(), 101)
		, RecTime = LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7	))
	WHERE (Spare = @SubID)

	RETURN 1
END
ELSE
	RETURN 0
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Deletes a single customer from ARCUST_local' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_DeleteARCust'
GO
