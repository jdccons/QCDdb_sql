USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_test]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--alter procedure  TestToSeeWhatTheErrorLineNumberRefersTo
--@debug int =0
--as
--declare @sql nvarchar(1000)
--set @sql = '/* some comment or other code
--more comments
--*/
--raiserror (''Some Error'',16,1)'
 

--if @debug > 0
--  print @sql
 
--exec sp_executesql @sql

CREATE procedure [dbo].[usp_test]
@debug int =0
as
declare @sql nvarchar(1000)
set @sql = 'UPDATE s
	SET s.SubLastName = r.LAST_NAME,
	s.SubFirstName = r.FIRST_NAME,
	s.SubMiddleName = r.MI,
	s.SubStreet1 = r.ADDR1,
	s.SubStreet2 = r.ADDR2,
	s.SubCity = r.CITY,
	s.SubState = r.[STATE],
	s.SubZip = r.ZIP,
	s.Email = r.EMAIL,
	s.SubPhoneHome = r.PHONE_HOME,
	s.SubPhoneWork = r.PHONE_WORK,
	s.PlanID = r.[PLAN],
	s.CoverID = r.COV,
	s.SubID = r.SUB_ID,
	s.SubSSN = r.SSN,
	s.SubCancelled = 1,
	s.DepCnt = r.NO_DEP,
	s.PreexistingDate = r.PREX_DT,
	s.SubEffDate = r.EFF_DT
	FROM tblSubscr s
	INNER JOIN tpa_data_exchange_sub r
		ON s.SubID = r.SUB_ID
			AND s.SubGroupID = r.GRP_ID
	WHERE (r.RCD_TYPE = ''' + 'S' + ''')
		AND (s.SubSSN = r.SSN
			OR s.SubID = r.SUB_ID) 
		AND (
			(s.SubLastName <> r.LAST_NAME)
			OR (s.SubFirstName <> r.FIRST_NAME)
			OR (s.SubMiddleName <> r.MI)
			OR (s.PlanID <> r.[PLAN])
			OR (s.CoverID <> r.COV)
			OR (s.SubStreet1 <> r.ADDR1)
			OR (ISNULL(s.SubStreet2, '') <> ISNULL(r.ADDR2, ''))
			OR (s.SubCity <> r.CITY)
			OR (s.SubState <> r.[STATE])
			OR (s.SubZip <> r.ZIP)
			OR (ISNULL(s.SubEmail, '') <> ISNULL(r.EMAIL, ''))
			OR (s.SubEffDate <> r.EFF_DT)
			OR (
				ISNULL(s.PreexistingDate, ''' + '1901-01-01 00:00:00.000' + ''') <> ISNULL(r.PREX_DT, ''' + '1901-01-01 00:00:00.000' + ''')
				)
			OR (s.SubPhoneHome <> r.PHONE_HOME)
			OR (s.SubPhoneWork <> r.PHONE_WORK)
			OR (
				ISNULL(s.SubDOB, ''' + '1901-01-01 00:00:00.000' + ''') <> ISNULL(r.DOB, ''' + '1901-01-01 00:00:00.000' + ''')
				)
			OR (s.DepCnt <> r.NO_DEP)
			);'

if @debug > 0
  print @sql
 
exec sp_executesql @sql
GO
