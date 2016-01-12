USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CallProcedureLog]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CallProcedureLog]
 @ObjectID       INT,
 @DatabaseID     INT = NULL,
 @AdditionalInfo NVARCHAR(MAX) = NULL
AS
/* =============================================
	Object:			usp_CallProcedureLog	
	Author:			John Criswell
	Create date:	2015-02-23	 
	Description:	Logs stored procedure errors to
					ProcedureLog table
					
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2015-02-23		JCriswell		Created
	
	
============================================= */
BEGIN
 SET NOCOUNT ON;

 DECLARE 
  @ProcedureName NVARCHAR(400);

 SELECT
  @DatabaseID = COALESCE(@DatabaseID, DB_ID()),
  @ProcedureName = COALESCE
  (
   QUOTENAME(DB_NAME(@DatabaseID)) + '.'
   + QUOTENAME(OBJECT_SCHEMA_NAME(@ObjectID, @DatabaseID)) 
   + '.' + QUOTENAME(OBJECT_NAME(@ObjectID, @DatabaseID)),
   ERROR_PROCEDURE()
  );

 INSERT ProcedureLog
 (
  DatabaseID,
  ObjectID,
  ProcedureName,
  ErrorLine,
  ErrorMessage,
  AdditionalInfo
 )
 SELECT
  @DatabaseID,
  @ObjectID,
  @ProcedureName,
  ERROR_LINE(),
  ERROR_MESSAGE(),
  @AdditionalInfo;
END
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Logs stored procedure errors to ProcedureLog table' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_CallProcedureLog'
GO
