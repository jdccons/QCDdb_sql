USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSubID]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetSubID]
	@NextSubID NVARCHAR(8) OUTPUT
AS
SET NOCOUNT ON
BEGIN

	SELECT @NextSubID = CAST(CAST(LastSubID AS int) + 1 AS VARCHAR(8)) FROM dbo.SubIDControl
	
	UPDATE dbo.SubIDControl
	SET LastSubID = @NextSubID
	
END
GO
