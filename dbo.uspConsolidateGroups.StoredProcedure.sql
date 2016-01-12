USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspConsolidateGroups]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspConsolidateGroups]

@ParentGroupID nvarchar(5),
@ChildGroupID nvarchar(5),
@UpdateMsg nvarchar(255)

AS

--change the GroupID in the child group
--to the GroupID in the parent group
UPDATE tblSubscr
SET SubGroupID = @ParentGroupID
WHERE tblSubscr.SubGroupID = @ChildGroupID

--change the groupID on tblRates to match the group change
UPDATE tblRates
SET GroupID = @ParentGroupID
WHERE tblRates.GroupID = @ChildGroupID

--put a message on the group record that was just merged
UPDATE tblGrp
SET Miscellaneous = @UpdateMsg
WHERE tblGrp.GroupID = @ChildGroupID

--insert 'no employee' rates for the child group
INSERT INTO tblRates(GroupID, PlanID, CoverID, Rate)
VALUES (@ChildGroupID, 6, 5, 0)
GO
