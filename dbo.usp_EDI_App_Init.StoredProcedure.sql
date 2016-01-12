USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Init]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Init]
@ReturnParm VARCHAR(255) OUTPUT 
AS
/* ================================================================
	Object:		    usp_EDI_App_Init	
	Author:			John Criswell
	Create date:	10/12/2013	 
	Description:	Fetches all initial enrollment
					group subscribers and dependents
					from the website and inserts them into 
					temporary tables
	Parameters:		None
	Where use:		frmOnlineEnrollmentProcessing
					(used to download individual,
					initial, and maintenance subscribers
					from the website; this procedure
					process initial subscribers)
					
	Change Log:
	---------------------------------------------------------------
	Change Date		Version		Changed by		Reason
	2015-02-23		2.0			JCriswell		Added error handling
	
	
=================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE	@LastOperation varchar(128), 
		@ErrorMessage varchar(8000), 
		@ErrorSeverity int, 
		@ErrorState int
------------------------------------------------------------------------------
BEGIN TRY
BEGIN TRANSACTION

/*   ---   get web data   ---   */
-- fetch indiv subscribers
SELECT	@LastOperation = 'fetch initial subscribers'
IF EXISTS (SELECT
    1
FROM
    [TRACENTRMTSRV].QCD.dbo.vwInitSub
WHERE
    (Download = 'Yes'
    AND MembershipStatus IN ( 'Added', 'Changed', 'Deleted' )))
    
TRUNCATE TABLE tblSubscriber_temp

/*  insert the new initial subscribers into a local table  */
INSERT  INTO tblSubscriber_temp
        ( SSN, EIMBRID, SubscriberID, GroupID, PlanID, CoverID, LastName,
          FirstName, MiddleInitial, Street1, Street2, City, [State], Zip,
          PhoneWork, PhoneHome, Email, DOB, DepCnt, Gender, Age,
          EffectiveDate, PreexistingDate, EmploymentDate, EmploymentStatus,
          Occupation_Title, MaritalStatus, CardPrinted, CardPrintedDate,
          MembershipStatus, DateCreated, DateChanged, DateDeleted, Download,
          DownloadDate, wSubID, AmtPaid )
        SELECT
            SSN, EIMBRID, SubscriberID, GroupID, PlanID, CoverID, LastName,
            FirstName, MiddleInitial, Street1, Street2, City, [State], Zip,
            PhoneWork, PhoneHome, Email, DOB, DepCnt, Gender, Age,
            EffectiveDate, PreexistingDate, EmploymentDate, EmploymentStatus,
            Occupation_Title, MaritalStatus, CardPrinted, CardPrintedDate,
            MembershipStatus, DateCreated, DateChanged, DateDeleted, Download,
            DownloadDate, wSubID, AmtPaid
        FROM
            [TRACENTRMTSRV].QCD.dbo.vwInitSub AS inits
        WHERE
            ( inits.Download = 'Yes' )
            AND ( inits.MembershipStatus IN ( 'Added', 'Changed', 'Deleted' ) )

/*  ---  fetch initial group depdendents   ---  */
SELECT	@LastOperation = 'fetch group depdendents'
IF EXISTS (SELECT
    1
FROM
    [TRACENTRMTSRV].QCD.dbo.vwDepDwnInit)
    
TRUNCATE TABLE tblDependent_temp

INSERT  INTO tblDependent_temp
        ( SubSSN, EIMBRID, DepSSN, FirstName, MiddleInitial, LastName, DOB,
          Age, Relationship, Gender, EffDate, PreexistingDate )
        SELECT
            initd.SubSSN, initd.EIMBRID,
            initd.DepSSN, initd.FirstName,
            initd.MiddleInitial, initd.LastName,
            initd.DOB, initd.Age,
            initd.Relationship, initd.Gender,
            initd.EffDate, initd.PreexistingDate
        FROM
            [TRACENTRMTSRV].QCD.dbo.vwDepDwnInit initd;

/*   move group subscribers to EDI_App_Subscr   */
SELECT	@LastOperation = 'move group subscribers to EDI_App_Subscr'
IF EXISTS (SELECT
    1
FROM
    tblEDI_App_Subscr)
            
TRUNCATE TABLE tblEDI_App_Subscr

INSERT  INTO tblEDI_App_Subscr
        ( SubSSN, EIMBRID, SubID, SubStatus, SubGroupID, PlanID, CoverID,
          SubLastName, SubFirstName, SubMiddleName, SUB_LUname, SubStreet1,
          SubStreet2, SubCity, SubState, SubZip, SubPhoneHome, SubPhoneWork,
          SUBdob, DepCnt, SubGender, SubAge, SubEffDate, PreexistingDate,
          SubMaritalStatus, SubCardPrt, SubCardPrtDte, TransactionType,
          DateCreated, DateUpdated, DateDeleted, wSubID, wUpt, AmtPaid )
        SELECT
            t.SSN, t.EIMBRID, t.SubscriberID, 'GRSUB' AS [Status], t.GroupID,
            t.PlanID, t.CoverID, t.LastName, t.FirstName, t.MiddleInitial,
            [LastName] + ', ' + [FirstName] + ' ' + SUBSTRING([MiddleInitial],1, 1) AS LU_Name,
            t.Street1, t.Street2, t.City, t.[State], t.Zip,
            REPLACE(t.PhoneHome, '-', '') PhoneHome,
            REPLACE(t.PhoneWork, '-', '') PhoneWork, t.DOB, t.DepCnt,
            t.Gender, t.Age, t.EffectiveDate, t.PreexistingDate,
            t.MaritalStatus, t.CardPrinted, t.CardPrintedDate,
            t.MembershipStatus, t.DateCreated, t.DateChanged, t.DateDeleted,
            t.wSubID, 1 AS setU, t.AmtPaid
        FROM
            tblSubscriber_temp t
        WHERE
            ( ( ( t.EIMBRID ) NOT IN ( 'INDIV' )) );
            
SELECT	@LastOperation = 'update fields from tblSubscr esp SubID for non BEXHM groups'
--update fields from tblSubscr esp SubID for non BEXHM groups
UPDATE
    eas
SET eas.SubID = s.SubID, 
	eas.SubCardPrt = s.SUBcardPRT,
    eas.SubCardPrtDte = s.SUBcardPRTdte, 
    eas.SubNotes = s.SUBnotes
FROM
    tblEDI_App_Subscr eas
		INNER JOIN tblSubscr s
			ON eas.SubSSN = s.SubSSN

SELECT	@LastOperation = 'fix PlanID for QCD Only groups'
--if the group type is a 1 i.e. QCD Only,
--then change the plan to 5 which is the planid for QCD Only
UPDATE
    eas
SET eas.PlanID = 5
FROM
    tblEDI_App_Subscr AS eas
    INNER JOIN tblGrp AS g
        ON eas.SubGroupID = g.GroupID
WHERE
    g.GroupType = 1

SELECT	@LastOperation = 'update rate ids for group subscribers'
--update rate id's for group subscribers
UPDATE
    eas
SET eas.RateID = r.RateID
FROM
    tblEDI_App_Subscr AS eas
    INNER JOIN tblRates AS r
        ON eas.CoverID = r.CoverID
           AND eas.PlanID = r.PlanID
           AND eas.SubGroupID = r.GroupID
           AND eas.SubStatus <> 'INDIV'


/*   ---   move group dependents to EDI_App_Dep   ---   */
SELECT	@LastOperation = 'move group dependents to EDI_App_Dep'
IF EXISTS (SELECT
    1
FROM
    tblEDI_App_Dep)
   
TRUNCATE TABLE tblEDI_App_Dep

INSERT  INTO tblEDI_App_Dep
        ( DEPssn, EIMBRID, DEPsubID, DEPfirstNAME, DEPlastNAME, DEPmiddleNAME,
          DepDOB, DepAge, DepRelationship, DEPgender, DepEffDate,
          PreexistingDate )
        SELECT
            td.DepSSN, td.EIMBRID, td.SubSSN, td.FirstName, td.LastName,
            td.MiddleInitial, td.DOB, td.Age, td.Relationship,
            SUBSTRING(td.[Gender], 1, 1) AS DepGender, td.EffDate,
            td.PreexistingDate
        FROM
            tblDependent_temp td
            INNER JOIN tblSubscriber_temp ts
                ON td.SubSSN = ts.SSN
        WHERE
            ( ( ( ts.MembershipStatus ) = 'Added'
                OR ( ts.MembershipStatus ) = 'Changed'
              )
              AND ( ( ts.GroupID ) NOT IN ( 'INDIV' ) )
            );


/*  clean up data on EDI_App_Subscr  */
--fix dep cnts
UPDATE
    s
SET s.DepCnt = depcnt.DepCnt
FROM
    tblEDI_App_Subscr s
    INNER JOIN ( SELECT
                    SubSSN, dbo.udf_EDI_App_Subscr_DepCnt(SubSSN) DepCnt
                 FROM
                    tblEDI_App_Subscr ) depcnt
        ON s.SubSSN = depcnt.SubSSN

        
--fix CoverIDs
UPDATE
    s
SET s.CoverID = c.CoverId
FROM
    tblEDI_App_Subscr s
    INNER JOIN ( SELECT
                    s.SubSSN, gct.TierCnt,
                    dbo.udf_EDI_App_Subscr_CoverID(s.SubSSN, gct.TierCnt) CoverID
                 FROM
                    tblEDI_App_Subscr AS s
                    INNER JOIN tblGrp g
                        ON s.SubGroupID = g.GroupID
                    INNER JOIN vw_Group_Coverage_Tiers gct
                        ON g.GroupID = gct.GroupID ) c
        ON s.SubSSN = c.SubSSN


--add the coverage description for the export file to the TPA
UPDATE
    eas
SET eas.Coverage = c.CoverDescr, eas.CoverDesc = c.CoverDescr
FROM
    tblEDI_App_Subscr AS eas
    INNER JOIN tblRates AS r
        ON eas.CoverID = r.CoverID
           AND eas.PlanId = r.PlanId
           AND eas.SubGroupID = r.GroupID
    INNER JOIN tblCoverage AS c
        ON r.CoverID = c.CoverID


COMMIT TRANSACTION
	SET @ReturnParm = 'Procedure succeeded'
END TRY

-- Error Handler
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Fetches all initial enrollment group subscribers and dependents from the website and inserts them into temporary tables.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_App_Init'
GO
