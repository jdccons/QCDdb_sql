USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspCreateWebGroup]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		John Criswell
-- Create date: 09/27/2009
-- Description:	this procedure will add
-- an entire group with the group, subscriber,
-- and dependent data from Access to the
-- database on the website
--
-- Update date:  10/01/2009
-- Added query to update SubID on the dependent
-- table based on the SubID on the subscriber
-- table
--
-- Update date:  01/10/2012
-- Added query to insert plan and coverage
-- records, based on plans and coverages
-- in the subscriber population of the group
-- =============================================

CREATE PROCEDURE [dbo].[uspCreateWebGroup]
    @GroupID NVARCHAR(5) ,
    @CoverageTypeID INT ,
    @GroupTypeID INT ,
    @Password NVARCHAR(12)
AS 

	DECLARE @CoverTypeID AS INT
	SET @CoverTypeID = (SELECT  CoverageTypeID FROM [TRACENTRMTSRV].QCD.dbo.tblCoverageType WHERE CoverageType = @CoverageTypeID)
	
	/* add the Group data */
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblGroup ( GroupID, Password, GroupName,
                                                  Address1, Address2, City, ST,
                                                  Zip, EffDate, CreateDate,
                                                  EnrollStatus, CoverageTypeID,
                                                  GroupTypeID )
            SELECT  GroupID, @Password AS [Password], GRName AS GroupName,
                    GRStreet1 AS Address1, GRStreet2 AS Address2,
                    GRCity AS City, GRState AS State, GRZip AS Zip,
                    GRContBeg AS EffDate,
                    CONVERT(VARCHAR(10), GETDATE(), 101) AS CreateDate,
                    'OPEN' AS EnrollStatus, @CoverTypeID AS CoverageType,
                    @GroupTypeID AS GroupTypeID
            FROM    tblGrp
            WHERE   ( GroupID = @GroupID )

/* add the Subscriber data */
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblSubscriber ( SSN, EIMBRID,
                                                       SubscriberID, GroupID,
                                                       PlanID, CoverID,
                                                       LastName, FirstName,
                                                       MiddleInitial, Street1,
                                                       Street2, City, State,
                                                       Zip, PhoneWork,
                                                       PhoneHome, DOB,
                                                       DepCnt, Gender,
                                                       Age, EffectiveDate,
                                                       PreexistingDate,
                                                       EmploymentStatus,
                                                       MaritalStatus,
                                                       CardPrinted,
                                                       CardPrintedDate,
                                                       MembershipStatus )
            SELECT  SubSSN, EIMBRID, SubID, SubGroupID, PlanID, CoverID,
                    RTRIM(LTRIM(SubLastName)) AS LastName,
                    RTRIM(LTRIM(SubFirstName)) AS FirstName,
                    RTRIM(LTRIM(SUBSTRING(SubMiddleName, 1, 1))) AS MiddleInitial,
                    RTRIM(LTRIM(SubStreet1)) AS Street1,
                    RTRIM(LTRIM(SubStreet2)) AS Street2,
                    RTRIM(LTRIM(SubCity)) AS City, SubState, SubZip,
                    SubPhoneWork, SubPhoneHome, SUBdob, DepCnt, SubGender,
                    SubAge, SubEffDate, PreexistingDate,
                    'Active' AS EmploymentStatus, SubMaritalStatus, SubCardPrt,
                    SubCardPrtDte, 'Current' AS MembershipStatus
            FROM    tblSubscr
            WHERE   ( SubGroupID = @GroupID )

/* add the dependent data */
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblDependent ( SubSSN, EIMBRID, DepSSN,
                                                      FirstName, MiddleInitial,
                                                      LastName, DOB, Age,
                                                      Relationship, Gender,
                                                      EffDate, PreexistingDate,
                                                      DepID_local )
            SELECT  ld.DepSubID, ld.EIMBRID, ld.DepSSN, ld.DepFirstName,
                    ld.DepMiddleName, ld.DepLastName,
                    CONVERT(VARCHAR, ld.DepDOB, 101) AS DepDOB, ld.DepAge,
                    ld.DepRelationship, ld.DepGender,
                    CONVERT(VARCHAR, ld.DepEffDate, 101),
                    CONVERT(VARCHAR, ld.PreexistingDate, 101), ld.ID
            FROM    tblDependent AS ld
            INNER JOIN tblSubscr AS ls ON ls.SubSSN = ld.DepSubID
            WHERE   ls.SubGroupID = @GroupID

/* update the SubID's on the dependent table */
    UPDATE  rd
    SET     rd.SubID = rs.SubID
    FROM    [TRACENTRMTSRV].QCD.dbo.tblDependent rd
    INNER JOIN [TRACENTRMTSRV].QCD.dbo.tblSubscriber rs ON rd.SubSSN = rs.SSN
    WHERE   rs.GroupID = @GroupID

/* create Plan records */
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblGroupPlan ( GroupID, PlanID )
            SELECT  GroupID, PlanID
            FROM    [TRACENTRMTSRV].QCD.dbo.tblSubscriber
            GROUP BY GroupID, PlanID
            HAVING  GroupID = @GroupID

/* create Coverage records */
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblGroupCover ( GroupID, CoverID )
            SELECT  GroupID, CoverID
            FROM    [TRACENTRMTSRV].QCD.dbo.tblSubscriber
            GROUP BY GroupID, CoverID
            HAVING  GroupID = @GroupID
GO
