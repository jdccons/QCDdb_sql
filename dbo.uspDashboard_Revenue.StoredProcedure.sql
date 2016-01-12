USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspDashboard_Revenue]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		John Criswell
-- Create date: 7/11/2010
-- Description:	Populates dashboard revenue table
-- =============================================
CREATE PROCEDURE [dbo].[uspDashboard_Revenue] 
	
AS
	TRUNCATE TABLE tblDashBoard_Revenue
		
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN


    -- Insert QCD Only and All American
	INSERT INTO tblDashBoard_Revenue ( TypeofGroup, PlanID, GroupType, [Monthly Premium])
	SELECT 
	CASE GroupType
		WHEN 1 THEN 'QCD Only'
		WHEN 4 THEN 'All American'
		WHEN 9 THEN 'Individual'
		ELSE 'None'
	END AS TypeofGroup
	, s.PlanID
	, s.GroupType
	, r.Rate AS [Monthly Premium] 
	FROM vwSubscribersAll s 
	INNER JOIN tblRates r ON (s.CoverID = r.CoverID) 
	AND (s.PlanID = r.PlanID) AND (s.SubGroupID = r.GroupID) 
	WHERE (((s.GroupType) IN (1,4))) ORDER BY s.GroupType
	

	
	-- Insert annual premium individuals
	INSERT INTO tblDashBoard_Revenue ( TypeofGroup, PlanID, GroupType, [Monthly Premium] )
	SELECT 'Individual' AS TypeofGroup, vwSubscribersAll.PlanID, 9 AS GroupType, 
	([Rate]/12) AS [Monthly Premium]
	FROM vwSubscribersAll INNER JOIN tblRates 
	ON (vwSubscribersAll.CoverID = tblRates.CoverID) 
	AND (vwSubscribersAll.PlanID = tblRates.PlanID) 
	AND (vwSubscribersAll.SubGroupID = tblRates.GroupID)
	WHERE (((vwSubscribersAll.SubGroupID)='INDV1' 
	Or (vwSubscribersAll.SubGroupID)='INDV2' 
	Or (vwSubscribersAll.SubGroupID)='INDV3') 
	AND ((vwSubscribersAll.SubStatus)='INDIV'))
	

	
	-- Insert monthly premium individuals
	INSERT INTO tblDashBoard_Revenue ( TypeofGroup, PlanID, GroupType, [Monthly Premium] )
	SELECT 'Individual' AS TypeofGroup
	, s.PlanID
	, 9 AS GroupType
	, r.Rate AS [Monthly Premium]
	FROM tblSubscr s 
	INNER JOIN tblRates r ON (s.CoverID = r.CoverID) 
	AND (s.PlanID = r.PlanID) 
	AND (s.SubGroupID = r.GroupID)
	WHERE (((s.SubGroupID)='INDVM') 
	AND ((s.SubStatus)='INDIV') AND ((s.SubCancelled)=1))


	END
GO
