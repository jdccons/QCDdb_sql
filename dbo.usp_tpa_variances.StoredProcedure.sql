USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_variances]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_tpa_variances]
AS
/* =====================================================================
	Object:			usp_tpa_variances
	Author:			John Criswell
	Create date:	10/10/2015 
	Description:	Creates data for variance
					report between tpa and QCD
	Where used:		fdlgAASync
				
					
								
							
	Change Log:
	--------------------------------------------------------------------
	Change Date	Version		Changed by		Reason
	2015-10-10	1.0			J Criswell		Created
	2015-10-19	2.0			J Criswell		Added logic to convert REL integers
											string code values.
	
======================================================================== */

/*  declarations  */

/*  end of declarations  */


BEGIN
	IF OBJECT_ID('tempdb..#tpa_variances', 'U') IS NOT NULL
		DROP TABLE #tpa_variances;
	  
	CREATE TABLE #tpa_variances
		(
		  [ID] [INT] IDENTITY(1, 1) NOT NULL ,
		  [DataElementTitle] [NVARCHAR](50) NULL ,
		  [DataElement] [NVARCHAR](50) NULL ,
		  [SubSSN] [NVARCHAR](10) NULL ,
		  [GroupID] [NVARCHAR](50) NULL ,
		  [NewValue] [NVARCHAR](50) NULL ,
		  [OldValue] [NVARCHAR](50) NULL ,
		  [RptDate] [DATETIME] NULL ,
		  [PrtOrder] [INT] NULL
		);


	ALTER TABLE #tpa_variances ADD PRIMARY KEY CLUSTERED (ID);


	-- Step 1 different SSN
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				5 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub SSN' AS Elem ,
				ISNULL(SubSSN, '') SubSSN ,
				ISNULL(GRP_ID, '') GRP_ID ,
				ISNULL(SSN, '') AS NewValue ,
				ISNULL(SubSSN, '') AS OldValue ,
				RptDate
			FROM
				vw_tpa_var_chg_ssn;

	-- Step 2 different SubID
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				10 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub SubID' AS Elem ,
				SubSSN ,
				GRP_ID ,
				ISNULL(SUB_ID, '') AS NewValue ,
				ISNULL(SubID, '') AS OldValue ,
				RptDate
			FROM
				vw_tpa_var_chg_subid;


	-- Step 3 different group
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				15 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Group ID' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL([GRP_ID], '')) AS NewValue ,
				UPPER(ISNULL([SubGroupID], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON r.SSN = s.SubSSN
			WHERE
				( ( ISNULL([SubGroupID], '') ) <> ISNULL([GRP_ID], '') )
			UNION
			SELECT
				15 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Group ID' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL([GRP_ID], '')) AS NewValue ,
				UPPER(ISNULL([SubGroupID], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON r.SSN = s.SubSSN
			WHERE
				( ( ISNULL([SubGroupID], '') ) <> ISNULL([GRP_ID], '') );

	-- Step 4 different plan
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				20 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Plan' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(p2.[PlanDesc], '')) AS NewValue ,
				UPPER(ISNULL(p.[PlanDesc], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
				INNER JOIN tblPlans p
					ON s.PlanID = p.[PlanID]
				INNER JOIN tblPlans p2
					ON r.[PLAN] = p2.[PlanID]
			WHERE
				( ISNULL(s.PlanID, 0) <> ISNULL(r.[PLAN], 0) )
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				20 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Plan' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(p2.[PlanDesc], '')) AS NewValue ,
				UPPER(ISNULL(p.[PlanDesc], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
				INNER JOIN tblPlans p
					ON s.PlanID = p.[PlanID]
				INNER JOIN tblPlans p2
					ON r.[PLAN] = p2.[PlanID]
			WHERE
				( ISNULL(s.PlanID, 0) <> ISNULL(r.[PLAN], 0) )
				AND ( g.GroupType IN ( 4 ) );


	-- Step 5 different coverage
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				25 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Coverage' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(c2.[CoverDescr], '')) AS NewValue ,
				UPPER(ISNULL(c.[CoverDescr], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
				INNER JOIN tblCoverage c
					ON s.CoverID = c.[CoverID]
				INNER JOIN tblCoverage c2
					ON r.[COV] = c2.[CoverID]
			WHERE
				( ISNULL(s.CoverID, 0) <> ISNULL(r.[COV], 0) )
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				25 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Coverage' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(c2.[CoverDescr], '')) AS NewValue ,
				UPPER(ISNULL(c.[CoverDescr], '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
				INNER JOIN tblCoverage c
					ON s.CoverID = c.[CoverID]
				INNER JOIN tblCoverage c2
					ON r.[COV] = c2.[CoverID]
			WHERE
				( ISNULL(s.CoverID, 0) <> ISNULL(r.[COV], 0) )
				AND ( g.GroupType IN ( 4 ) );
			
	-- Step 6 different first name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				30 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub First Name' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.FIRST_NAME, '')) AS NewValue ,
				UPPER(ISNULL(s.SubFirstName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(s.SubFirstName, '')) <> UPPER(ISNULL(r.FIRST_NAME, '')) )
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				30 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub First Name' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.FIRST_NAME, '')) AS NewValue ,
				UPPER(ISNULL(s.SubFirstName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(s.SubFirstName, '')) <> UPPER(ISNULL(r.FIRST_NAME, '')) )
				AND ( g.GroupType IN ( 4 ) );

	-- Step 7 different last name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				35 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Last Name' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.LAST_NAME, '')) AS NewValue ,
				UPPER(ISNULL(s.SubLastName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(s.SubLastName, '')) <> UPPER(ISNULL(r.LAST_NAME, '')) )
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				35 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Last Name' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.LAST_NAME, '')) AS NewValue ,
				UPPER(ISNULL(s.SubLastName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(s.SubLastName, '')) <> UPPER(ISNULL(r.LAST_NAME, '')) )
				AND ( g.GroupType IN ( 4 ) );

	-- Step 8 different middle name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				40 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Middle Initial' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.MI, '')) AS NewValue ,
				UPPER(ISNULL(s.SubMiddleName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(r.[MI], '')) <> UPPER(LEFT(ISNULL(s.[SubMiddleName], ''), 1)) )
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				40 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Middle Initial' AS Elem ,
				ISNULL(s.SubSSN, '') SubSSN ,
				ISNULL(r.GRP_ID, '') GRP_ID ,
				UPPER(ISNULL(r.MI, '')) AS NewValue ,
				UPPER(ISNULL(s.SubMiddleName, '')) AS OldValue ,
				r.DT_UPDT AS RptDate
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				( UPPER(ISNULL(r.[MI], '')) <> UPPER(LEFT(ISNULL(s.[SubMiddleName], ''), 1)) )
				AND ( g.GroupType IN ( 4 ) );


	-- Step 9 different date of birth
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				45 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub DOB' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.DOB AS NewValue ,
				s.SubDOB AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				r.DOB <> s.SubDOB
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				45 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub DOB' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.DOB AS NewValue ,
				s.SubDOB AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				r.DOB <> s.SubDOB
				AND ( g.GroupType IN ( 4 ) );


	-- Step 10 different gender
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				50 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Gender' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.GENDER AS NewValue ,
				s.SubGender AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				r.GENDER <> s.SubGender
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				50 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Gender' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.GENDER AS NewValue ,
				s.SubGender AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				r.GENDER <> s.SubGender
				AND ( g.GroupType IN ( 4 ) );

	-- Step 11 different preexisting date
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				60 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Preexisting Date' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				convert(varchar(10), r.PREX_DT, 101) AS NewValue ,
				convert(varchar(10), s.PreexistingDate, 101) AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PREX_DT, '1901-01-01 00:00:00') <> ISNULL(s.PreexistingDate, '1901-01-01 00:00:00')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				60 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Preexisting Date' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				convert(varchar(10), r.PREX_DT, 101) AS NewValue ,
				convert(varchar(10), s.PreexistingDate, 101) AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PREX_DT, '1901-01-01 00:00:00') <> ISNULL(s.PreexistingDate, '1901-01-01 00:00:00')
				AND ( g.GroupType IN ( 4 ) );
		
	-- Step 12 different effective date
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				70 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Effective Date' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				CONVERT(VARCHAR(10), r.EFF_DT, 101) AS NewValue ,
				CONVERT(VARCHAR(10), s.SubEffDate, 101) AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.EFF_DT, '1901-01-01 00:00:00') <> ISNULL(s.SubEffDate, '1901-01-01 00:00:00')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				70 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Effective Date' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				CONVERT(VARCHAR(10), r.EFF_DT, 101) AS NewValue ,
				CONVERT(VARCHAR(10), s.SubEffDate, 101) AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.EFF_DT, '1901-01-01 00:00:00') <> ISNULL(s.SubEffDate, '1901-01-01 00:00:00')
				AND ( g.GroupType IN ( 4 ) );


	-- Step 13 different address 1
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				75 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Address 1' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ADDR1 AS NewValue ,
				s.SubStreet1 AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ADDR1, '') <> ISNULL(s.SubStreet1, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				75 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Address 1' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ADDR1 AS NewValue ,
				s.SubStreet1 AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ADDR1, '') <> ISNULL(s.SubStreet1, '')
				AND ( g.GroupType IN ( 4 ) );


	-- Step 14 different address 2
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				80 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Address 2' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ADDR2 AS NewValue ,
				s.SubStreet2 AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ADDR2, '') <> ISNULL(s.SubStreet2, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				80 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Address 2' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ADDR2 AS NewValue ,
				s.SubStreet2 AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ADDR2, '') <> ISNULL(s.SubStreet2, '')
				AND ( g.GroupType IN ( 4 ) );


	-- Step 15 different city
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				85 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub City' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.CITY AS NewValue ,
				s.SubCity AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.CITY, '') <> ISNULL(s.SubCity, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				85 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub City' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.CITY AS NewValue ,
				s.SubCity AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.CITY, '') <> ISNULL(s.SubCity, '')
				AND ( g.GroupType IN ( 4 ) );


	-- Step 16 different state
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				90 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub State/Province' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.[STATE] AS NewValue ,
				s.SubState AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.[STATE], '') <> ISNULL(s.SubState, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				90 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub State/Province' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.[STATE] AS NewValue ,
				s.SubState AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.[STATE], '') <> ISNULL(s.SubState, '')
				AND ( g.GroupType IN ( 4 ) );


	-- Step 17 different zip
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				95 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Zipcode' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ZIP AS NewValue ,
				s.SubZip AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ZIP, '') <> ISNULL(s.SubZip, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				95 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Zipcode' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.ZIP AS NewValue ,
				s.SubZip AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.ZIP, '') <> ISNULL(s.SubZip, '')
				AND ( g.GroupType IN ( 4 ) );

	-- Step 18 different home phone
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				100 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Home Phone' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.PHONE_HOME AS NewValue ,
				s.SubPhoneHome AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PHONE_HOME, '') <> ISNULL(s.SubPhoneHome, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				100 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Home Phone' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.PHONE_HOME AS NewValue ,
				s.SubPhoneHome AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PHONE_HOME, '') <> ISNULL(s.SubPhoneHome, '')
				AND ( g.GroupType IN ( 4 ) );




	-- Step 19 different work phone
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				105 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Work Phone' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.PHONE_WORK AS NewValue ,
				s.SubPhoneWork AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PHONE_WORK, '') <> ISNULL(s.SubPhoneWork, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				105 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Work Phone' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.PHONE_WORK AS NewValue ,
				s.SubPhoneWork AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.PHONE_WORK, '') <> ISNULL(s.SubPhoneWork, '')
				AND ( g.GroupType IN ( 4 ) );

	-- Step 20 different email
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				110 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Email' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.EMAIL AS NewValue ,
				s.SubEmail AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.EMAIL, '') <> ISNULL(s.SubEmail, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				110 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Email' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.EMAIL AS NewValue ,
				s.SubEmail AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.EMAIL, '') <> ISNULL(s.SubEmail, '')
				AND ( g.GroupType IN ( 4 ) );

	-- Step 15 different count of dependents
		INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				115 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Dependent Count' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.NO_DEP AS NewValue ,
				s.DepCnt AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SSN, '') = ISNULL(s.SubSSN, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.NO_DEP, '') <> ISNULL(s.DepCnt, '')
				AND ( g.GroupType IN ( 4 ) )
			UNION
			SELECT
				110 AS Ord ,
				'Subscriber Change' AS Title ,
				'Sub Email' AS Elem ,
				s.SubSSN ,
				r.GRP_ID ,
				r.NO_DEP AS NewValue ,
				s.DepCnt AS OldValue ,
				r.DT_UPDT
			FROM
				tpa_data_exchange_sub r
				INNER JOIN tblSubscr s
					ON ISNULL(r.SUB_ID, '') = ISNULL(s.SubID, '')
				INNER JOIN tblGrp g
					ON s.SubGroupID = g.GroupID
			WHERE
				ISNULL(r.NO_DEP, '') <> ISNULL(s.DepCnt, '')
				AND ( g.GroupType IN ( 4 ) );

	/*  dependent changes  */

	-- Step 16 different first name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				120 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep First Name' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				UPPER(r.[FIRST_NAME]) AS NewValue ,
				UPPER(d.[DepFirstName]) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				ISNULL(d.[DepFirstName], '') <> ISNULL(r.[FIRST_NAME], '')
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
	        


	-- Step 17 different last name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				125 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep Last Name' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				UPPER(r.[LAST_NAME]) AS NewValue ,
				UPPER(d.[DepLastName]) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				ISNULL(d.[DepLastName], '') <> ISNULL(r.[LAST_NAME], '')
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
	        

	-- Step 18 different middle name
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				130 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep Middle Name' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				UPPER(r.[MI]) AS NewValue ,
				UPPER(d.[DepMiddleName]) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				ISNULL(d.[DepMiddleName], '') <> ISNULL(r.[MI], '')
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
	        

	-- Step 19 different relationship
	INSERT INTO #tpa_variances (
		PrtOrder, DataElementTitle, DataElement, SubSSN, GroupID, NewValue, OldValue, RptDate
		)
	SELECT 135 AS Ord, 
			'Dependent Change' AS Title, 
			'Dep Relationship' AS Elem, 
			d.SubSSN AS SubSSN, 
			r.GRP_ID AS GroupID,
			CASE 
				WHEN r.REL = 0 THEN ''
				WHEN r.REL = 1 THEN 'S'
				WHEN r.REL = 2 THEN 'C'
				WHEN r.REL = 3 THEN 'O'
				ELSE ''
			END AS NewValue,
			UPPER(d.[DepRel]) AS OldValue, 
			r.DT_UPDT
	FROM tpa_data_exchange_dep r
	INNER JOIN vw_GrpDep d
		ON (r.[MBR_ID] = d.EIMBRID)
	WHERE ISNULL(d.[DepRel], '') <> (
			CASE 
				WHEN r.REL = 0 THEN ''
				WHEN r.REL = 1 THEN 'S'
				WHEN r.REL = 2 THEN 'C'
				WHEN r.REL = 3 THEN 'O'
				ELSE ''
			END
			)
		AND d.GrpType = 'All American'
		AND d.GrpCancel = 'Active'
		AND d.SubCancel = 'Active';

	   

	-- Step 20 different gender
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				140 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep Gender' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				UPPER(r.[GENDER]) AS NewValue ,
				UPPER(d.[DepGender]) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				ISNULL(d.[DepGender], '') <> ISNULL(r.[GENDER], '')
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
				
				
	-- Step 21 effective date
	INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				145 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep Effective Date' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				convert( varchar(10), r.[EFF_DT], 101) AS NewValue ,
				convert(varchar(10), d.[DepEffDate], 101) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				r.[EFF_DT] <> d.[DepEffDate]
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
				
		-- Step 22 preexisting date
		INSERT  INTO #tpa_variances
			( PrtOrder ,
			  DataElementTitle ,
			  DataElement ,
			  SubSSN ,
			  GroupID ,
			  NewValue ,
			  OldValue ,
			  RptDate
			)
			SELECT
				150 AS Ord ,
				'Dependent Change' AS Title ,
				'Dep Preexisting Date' AS Elem ,
				d.SubSSN AS SubSSN ,
				r.GRP_ID AS GroupID ,
				convert( varchar(10), r.[PREX_DT], 101) AS NewValue ,
				convert(varchar(10), d.[DepPrexDate], 101) AS OldValue ,				
				r.DT_UPDT
			FROM
				tpa_data_exchange_dep r
				INNER JOIN vw_GrpDep d
					ON ( r.[MBR_ID] = d.EIMBRID )
			WHERE
				r.[PREX_DT] <> d.[DepPrexDate]
				AND d.GrpType = 'All American'
				AND d.GrpCancel = 'Active'
				AND d.SubCancel = 'Active';
				
		TRUNCATE TABLE dbo.tmpAA_VarianceReport;
				
        INSERT  INTO tmpAA_VarianceReport
                ( DataElementTitle ,
                  DataElement ,
                  SubSSN ,
                  AAGrpID ,                  
                  NewValue ,
                  OldValue ,
                  RptDate ,
                  PrtOrder
                )
                SELECT
                    DataElementTitle ,
                    DataElement ,
                    SubSSN ,
                    GroupID ,                    
                    NewValue ,
                    OldValue ,
                    RptDate ,
                    PrtOrder
                FROM
                    #tpa_variances;
END
GO
