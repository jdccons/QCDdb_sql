USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExpireInitialEnrollment]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ExpireInitialEnrollment]
-- =============================================
-- Author:		John Criswell
-- Create date: 3/22/2012
-- Description:	need to run a stored procedure daily to look for groups in initial enrollment;
--              if any initial enrollment groups are out of their initial enrollment period
--              e.g. GetDate() > IEEndDate, then set the EnrollStatus of the group to 'Open'            
-- =============================================

AS

SET NOCOUNT ON

IF EXISTS (SELECT 1 FROM tblGroup
WHERE EnrollStatus = 'Initial'
AND GETDATE() > IEEndDate)

BEGIN

UPDATE tblGroup
SET    EnrollStatus = 'Open'
WHERE  EnrollStatus = 'Initial' AND GETDATE() > IEEndDate

END
GO
