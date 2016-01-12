USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_App_Subscr_Indiv]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EDI_App_Subscr_Indiv]
AS

INSERT  INTO tblEDI_App_Subscr
        ( SubSSN, SubID, SubStatus, SubGroupID, PlanID, CoverID, SubLastName,
          SubFirstName, SubMiddleName, SUB_LUname, SubStreet1, SubStreet2,
          SubCity, SubState, SubZip, SubPhoneHome, SUBbankDraftNo, SUBdob,
          DepCnt, SubGender, SubAge, SubEffDate, PreexistingDate,
          SubMaritalStatus, SubCardPrt, SubCardPrtDte, TransactionType,
          DateCreated, DateUpdated, DateDeleted, RateID, SUBcoverage,
          SUBplanIDin, SubContBeg, SubContEnd, EIMBRID, wSubID, wUpt, AmtPaid )
        SELECT
            s.SSN, s.SubscriberID, 'INDIV' AS [Status], s.GroupID, s.PlanID,
            s.CoverID, s.LastName, s.FirstName, s.MiddleInitial,
            [LastName] + ', ' + [FirstName] + ' ' + SUBSTRING([MiddleInitial],
                                                              1, 1) AS LU_Name,
            s.Street1, s.Street2, s.City, s.[State], s.Zip,
            ISNULL(PhoneHome, '') SubPhoneHome, s.PhoneWork, s.DOB,
            s.DepCnt, s.Gender, s.Age, s.EffectiveDate,
            s.PreexistingDate, s.MaritalStatus, s.CardPrinted,
            s.CardPrintedDate, s.MembershipStatus, s.DateCreated,
            s.DateChanged, s.DateDeleted, 
            r.RateID,
            CASE WHEN s.CoverId = 1 THEN 'I'
                 WHEN s.CoverId = 2 THEN 'O'
                 ELSE 'F'
            END AS SUBcoverage, 
            CASE WHEN s.CoverId = 1 THEN '1S'
                 WHEN s.CoverId = 2 THEN '1S1'
                 ELSE '1SF'
            END SUBplanIDin, 
            s.EffectiveDate, s.EmploymentDate,
            s.EIMBRID, s.wSubID, 1 AS setU, s.AmtPaid
        FROM
            tblSubscriber_temp s
				INNER JOIN tblRates r
					ON s.CoverId = r.CoverID
					AND s.PlanId = r.PlanID
					AND s.GroupId = r.PlanId
        WHERE
            ( ( s.MembershipStatus ) = 'Added'
              OR s.MembershipStatus = 'Changed'
            )
            AND ( s.EIMBRID IN ( 'INDIV' ) );
GO
