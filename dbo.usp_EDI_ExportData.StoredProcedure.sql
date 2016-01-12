USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_ExportData]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_ExportData]
    (
      @GroupID AS VARCHAR(5) ,
      @PlanID AS INTEGER
    )
AS 
/* ================================================================
  Object:			usp_EDI_ExportData
  Author:			Ryan Wicks
  Create date:		2012-10-15 
  Description:		Imports data from flat files that certain groups
					using the HIPAA ANSI 834 5010 specification submit.
					
					
  Parameters:		GroupID varchar(8), @PlanID int
  Where Used:		frmImportProcessing (used for HIPAA ANSI 834 groups)
					
				
  Change Log:
  -----------------------------------------------------------------
  Change Date		Version		Changed by		Reason
  2012-10-15		1.0			RWicks			Created	
	
	
=================================================================== */
    SET nocount ON

    BEGIN

        DECLARE @FileID UNIQUEIDENTIFIER

        CREATE TABLE #temp
            (
              EntitySeq INT ,
              AddressLine1 VARCHAR(MAX) ,
              AddressLine2 VARCHAR(MAX) ,
              BeginEligibility VARCHAR(MAX) ,
              City VARCHAR(MAX) ,
              Coverage VARCHAR(MAX) ,
              CoverageLevel VARCHAR(MAX) ,
              DependentNumber VARCHAR(MAX) ,
              DOB VARCHAR(MAX) ,
              EndEligibility VARCHAR(MAX) ,
              FirstName VARCHAR(MAX) ,
              Gender VARCHAR(MAX) ,
              GroupName VARCHAR(MAX) ,
              LastName VARCHAR(MAX) ,
              MemberSSN VARCHAR(MAX) ,
              MiddleName VARCHAR(MAX) ,
              NameSuffix VARCHAR(MAX) ,
              [State] VARCHAR(MAX) ,
              SubscriberInd VARCHAR(MAX) ,
              SubscriberNumber VARCHAR(MAX) ,
              ZIP VARCHAR(MAX)
            )

        SELECT  @FileID = FileID
        FROM    (
                  SELECT TOP 1
                            FileID
                  FROM      EDI_ParseFile
                  ORDER BY  LoadCompleted DESC
                ) x

        INSERT  INTO #Temp
                EXEC usp_EDI_GetData @FileID

        CREATE TABLE #Sub
            (
              SubSSN NVARCHAR(18) ,
              SubID NVARCHAR(16) ,
              SubGroupID NVARCHAR(10) ,
              PlanID INT ,
              CoverID INT ,
              SUB_LUname NVARCHAR(100) ,
              SubLastName NVARCHAR(100) ,
              SubFirstName NVARCHAR(100) ,
              SubMiddleName NVARCHAR(50) ,
              SubStreet1 NVARCHAR(100) ,
              SubStreet2 NVARCHAR(100) ,
              SubCity NVARCHAR(100) ,
              SubState NVARCHAR(4) ,
              SubZip NVARCHAR(18) ,
              SUBdob DATETIME ,
              DepCnt INT ,         -- (count(*) from Dependents)
              SubGender NVARCHAR(14) ,
              SubAge INT ,              -- (calculation)
              SubEffDate DATETIME ,
              SubExpDate DATETIME
            )

        CREATE TABLE #Dep
            (
              DepSSN NVARCHAR(18) ,
              DepSubID NVARCHAR(18) ,
              DepFirstName NVARCHAR(100) ,
              DepMiddleName NVARCHAR(50) ,
              DepLastName NVARCHAR(100) ,
              DepDOB DATETIME ,
              DepAge INT ,                  -- (null)
              DepRelationship NVARCHAR(4) , -- (c = child (19); s = spouse (01))
              DepGender NVARCHAR(2) ,
              DepEffDate DATETIME
            )         -- (null)

        INSERT  INTO #Dep ( DepSSN, DepSubID, DepFirstName, DepMiddleName,
                            DepLastName, DepDOB, DepAge, DepRelationship,
                            DepGender, DepEffDate )
                SELECT  CAST(MemberSSN AS NVARCHAR(18)),
                        CAST(SubscriberNumber AS NVARCHAR(18)),
                        CAST(FirstName AS NVARCHAR(100)),
                        CAST(MiddleName AS NVARCHAR(50)),
                        CAST(LastName AS NVARCHAR(100)), CAST(DOB AS DATETIME),
                        CAST(DATEDIFF(year, CAST(DOB AS DATETIME), GETDATE()) AS INT),
                        CAST(CASE DependentNumber
                               WHEN '01' THEN 'S'
                               WHEN '19' THEN 'C'
                             END AS NVARCHAR(4)), CAST(Gender AS NVARCHAR(2)),
                        CAST(BeginEligibility AS DATETIME)
                FROM    #temp
                WHERE   ISNULL(SubscriberInd, 'N') = 'N'
                        AND ISNULL(EntitySeq, 0) > 0

        INSERT  INTO #Sub ( SubSSN, SubID, SubGroupID, PlanID, CoverID,
                            SUB_LUname, SubLastName, SubFirstName,
                            SubMiddleName, SubStreet1, SubStreet2, SubCity,
                            SubState, SubZip, SUBdob, DepCnt, SubGender,
                            SubAge, SubEffDate, SubExpDate )
                SELECT  CAST(MemberSSN AS NVARCHAR(18)),
                        CAST(SubscriberNumber AS NVARCHAR(18)), @GroupID,
						--cast((select top 1 GroupName from #temp where GroupName is not null) as nvarchar(10)),
                        @PlanID, CAST(CASE CoverageLevel
                                        WHEN 'EMP' THEN 1
                                        WHEN 'ECH' THEN 2
                                        WHEN 'ESP' THEN 3
                                        WHEN 'FAM' THEN 4
                                      END AS INT),
                        CAST(LastName + ', ' + FirstName + ISNULL(' '
                                                              + MiddleName, '') AS NVARCHAR(100)),
                        CAST(LastName AS NVARCHAR(100)),
                        CAST(FirstName AS NVARCHAR(100)),
                        CAST(MiddleName AS NVARCHAR(50)),
                        CAST(AddressLine1 AS NVARCHAR(100)),
                        CAST(AddressLine2 AS NVARCHAR(100)),
                        CAST(City AS NVARCHAR(100)),
                        CAST([State] AS NVARCHAR(100)),
                        CAST(ZIP AS NVARCHAR(100)), CAST(DOB AS DATETIME),
                        CAST((
                               SELECT   COUNT(*)
                               FROM     #Dep d
                               WHERE    CAST(t.SubscriberNumber AS NVARCHAR(16)) = d.DepSubID
                             ) AS INT), CAST(Gender AS NVARCHAR(2)),
                        CAST(DATEDIFF(year, CAST(DOB AS DATETIME), GETDATE()) AS INT),
                        CAST(BeginEligibility AS DATETIME),
                        CAST(EndEligibility AS DATETIME)
                FROM    #temp t
                WHERE   SubscriberInd = 'Y'
                        AND ISNULL(EntitySeq, 0) > 0
   
        TRUNCATE TABLE dbo.tblEDI_App_Subscr

		-- populate the subscriber table
        INSERT  INTO dbo.tblEDI_App_Subscr ( SubSSN, SubGroupID, PlanID,
                                             CoverID, SUB_LUname, SubLastName,
                                             SubFirstName, SubMiddleName,
                                             SubStreet1, SubStreet2, SubCity,
                                             SubState, SubZip, SUBdob, DepCnt,
                                             SubGender, SubAge, SubEffDate,
                                             SubExpDate )
                SELECT  SubSSN, SubGroupID, PlanId, CoverID, SUB_LUname,
                        SubLastName, SubFirstName, SubMiddleName, SubStreet1,
                        SubStreet2, SubCity, SubState, SubZip, SUBdob,
                        DepCnt, SubGender, SubAge, SubEffDate, SubExpDate
                FROM    #Sub
        
		-- updates rate id's
        UPDATE  e
        SET     e.RateID = r.RateID
        FROM    tblEDI_App_Subscr e
        INNER JOIN tblRates r ON e.PlanID = r.PlanID
                                 AND e.CoverID = r.CoverID
                                 AND e.SubGroupID = r.GroupID

-- updates fields with QCD specific data                        
        UPDATE  e
        SET     e.SubID = s.SubID, e.SUBcardPRT = s.SUBcardPRT,
                e.SUBcardPRTdte = s.SUBcardPRTdte, e.SUBnotes = s.SUBnotes,
                e.DateCreated = s.DateCreated, e.DateUpdated = s.DateUpdated,
                e.SubStatus = 'GRSUB'
        FROM    tblEDI_App_Subscr e
        INNER JOIN tblSubscr s ON e.SUBssn = s.SUBssn

        TRUNCATE TABLE dbo.tblEDI_App_Dep

		-- populate the dependent table
        INSERT  INTO dbo.tblEDI_App_Dep ( DepSSN, EIMBRID, DepSubID,
                                          DepFirstName, DepMiddleName,
                                          DepLastName, DepDOB, DepAge,
                                          DepRelationship, DepGender,
                                          DepEffDate )
                SELECT  DepSSN, '' EIMBRID, DepSubID, DepFirstName,
                        DepMiddleName, DepLastName, DepDOB, DepAge,
                        DepRelationship, DepGender, DepEffDate
                FROM    #Dep

    END
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Imports data from flat files that certain groups using the HIPAA ANSI 834 5010 specification submit.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_ExportData'
GO
