USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspPrintAAreport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.uspPrintAAreport    Script Date: 3/18/2009 8:23:47 PM ******/
CREATE PROCEDURE [dbo].[uspPrintAAreport]
AS
/* ====================================================================================
	Object:			uspPrintAAreport
	Author:			T Cook
	Create date:	2007-01-01	 
	Description:	Takes data from All American subscribers and populates a report
					table (tmpEDI_rpt)
	Called from:	fdlgAASync.cmdReport
	Report name:	rptAA_NewSubscribers		
							
	Change Log:
	-----------------------------------------------------------------------------------
	Change Date		Versions	Changed by		Reason
	2007-01-01		1.0			T Cook			Created
	2015-10-20		2.0			J Criswell		Update for new tpa and tables.
	2015-11-23		3.0			J Criswell		Changed name of view - from AA_DepCntDiffs to vw_tpa_dep_cnt_diffs
	
======================================================================================= */ 
	-- clear out report temp table
	DELETE FROM tmpEDI_rpt

	-- new All American subscribers
	INSERT INTO tmpEDI_Rpt (
		SUBssn
		, EIMBRID
		, SUBfirstNAME
		, SUBlastNAME
		, SUBStreet
		, SUBcity
		, SUBstate
		, SUBzip
		, Stat
		, GroupID
		)
	SELECT r.SSN
		, (r.SSN + '00') AS EIMBRID
		, r.FIRST_NAME
		, r.LAST_NAME
		, substring(rtrim(isnull(r.ADDR1,'')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
		, r.CITY
		, r.[STATE]
		, r.ZIP
		, 'NEW' AS Stat
		, r.GRP_ID
	FROM (
		/*  All American Subscribers from QCD database   */
		SELECT s.SubSSN
			, s.SubID
			, s.SubLastName
			, s.SubFirstName
			, s.SubMiddleName
			, s.SubGroupID
			, s.SubCancelled
			, g.GRCancelled
			, g.GroupType
		FROM tblSubscr s
		INNER JOIN tblGrp g
			ON s.SubGroupID = g.GroupID
		WHERE g.GroupType IN (4) -- All American groups only
			AND g.GRCancelled = 0 -- active groups only	
			AND s.SubCancelled = 1 -- active subscribers only
		) s
	RIGHT OUTER JOIN (
		/*  Direct Care Administrators All American Subscribers  */
		SELECT r.SSN
			, r.SUB_ID
			, ISNULL(r.LAST_NAME, '') LAST_NAME
			, ISNULL(r.FIRST_NAME, '') FIRST_NAME
			, r.MI
			, r.GRP_ID
			, r.DOB
			, r.[PLAN]
			, COV
			, EFF_DT
			, PREX_DT
			, GENDER
			, ISNULL(r.ADDR1, '') ADDR1
			, ISNULL(r.ADDR2, '') ADDR2
			, ISNULL(r.CITY, '') CITY
			, r.[STATE]
			, ISNULL(r.ZIP, '') ZIP
			, ISNULL(r.[EMAIL], '') [EMAIL]
			, ISNULL(r.PHONE_HOME, '') PHONE_HOME
			, ISNULL(r.PHONE_WORK, '') PHONE_WORK
			, NO_DEP
			, 1 AS SubCancelled
		FROM tpa_data_exchange_sub r
		INNER JOIN tblGrp g
			ON r.GRP_ID = g.GroupID
		WHERE r.RCD_TYPE = 'S'					-- subscribers only
			AND r.GRP_TYPE = 4					-- All American groups only
			AND g.GRCancelled = 0				-- active groups only
			AND (r.MBR_ST IN (1, 2))			-- only add and change transactions from tpa
		) r
		ON s.SubSSN = r.SSN
	WHERE (s.SubSSN IS NULL);

	-- Group to Group Change
	INSERT INTO tmpEDI_Rpt (
		SUBssn
		, EIMBRID
		, SUBfirstNAME
		, SUBlastNAME
		, SUBStreet
		, SUBcity
		, SUBstate
		, SUBzip
		, Stat
		, GroupID
		)
		SELECT DISTINCT s.SubSSN
			, s.EIMBRID
			, s.SubFirstName
			, s.SubLastName
			, substring(rtrim(isnull(s.SubStreet1,'')) + ' ' + rtrim(isnull(s.SubStreet2, '')), 1, 50) AS 
			SubStreet
			, s.SubCity
			, s.SubState
			, s.SubZip
			, 'GRP->GRP' AS Stat
			, s.SubGroupID
		FROM tpa_data_exchange_sub AS r
		INNER JOIN tblSubscr AS s
			ON r.SSN = s.SubSSN
				AND r.GRP_ID <> s.SubGroupID;


	-- subscriber name changes (Change-A)
	INSERT INTO tmpEDI_Rpt (
		SUBssn
		, EIMBRID
		, SUBfirstNAME
		, SUBlastNAME
		, Stat
		, GroupID
		, SUBStreet
		, SUBcity
		, SUBstate
		, SUBzip
		)
		SELECT DISTINCT r.SSN
			, r.MBR_ID
			, r.FIRST_NAME
			, r.LAST_NAME
			, 'Change-A' AS Stat
			, r.GRP_ID
			, substring(rtrim(isnull(r.ADDR1,'')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
			, r.CITY
			, r.[STATE]
			, r.ZIP
		FROM tpa_data_exchange_sub AS r
		INNER JOIN tblSubscr AS s
			ON r.SSN = s.SubSSN
		WHERE (r.FIRST_NAME <> s.SubFirstName)
			OR (r.LAST_NAME <> s.SubLastName);

		-- subscriber zip code changes (Change-B)
		INSERT INTO tmpEDI_Rpt (
			SubSSN
			, EIMBRID
			, SubZIP
			, Stat
			, GroupID
			, SubStreet
			, SubCity
			, SubState
			, SubFirstName
			, SubLastName
			)
		SELECT DISTINCT r.SSN
			, r.MBR_ID
			, r.ZIP
			, 'Change-B' AS Stat
			, r.GRP_ID
			, substring(rtrim(isnull(r.ADDR1,'')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
			, r.CITY
			, isnull(r.[STATE], '')
			, r.FIRST_NAME
			, r.LAST_NAME
		FROM tpa_data_exchange_sub AS r
		INNER JOIN tblSubscr AS s
			ON r.SSN = s.SubSSN
				AND r.ZIP <> s.SubZip;

		-- change in NO_DEP (Change-C) - compares the count of dependents (import versus existing)
		INSERT INTO tmpEDI_Rpt (
			SUBssn
			, EIMBRID
			, SUBfirstNAME
			, SUBlastNAME
			, SUBStreet
			, SUBcity
			, SUBstate
			, SUBzip
			, Stat
			, GroupID
			)
			SELECT r.SSN
				, r.MBR_ID
				, r.FIRST_NAME
				, r.LAST_NAME
				, substring(rtrim(isnull(r.ADDR1,'')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
				, r.CITY
				, r.[STATE]
				, r.ZIP
				, 'Change-C' AS Stat
				, r.GRP_ID
			FROM tpa_data_exchange_sub AS r
			INNER JOIN vw_tpa_dep_cnt_diffs AS dcd  -- subscribers who had dep changes
				ON r.SSN = dcd.SubSSN;

		-- Plan changes (Change-D)
		INSERT INTO tmpEDI_Rpt (
			SUBssn
			, SUBfirstNAME
			, SUBlastNAME
			, SUBStreet
			, SUBcity
			, SUBstate
			, SUBzip
			, Stat
			, GroupID
			)
			SELECT r.SSN
				, r.FIRST_NAME
				, r.LAST_NAME
				, substring(rtrim(isnull(r.ADDR1,'')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
				, r.CITY
				, r.[STATE]
				, r.ZIP
				, 'Change-D' AS Stat
				, r.GRP_ID
			FROM tpa_data_exchange_sub AS r
			INNER JOIN tblSubscr AS s
				ON r.SSN = s.SubSSN
			WHERE (s.PlanID <> r.[PLAN])
		
		/*  subscribers in QCD database and not in 
		tpa file - assumed to be deletes  */	
		INSERT INTO tmpEDI_Rpt (
			SubSSN
			, SubFirstName
			, SubLastName
			, GroupID
			, Stat
			, SubStreet
			, SubCity
			, SubState
			, SubZip
			)
		SELECT s.SubSSN
			, s.SubFirstName
			, s.SubLastName
			, s.SubGroupID
			, 'Deleted' AS Stat
			, substring(rtrim(isnull(s.SubStreet1, '')) + ' ' + rtrim(isnull(s.SubStreet2, '')), 1, 50) AS SubStreet
			, s.SubCity
			, s.SubState
			, s.SubZip
		FROM tblSubscr AS s
		INNER JOIN tblGrp g
			ON s.SubGroupID = g.GroupID
		LEFT OUTER JOIN (
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
			AND (s.SubCancelled = 1) -- active subscribers only	-- 130
		
		UNION
		
		/*  subscribers marked as deleted in the tpa file  */
		SELECT r.SSN
			, r.FIRST_NAME
			, r.LAST_NAME
			, r.GRP_ID
			, 'Deleted' AS Stat
			, substring(rtrim(isnull(r.ADDR1, '')) + ' ' + rtrim(isnull(r.ADDR2, '')), 1, 50) AS SubStreet
			, r.CITY
			, r.[STATE]
			, r.ZIP
		FROM tpa_data_exchange_sub r
		WHERE r.GRP_TYPE = 4
			AND r.MBR_ST = 3;  --24

		
		-- dropped groups
		INSERT INTO tmpEDI_Rpt (
			SUBssn
			, SUBfirstNAME
			, SUBlastNAME
			, GroupID
			, Stat
			)
		SELECT g.GroupID AS SubSSN
				, 'Dropped Group' AS SubFirstName
				, 'Group ID' AS SubLastName
				, g.GroupID
				, 'Cancelled' AS Stat
			FROM tblGrp g
			LEFT OUTER JOIN (
				SELECT DISTINCT GRP_ID
				FROM tpa_data_exchange_sub
				WHERE GRP_TYPE = 4
					AND MBR_ST IN (1, 2)
				) aag
				ON g.GroupID = aag.GRP_ID
			WHERE aag.GRP_ID IS NULL
				AND g.GroupType = 4
				AND g.GRCancelled = 0;
GO
