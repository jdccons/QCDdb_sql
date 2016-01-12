USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspPendingDeletions]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspPendingDeletions]

AS

DECLARE @RecordCount int
SELECT @RecordCount = Count(*) FROM [TRACENTRMTSRV].QCD.dbo.tblSubscriber WHERE MembershipStatus = 'Pending Deletion'

If @RecordCount > 0
--change the Pending Deletion MembershipStatus to Deleted
UPDATE [TRACENTRMTSRV].QCD.dbo.tblSubscriber 
SET MembershipStatus = 'Deleted', Download = 'Yes'
WHERE (MembershipStatus = 'Pending Deletion') AND (DateDeleted = GETDATE()) OR
(MembershipStatus = 'Pending Deletion') AND (DateDeleted < GETDATE())

--send an email
EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'QCD Database Mail',
        @recipients='jlerma@qcdofamerica.com', 
        @body = 'You have subscribers whose pending deleteions have been converted to deleted.  These subscribers need to be downloaded and processed.',
	@body_format = 'TEXT',
        @subject = 'Pending Deletions Converted to Deleted'
GO
