USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspSubscrSearch]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSubscrSearch]
    @SSN NVARCHAR(9) ,
    @SubID NVARCHAR(8) ,
    @SearchMethod INT
AS
/* ====================================================================================
	Object:			uspSubscrSearc
	Author:			John Criswell
	Create date:	2007-01-01	 
	Description:	Pulls data from tblSubscr and puts it in a temp table
	Called from:	frmSubscrInquire		
							
	Change Log:
	-----------------------------------------------------------------------------------
	Change Date		Versions	Changed by		Reason
	2007-01-01		1.0			JCriswell		Created
	2014-01-01		2.0			JCriswell		Deleted Bexar County
	
======================================================================================= */  
    TRUNCATE TABLE tblSubscrSearch

    DECLARE @Result INT

--SSN
IF @SearchMethod = 1 
   EXEC uspFindSubscr_SSN @SSN, @Result OUTPUT

IF @Result > 0
/* if the subscriber can be found in tblSubscr, then insert the subscriber
into the temp table */ 
BEGIN
INSERT  INTO tblSubscrSearch ( 
		SubSSN, SubStatus, SubID, SubGroupID,
		GrContEndDate, GrName, SubFirstName,
		SubMiddleName, SubLastName, SubStreet1,
		SubStreet2, SubCity, SubState, SubZip,
		SubPhoneHome, SubPhoneWork, SubDOB, SubAge,
		SubGender, PlanDesc, CoverDescr, Rate,
		DepCnt, SubEffDate, SubContBeg, SubContEnd,
		SubCardPrt, SubCardPrDate, PreexistingDate,
		SubNotes, GrHold, GrCancelled, SubCancelled,
		IndivSubStatus, OrthoCoverage,
		OrthoLifetimeLimit, WaitingPeriod, DateCreated, DateDeleted )
SELECT  s.SubSSN, s.SubStatus, s.SubID, s.SubGroupID, g.GRcontEND, g.GRname,
        s.SubFirstName, s.SubMiddleName, s.SubLastName, s.SubStreet1,
        s.SubStreet2, s.SubCity, s.SubState, s.SubZip, s.SubPhoneHome,
        s.SubPhoneWork, s.SubDOB, s.SubAge, s.SubGender, p.PlanDesc,
        c.CoverDescr, r.Rate, s.DepCnt, s.SubEffDate, s.SubContBeg,
        s.SubContEnd, s.SubCardPrt, s.SubCardPrtDte, s.PreexistingDate,
        s.SubNotes, g.GRhold, g.GRcancelled, s.SubCancelled,
        CASE s.SubCancelled
          WHEN 1 THEN 'Active'
          WHEN 2 THEN 'Hold'
          WHEN 3 THEN 'Cancelled'
          ELSE ''
        END AS IndivSubStatus, g.OrthoCoverage, g.OrthoLifetimeLimit,
        g.WaitingPeriod, 
        isnull(s.DateCreated, '1901-01-01 00:00:00') DateCreated, 
        isnull(s.DateDeleted, '1901-01-01 00:00:00') DateDeleted
FROM    tblGrp AS g
INNER JOIN tblSubscr AS s
LEFT OUTER JOIN tblRates AS r 
	ON s.RateID = r.RateID
LEFT OUTER JOIN tblCoverage AS c 
	ON s.CoverID = c.CoverID
LEFT OUTER JOIN tblPlans AS p 
	ON r.PlanID = p.PlanID ON g.GROUPid = s.SubGroupID
WHERE   ( s.SubSSN = @ssn )
END

-- subscriber ID
IF @SearchMethod = 2 
   EXEC uspFindSubscr_SubID @SubID, @Result OUTPUT

    IF @Result > 0
/* if the subscriber can be found in tblSubscr, then insert the subscriber
into the temp table */ 
BEGIN
    INSERT  INTO tblSubscrSearch ( SubSSN, SubStatus, SubID,
                                   SubGroupID, GrContEndDate, GrName,
                                   SubFirstName, SubMiddleName,
                                   SubLastName, SubStreet1, SubStreet2,
                                   SubCity, SubState, SubZip,
                                   SubPhoneHome, SubPhoneWork, SubDOB,
                                   SubAge, SubGender, PlanDesc,
                                   CoverDescr, Rate, DepCnt,
                                   SubEffDate, SubContBeg, SubContEnd,
                                   SubCardPrt, SubCardPrDate,
                                   PreexistingDate, SubNotes, GrHold,
                                   GrCancelled, SubCancelled,
                                   IndivSubStatus, OrthoCoverage,
                                   OrthoLifetimeLimit, WaitingPeriod,
                                   DateCreated, DateDeleted )
            SELECT  s.SubSSN, s.SubStatus, s.SubID, s.SubGroupID,
                    g.GRcontEND, g.GRname, s.SubFirstName,
                    s.SubMiddleName, s.SubLastName, s.SubStreet1,
                    s.SubStreet2, s.SubCity, s.SubState, s.SubZip,
                    s.SubPhoneHome, s.SubPhoneWork, s.SubDOB, s.SubAge,
                    s.SubGender, p.PlanDesc, c.CoverDescr, r.Rate,
                    s.DepCnt, s.SubEffDate, s.SubContBeg, s.SubContEnd,
                    s.SubCardPrt, s.SubCardPrtDte, s.PreexistingDate,
                    s.SubNotes, g.GRhold, g.GRcancelled,
                    s.SubCancelled, CASE s.SubCancelled
                                      WHEN 1 THEN 'Active'
                                      WHEN 2 THEN 'Hold'
                                      WHEN 3 THEN 'Cancelled'
                                      ELSE ''
                                    END AS IndivSubStatus,
                    g.OrthoCoverage, g.OrthoLifetimeLimit,
                    g.WaitingPeriod, 
                    isnull(s.DateCreated, '1901-01-01 00:00:00') DateCreated, 
					isnull(s.DateDeleted, '1901-01-01 00:00:00') DateDeleted
            FROM    tblGrp AS g
            INNER JOIN tblSubscr AS s
            LEFT OUTER JOIN tblRates AS r ON s.RateID = r.RateID
            LEFT OUTER JOIN tblCoverage AS c ON s.CoverID = c.CoverID
            LEFT OUTER JOIN tblPlans AS p ON r.PlanID = p.PlanID ON g.GROUPid = s.SubGroupID
            WHERE   ( s.SubID = @SubID )
END
GO
