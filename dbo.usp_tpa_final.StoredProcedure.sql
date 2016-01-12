USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_final]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  dentist direct import  */
create procedure [dbo].[usp_tpa_final]
as
/* ==================================================
	Object:			
	Author:			John Criswell
	Create date:		 
	Description:	 
					
							
	Change Log:
	--------------------------------------------------
	Change Date		Version		Changed by		Reason
	
	
	
====================================================== */

-- copy subscribers to subscriber table
TRUNCATE TABLE tpa_data_exchange_sub

INSERT INTO [QCDdataSQL2005_temp].[dbo].[tpa_data_exchange_sub] (
	[GRP_TYPE],
	[RCD_TYPE],
	[SSN],
	[SUB_ID],
	[DEP_SSN],
	[LAST_NAME],
	[FIRST_NAME],
	[MI],
	[DOB],
	[GRP_ID],
	[PLAN],
	[COV],
	[EFF_DT],
	[PREX_DT],
	[GENDER],
	[ADDR1],
	[ADDR2],
	[CITY],
	[STATE],
	[ZIP],
	[EMAIL],
	[PHONE_HOME],
	[PHONE_WORK],
	[NO_DEP],
	[REL],
	[CARD_PRT],
	[CARD_PRT_DT],
	[MBR_ST],
	[DT_UPDT]
	)
SELECT [GRP_TYPE],
	[RCD_TYPE],
	[SSN],
	[SUB_ID],
	[DEP_SSN],
	[LAST_NAME],
	[FIRST_NAME],
	[MI],
	[DOB],
	[GRP_ID],
	[PLAN],
	[COV],
	[EFF_DT],
	[PREX_DT],
	[GENDER],
	[ADDR1],
	[ADDR2],
	[CITY],
	[STATE],
	[ZIP],
	[EMAIL],
	[PHONE_HOME],
	[PHONE_WORK],
	[NO_DEP],
	[REL],
	[CARD_PRT],
	[CARD_PRT_DT],
	[MBR_ST],
	[DT_UPDT]
FROM [QCDdataSQL2005_temp].[dbo].[tpa_data_exchange]
WHERE RCD_TYPE = 'S';

/*  update attribute fields on tblSubscr  */	
IF EXISTS (
		SELECT s.SubGroupID, s.SubSSN, s.SubID, s.SUB_LUname, r.MBR_ST
		FROM tblSubscr AS s
		INNER JOIN tpa_data_exchange_sub AS r
			ON s.SubID = r.SUB_ID
				AND s.SubGroupID = r.GRP_ID
		WHERE (r.RCD_TYPE = 'S')
			AND (s.SubSSN = r.SSN
			OR s.SubID = r.SUB_ID) 
			AND ((s.SubLastName <> r.LAST_NAME)
			OR (s.SubFirstName <> r.FIRST_NAME)
			OR (s.SubMiddleName <> r.MI)
			OR (s.PlanID <> r.[PLAN])
			OR (s.CoverID <> r.COV)
			OR (ISNULL(s.SubStreet1, '') <> ISNULL(r.ADDR1, ''))
			OR (ISNULL(s.SubStreet2, '') <> ISNULL(r.ADDR2,''))
			OR (s.SubCity <> r.CITY)
			OR (s.SubState <> r.[STATE])
			OR (s.SubZip <> r.ZIP)
			OR (ISNULL(s.SubEmail, '') <> ISNULL(r.EMAIL, ''))
			OR (s.SubEffDate <> r.EFF_DT)
			OR (ISNULL(s.PreexistingDate, '1901-01-01 00:00:00.000') <> ISNULL(r.PREX_DT, '1901-01-01 00:00:00.000'))
			OR (s.SubPhoneHome <> r.PHONE_HOME)
			OR (s.SubPhoneWork <> r.PHONE_WORK)
			OR (ISNULL(s.SubDOB, '1901-01-01 00:00:00.000') <> ISNULL(r.DOB, '1901-01-01 00:00:00.000'))
			OR (s.DepCnt <> r.NO_DEP))
		)
	UPDATE s
		SET s.SubSSN = r.SSN,
			s.SubID = r.SUB_ID,
			s.EIMBRID = '',
			s.SubStatus = CASE 
							WHEN r.GRP_ID LIKE 'INDV%' THEN 'INDIV'
							ELSE 'GRSUB'
							END,
			s.SubGroupID = r.GRP_ID,
			s.PlanID = r.[PLAN],
			s.CoverID = r.COV,
			s.SubCancelled = 1,
			s.SubLastName = ISNULL(r.LAST_NAME, ''),
			s.SubFirstName = ISNULL(r.FIRST_NAME, ''),
			s.SubMiddleName = ISNULL(r.MI, ''),
			s.SubStreet1 = ISNULL(SUBSTRING(r.ADDR1, 1, 50), ''),
			s.SubStreet2 = ISNULL(SUBSTRING(r.ADDR2, 1, 50), ''),
			s.SubCity = ISNULL(r.CITY, ''),
			s.SubState = ISNULL(r.[STATE], ''),
			s.SubZip = ISNULL(r.ZIP, ''),			
			s.SubPhoneHome = ISNULL(r.PHONE_HOME, ''),
			s.SubPhoneWork = ISNULL(r.PHONE_WORK, ''),
			s.SubEmail = ISNULL(r.EMAIL, ''),
			s.SubDOB = ISNULL(r.DOB, '1901-01-01 00:00:00'),
			s.DepCnt = r.NO_DEP,
			s.SubGender = r.GENDER,
			s.SubEffDate = r.EFF_DT,
			s.PreexistingDate = r.PREX_DT,			
			s.User01 = 'usp_tpa_final',
			s.User06 = GETDATE()
		FROM tblSubscr s
		INNER JOIN tpa_data_exchange_sub r
			ON s.SubID = r.SUB_ID
				AND s.SubGroupID = r.GRP_ID
		WHERE (r.RCD_TYPE = 'S')
			AND (
				s.SubSSN = r.SSN
				OR s.SubID = r.SUB_ID
				)
			AND ((s.SubLastName <> r.LAST_NAME)
			OR (s.SubFirstName <> r.FIRST_NAME)
			OR (s.SubMiddleName <> r.MI)
			OR (s.PlanID <> r.[PLAN])
			OR (s.CoverID <> r.COV)
			OR (ISNULL(s.SubStreet1, '') <> ISNULL(r.ADDR1, ''))
			OR (ISNULL(s.SubStreet2, '') <> ISNULL(r.ADDR2,''))
			OR (s.SubCity <> r.CITY)
			OR (s.SubState <> r.[STATE])
			OR (s.SubZip <> r.ZIP)
			OR (ISNULL(s.SubEmail, '') <> ISNULL(r.EMAIL, ''))
			OR (s.SubEffDate <> r.EFF_DT)
			OR (ISNULL(s.PreexistingDate, '1901-01-01 00:00:00.000') <> ISNULL(r.PREX_DT, '1901-01-01 00:00:00.000'))
			OR (s.SubPhoneHome <> r.PHONE_HOME)
			OR (s.SubPhoneWork <> r.PHONE_WORK)
			OR (ISNULL(s.SubDOB, '1901-01-01 00:00:00.000') <> ISNULL(r.DOB, '1901-01-01 00:00:00.000'))
			OR (s.DepCnt <> r.NO_DEP));
GO
