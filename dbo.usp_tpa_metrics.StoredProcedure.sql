USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_metrics]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_tpa_metrics]
@ReturnParm VARCHAR(255) OUTPUT 
AS
/* ====================================================================================
	Object:			usp_tpa_metrics
	Author:			John Criswell
	Create date:	2015-10-29		 
	Description:	Gathers statistics on the tpa file import
	Called from:	fdlgAASync		
							
	Change Log:
	-----------------------------------------------------------------------------------
	Change Date		Versions	Changed by		Reason
	2015-10-29		1.0			J Criswell		Created
	
	
=======================================================================================*/
/*  ------------------  declarations  --------------------  */ 
SET NOCOUNT ON;
SET XACT_ABORT ON;
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT

	
/*  ------------------------------------------------------  */
BEGIN TRY
   BEGIN TRANSACTION


SELECT  @LastOperation = 'create temp table'
IF OBJECT_ID('tempdb..#metrics', 'U') IS NOT NULL
	DROP TABLE #metrics;

CREATE TABLE #metrics (
	[ID] [INT] IDENTITY(1, 1) NOT NULL
	, [rcd_type] CHAR(1)
	, [MetKey] VARCHAR(50) NULL
	, [Metric] VARCHAR(50) NULL
	, [MetCnt] [INT] NULL
	)
	
	/*  subscribers  */
	SELECT  @LastOperation = 'gather statistics for subscribers'
	-- beginning balance for subscribers
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 's' AS [rcd_type]
		, 'sbb' AS [MetKey]
		, 'qcd sub beg bal' Metric
		, cast(count(s.SubSSN) AS INTEGER) MetCnt
	FROM tblSubscr s
	INNER JOIN tblGrp g
		ON s.SubGroupID = g.GroupID
	WHERE g.GroupType = 4
		AND g.GRCancelled = 0
		AND s.SubCancelled = 1

	UNION
	
	-- plus adds -- mis-match between tpa and QCD
	SELECT 's' AS [rcd_type]
		, 'snw' AS [MetKey]
		, 'tpa new subs' Metric
		, cast(count(r.SSN) AS INTEGER) MetCnt
	FROM (
		SELECT s.SubSSN
		FROM tblSubscr s
		INNER JOIN tblGrp g
			ON s.SubGroupID = g.GroupID
		WHERE g.GroupType IN (4) -- All American groups only
			AND g.GRCancelled = 0 -- active groups only	
			AND s.SubCancelled = 1 -- active subscribers only
		) s
	RIGHT OUTER JOIN (
		SELECT r.SSN
		FROM tpa_data_exchange_sub r
		INNER JOIN tblGrp g
			ON r.GRP_ID = g.GroupID
		WHERE r.RCD_TYPE = 'S' -- subscribers only
			AND r.GRP_TYPE = 4 -- All American groups only
			AND g.GRCancelled = 0 -- active groups only
			AND (r.MBR_ST IN (1, 2))
			-- only add and change transactions from tpa
		) r
		ON s.SubSSN = r.SSN
	WHERE (s.SubSSN IS NULL)

	UNION

	-- less tpa mis-match terminations
	SELECT 's' AS [rcd_type]
		, 'stm' AS [MetKey]
		, 'tpa mis-match sub terms' Metric
		, (cast(count(s.SubSSN) AS INTEGER) * - 1) MetCnt
	FROM tblSubscr AS s  -- qcd subs
	INNER JOIN tblGrp g
		ON s.SubGroupID = g.GroupID
	LEFT OUTER JOIN (
					-- tpa subs
					SELECT r.SSN
					FROM tpa_data_exchange_sub r
					INNER JOIN tblGrp g
						ON r.GRP_ID = g.GroupID
					WHERE r.RCD_TYPE = 'S' -- subscribers only
						AND r.GRP_TYPE = 4 -- All American groups only
						AND g.GRCancelled = 0 -- active groups only		
					) r
	ON s.SubSSN = r.SSN
	WHERE (r.SSN IS NULL)
		AND (g.GroupType = 4) -- All American groups only
		AND (g.GRCancelled = 0) -- active groups only
		AND (s.SubCancelled = 1)

	UNION

	-- less terminations tpa identified
	SELECT 's' AS [rcd_type]
		, 'st3' AS [MetKey]
		, 'code 3 sub terms' AS Metric
		, (cast(count(s.SubSSN) AS INTEGER) * - 1) AS MetCnt
	FROM tpa_data_exchange_sub r
	INNER JOIN tblSubscr s
		ON r.SSN = s.SubSSN
	WHERE MBR_ST = 3
		AND GRP_TYPE = 4
		AND s.SubCancelled = 1

	-- calculate subscriber ending balance
	SELECT  @LastOperation = 'calculate subscriber ending balance'
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 's' AS [rcd_type]
		, 'scb' AS [MetKey]
		, 'calc sub end bal' AS Metric
		, SUM(MetCnt) MetCnt
	FROM #metrics

	-- tpa subscriber ending balance
	SELECT  @LastOperation = 'tpa subscriber ending balance'
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 's' AS [rcd_type]
		, 'seb' AS [MetKey]
		, 'tpa sub end bal' AS Metric
		, cast(COUNT(SSN) AS INTEGER) MetCnt
	FROM tpa_data_exchange_sub
	WHERE GRP_TYPE = 4
		AND MBR_ST IN (1, 2)

	/*   ***  depdendents  ***   */
	SELECT  @LastOperation = 'gather statistics for dependents'
	-- qcd beginning bal
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 'd' AS [rcd_type]
		, 'dbb' AS [MetKey]
		, 'qcd dep beg bal' Metric
		, CAST(COUNT(d.SubSSN) AS INTEGER) MetCnt
	FROM vw_GrpDep d
	WHERE d.GrpCancel = 'Active'
		AND d.GrpType = 'All American'
		AND d.SubCancel = 'Active'
		AND d.DepCancel = 'Active'


	UNION

	-- plus adds (mis-match between tpa and QCD)
	SELECT 'd' AS [rcd_type]
		, 'dnw' AS [MetKey]
		, 'tpa new deps' Metric
		, CAST(COUNT(r.MBR_ID) AS INTEGER) AS MetCnt
	FROM tpa_data_exchange_dep r -- tpa deps
	INNER JOIN tblGrp g
		ON r.GRP_ID = g.GroupID
	LEFT OUTER JOIN
		-- qcd deps
		(
		SELECT d.EIMBRID
		FROM vw_GrpDep d
		WHERE d.GrpCancel = 'Active'
			AND d.GrpType = 'All American'
			AND d.SubCancel = 'Active'
			AND d.DepCancel = 'Active'
		) m
		ON ISNULL(r.MBR_ID, '') = ISNULL(m.EIMBRID, '')
	WHERE m.EIMBRID IS NULL
	AND r.MBR_ST IN (1,2)

	UNION

	---- less tpa mis-match dep terminations
	SELECT 'd' AS [rcd_type]
		, 'dtm' AS [MetKey]
		, 'tpa mis-match dep terms' Metric
		, (CAST(COUNT(qcd.MBR_ID) AS INTEGER) * - 1) AS MetCnt
	FROM (
		-- qcd deps
		SELECT 
			d.EIMBRID AS MBR_ID			
		FROM vw_GrpDep AS d
		WHERE d.GrpCancel = 'Active'
			AND d.SubCancel = 'Active'
			AND d.GrpType = 'All American'
			AND d.DepCancel = 'Active'
		) qcd
	LEFT OUTER JOIN (
		-- tpa deps
		SELECT MBR_ID
		FROM tpa_data_exchange_dep
		WHERE GRP_TYPE = 4
			AND (MBR_ST IN (1, 2))
		) dca
		ON qcd.MBR_ID = dca.MBR_ID
	WHERE dca.MBR_ID IS NULL


	UNION

	-- tpa identified terms
	SELECT 'd' AS [rcd_type]
		, 'dt3' AS [MetKey]
		, 'tpa code 3 dep terms' Metric
		, (CAST(COUNT(SSN) AS INTEGER) * - 1) AS MetCnt
	FROM tpa_data_exchange_dep r
		INNER JOIN tblDependent d
			ON r.MBR_ID = d.EIMBRID
	WHERE r.RCD_TYPE = 'D'
		AND r.MBR_ST = 3
		AND r.GRP_TYPE = 4
		AND ISNULL(d.DepCancelled,1) = 1

	-- calculate dependent ending balance
	SELECT  @LastOperation = 'calculate dependent ending balance'
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 'd' AS [rcd_type]
		, 'dcb' AS [MetKey]
		, 'calc dep end bal' AS Metric
		, SUM(MetCnt) MetCnt
	FROM #metrics
	WHERE [rcd_type] = 'd'

	-- tpa dependent ending balance
	SELECT  @LastOperation = 'tpa dependent ending balance'
	INSERT INTO #metrics (
		[rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
		)
	SELECT 'd' AS [rcd_type]
		, 'deb' AS [MetKey]
		, 'tpa dep end bal' AS Metric
		, CAST(COUNT(SSN) AS INTEGER) MetCnt
	FROM tpa_data_exchange_dep
	WHERE GRP_TYPE = 4
		AND MBR_ST IN (1, 2)	
	
	-- final insert into report table
	SELECT  @LastOperation = 'final insert into report table'
	TRUNCATE TABLE tmpEDI_Rpt;

	INSERT INTO tmpEDI_Rpt (
		ID
		, Stat
		, SubFirstName
		, SubLastName
		, Cnt
		)
	SELECT [ID]
		, [rcd_type]
		, [MetKey]
		, Metric
		, MetCnt
	FROM #metrics;

COMMIT TRANSACTION
	SET @ReturnParm = 'Procedure succeeded'
END TRY

BEGIN CATCH 
	IF @@TRANCOUNT > 0 
		ROLLBACK

	SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
			+ @LastOperation ,
			@ErrorSeverity = ERROR_SEVERITY() ,
			@ErrorState = ERROR_STATE()
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    EXEC usp_CallProcedureLog 
	@ObjectID       = @@PROCID,
	@AdditionalInfo = @LastOperation;
    SET @ReturnParm = 'Procedure Failed'
END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Creates statistical data from tpa import file...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_tpa_metrics'
GO
