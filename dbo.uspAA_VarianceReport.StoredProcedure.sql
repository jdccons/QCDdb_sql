USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspAA_VarianceReport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[uspAA_VarianceReport]

as

truncate table tmpAA_VarianceReport

-- Step 1 different SSN
insert into tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
SubSSN, 
AAGrpID, 
NewValue, 
OldValue, 
RptDate )
SELECT 5 AS Ord, 
'Subscriber Change' AS Title, 
'Sub Change SSN' AS Elem, 
tblSubscr.SUBssn, 
AA_Changed_SSNs.GRPid, 
AA_Changed_SSNs.[EISSN#] AS AA, 
tblSubscr.SUBssn AS QCD, 
AA_Changed_SSNs.RptDate
FROM AA_Changed_SSNs INNER JOIN tblSubscr 
	ON AA_Changed_SSNs.AA_SSN = tblSubscr.SUBssn;

-- Step 2 different group
INSERT INTO tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
SubSSN, 
AAGrpID, 
NewValue, 
OldValue, 
RptDate )
SELECT 10 AS Ord, 
'Subscriber Change' AS Title, 
'Sub Group ID' AS Elem, 
tblSubscr.SUBssn, 
AA_Subscr.GRPid, 
UPPER([GRPid]) AS AA, 
UPPER([SUBgroupID]) AS QCD, 
AA_Subscr.RptDate
FROM AA_Subscr 
	INNER JOIN tblSubscr 
ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBgroupID]))<>UPPER([GRPid]))) 
OR (((UPPER([GRPid]))<>UPPER([SUBgroupID])));

-- Step 2a different plan
INSERT INTO tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
SubSSN, 
AAGrpID, 
RptDate, 
NewValue, 
OldValue )
SELECT 12 AS Ord, 
'Subscriber Change' AS Title, 
'Plan Change' AS Elem, 
tblSubscr.SUBssn, 
AA_Subscr_Rates.GrpID, 
AA_Subscr_Rates.RptDate, 
tblPlans.PlanDesc AS AAPlan, 
tblPlans_1.PlanDesc AS QCDPlan
FROM AA_Subscr_Rates 
INNER JOIN tblSubscr ON AA_Subscr_Rates.AA_SSN = tblSubscr.SUBssn 
INNER JOIN tblPlans ON AA_Subscr_Rates.PlanID = tblPlans.PlanID 
INNER JOIN tblPlans AS tblPlans_1 ON tblSubscr.PlanID = tblPlans_1.PlanID
WHERE (tblSubscr.PlanID <> AA_Subscr_Rates.PlanID) 
OR (AA_Subscr_Rates.PlanID <> tblSubscr.PlanID)

-- Step 2b different coverage
INSERT INTO tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
SubSSN, 
AAGrpID, 
RptDate, 
NewValue, 
OldValue )
SELECT     
14 AS Ord, 
'Subscriber Change' AS Title, 
'Coverage Change' AS Elem, 
tblSubscr.SUBssn, 
AA_Subscr_Rates.GrpID, 
AA_Subscr_Rates.RptDate, 
tblCoverage.COVERdescr AS AACoverage, 
tblCoverage_1.COVERdescr AS QCDCoverage
FROM AA_Subscr_Rates 
INNER JOIN tblSubscr ON AA_Subscr_Rates.AA_SSN = tblSubscr.SUBssn 
INNER JOIN tblCoverage ON AA_Subscr_Rates.CoverID = tblCoverage.CoverID 
INNER JOIN tblCoverage AS tblCoverage_1 ON tblSubscr.CoverID = tblCoverage_1.CoverID
WHERE (tblSubscr.CoverID <> AA_Subscr_Rates.CoverID) OR
(AA_Subscr_Rates.CoverID <> tblSubscr.CoverID)

-- Step 3 different rate
INSERT INTO tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
SubSSN, 
AAGrpID, 
RptDate, 
NewValue, 
OldValue )
SELECT 
18 AS Ord, 
'Subscriber Change' AS Title, 
'Sub Rate Change' AS Elem, 
tblSubscr.SUBssn, 
AA_Subscr_Rates.GRPid, 
AA_Subscr_Rates.RptDate, 
convert(nvarchar(10),AA_Subscr_Rates.Rate) AS AA, 
convert(nvarchar(10),tblRates.Rate) AS QCD
FROM AA_Subscr_Rates 
INNER JOIN tblSubscr ON AA_Subscr_Rates.AA_SSN = tblSubscr.SUBssn
INNER JOIN tblRates ON tblSubscr.RateID = tblRates.RateID
WHERE (((tblRates.Rate)<>AA_Subscr_Rates.rate)) OR (((AA_Subscr_Rates.Rate)<>tblRates.Rate));

-- Step 5 different first name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 20 AS Ord, 'Subscriber Change' AS Title, 'Sub First Name' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EINAMF]) AS AA, UPPER([SUBfirstNAME]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBfirstNAME]))<>UPPER([EINAMF]))) OR (((UPPER([EINAMF]))<>UPPER([SUBfirstNAME])));

-- Step 6 different last name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 25 AS Ord, 'Subscriber Change' AS Title, 'Sub Last Name' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EINAML]) AS AA, UPPER([SUBlastNAME]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBlastNAME]))<>UPPER([EINAML]))) OR (((UPPER([EINAML]))<>UPPER([SUBlastNAME])));

-- Step 7 different middle name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 30 AS Ord, 'Subscriber Change' AS Title, 'Sub Middle Init' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER(Left([EINAMM],1)) AS AA, UPPER([SUBmiddleNAME]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBmiddleNAME]))<>UPPER(Left([EINAMM],1)))) OR (((UPPER(Left([EINAMM],1)))<>UPPER([SUBmiddleNAME])));

-- Step 8 different date of birth
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 35 AS Ord, 'Subscriber Change' AS Title, 'Sub DOB' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
(Left([EIDTBR],2) + '/' +  substring([EIDTBR],3,2) + '/' + Right([EIDTBR],4)) AS AA, 
tblSubscr.SUBdob AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (Left([EIDTBR],2) + '/' +  substring([EIDTBR],3,2) + '/' + Right([EIDTBR],4))<>[SUBdob] 
OR tblSubscr.SUBdob<>(Left([EIDTBR],2) + '/' +  substring([EIDTBR],3,2) + '/' + Right([EIDTBR],4));

-- Step 9 different gender
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 40 AS Ord, 'Subscriber Change' AS Title, 'Sub Gender' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EISEX]) AS AA, UPPER([SUBGender]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBGender]))<>UPPER([EISEX]))) OR (((UPPER([EISEX]))<>UPPER([SUBGender])));

-- Step 10 different preexisting date
insert into tmpAA_VarianceReport ( 
PrtOrder, 
DataElementTitle, 
DataElement, 
AAGrpID, 
SubSSN, 
NewValue, 
OldValue, 
RptDate )
select 45 as Ord, 'Subscriber Change' as DataElementTitle, 'Sub Prior Coverage Date' as DataElement, 
       x.GrpID, s.SubSSN, 
       left(x.EIDTCVEF, 2) + '/' + substring(x.EIDTCVEF, 3, 2) + '/' + right(x.EIDTCVEF, 4) as AACoverEffDt, 
       convert(nvarchar, s.PreexistingDate, 101) as QCDPreExistDt,
       x.RptDate 
from   tblSubscr as s 
       inner join AA_Subscr_PreexistingDate as x 
         on s.SubSSN = x.AA_SSN 
where  ( s.PreexistingDate <> left(x.EIDTCVEF, 2) + '/' + substring(x.EIDTCVEF, 3, 2) + '/' + right(x.EIDTCVEF, 4) ) 
        or ( s.PreexistingDate is null ) 
        or ( left(x.EIDTCVEF, 2) + '/' + substring(x.EIDTCVEF, 3, 2) + '/' + right(x.EIDTCVEF, 4) <> s.PreexistingDate );  

-- Step 11 different address 1
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 50 AS Ord, 'Subscriber Change' AS Title, 'Sub Address 1' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EIADD1]) AS AA, UPPER([SUBstreet1]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBstreet1]))<>UPPER([EIADD1]))) OR (((UPPER([EIADD1]))<>UPPER([SUBstreet1])));

-- Step 12 different address 2
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 55 AS Ord, 'Subscriber Change' AS Title, 'Sub Address 2' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EIADD2]) AS AA, UPPER([SUBstreet2]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBstreet2]))<>UPPER([EIADD2]))) OR (((UPPER([EIADD2]))<>UPPER([SUBstreet2])));

-- Step 13 different home phone
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 60 AS Ord, 'Subscriber Change' AS Title, 'Sub Work Phone' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EIWPHR]) AS AA, UPPER([SUBphoneWORK]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBphoneWORK]))<>UPPER([EIWPHR]))) OR (((UPPER([EIWPHR]))<>UPPER([SUBphoneWORK])));

-- Step 14 different work phone
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 65 AS Ord, 'Subscriber Change' AS Title, 'Sub Work Phone' AS Elem, tblSubscr.SUBssn, AA_Subscr.GRPid, 
UPPER([EIWPHR]) AS AA, UPPER([SUBphoneWORK]) AS QCD, AA_Subscr.RptDate
FROM AA_Subscr INNER JOIN tblSubscr ON AA_Subscr.AA_SSN = tblSubscr.SUBssn
WHERE (((UPPER([SUBphoneWORK]))<>UPPER([EIWPHR]))) OR (((UPPER([EIWPHR]))<>UPPER([SUBphoneWORK])));

-- Dependent Changes
-- Step 15 different count of dependents
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID, NewValue, OldValue, RptDate )
SELECT 70 AS Ord, 'Subscriber Change' AS Title, 'Sub Count of Dependents' AS Elem, QCD_CntOfDeps.SUBssn, 
AA_CntOfDeps.GRPid, AA_CntOfDeps.Cnt, QCD_CntOfDeps.CountOfDEPsubID AS Expr1, AA_CntOfDeps.RptDate
FROM AA_CntOfDeps INNER JOIN QCD_CntOfDeps ON AA_CntOfDeps.AA_SSN = QCD_CntOfDeps.SUBssn
WHERE (((QCD_CntOfDeps.CountOfDEPsubID)<>[Cnt])) OR (((AA_CntOfDeps.Cnt)<[CountOfDEPsubID]));

-- Step 16 different first name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, AAGrpID, DataElementTitle, DataElement, SubSSN, NewValue, OldValue, RptDate )
SELECT 75 AS Ord, AA_DepInfo.GRPid, 'Dependent Change' AS Title, 'Dep First Name' AS Elem, QCD_DepInfo.SUBssn, 
UPPER([EINAMF]) AS AA, UPPER([DEPfirstNAME]) AS QCD, AA_DepInfo.RptDate
FROM AA_DepInfo INNER JOIN QCD_DepInfo ON (AA_DepInfo.[EISSN#] = QCD_DepInfo.DEPssn) AND (AA_DepInfo.AA_SSN = QCD_DepInfo.AA_SSN)
WHERE (((UPPER([DEPfirstNAME]))<>UPPER([EINAMF]))) OR (((UPPER([EINAMF]))<>UPPER([DEPfirstNAME])));

-- Step 17 different last name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, AAGrpID, DataElementTitle, DataElement, SubSSN, NewValue, OldValue, RptDate )
SELECT 78 AS Ord, AA_DepInfo.GRPid, 'Dependent Change' AS Title, 'Dep Last Name' AS Elem, QCD_DepInfo.SUBssn, 
UPPER([EINAML]) AS AA, UPPER([DEPlastNAME]) AS QCD, AA_DepInfo.RptDate
FROM AA_DepInfo INNER JOIN QCD_DepInfo ON (AA_DepInfo.[EISSN#] = QCD_DepInfo.DEPssn) AND (AA_DepInfo.AA_SSN = QCD_DepInfo.AA_SSN)
WHERE (((UPPER([DEPlastNAME]))<>UPPER([EINAML]))) OR (((UPPER([EINAML]))<>UPPER([DEPlastNAME])));

-- Step 18 different middle name
INSERT INTO tmpAA_VarianceReport ( PrtOrder, AAGrpID, DataElementTitle, DataElement, SubSSN, NewValue, OldValue, RptDate )
SELECT 84 AS Ord, AA_DepInfo.GRPid, 'Dependent Change' AS Title, 'Dep Middle Init' AS Elem, QCD_DepInfo.SUBssn, 
UPPER([EINAMM]) AS AA, UPPER([DEPmiddleNAME]) AS QCD, AA_DepInfo.RptDate
FROM AA_DepInfo INNER JOIN QCD_DepInfo ON (AA_DepInfo.[EISSN#] = QCD_DepInfo.DEPssn) AND (AA_DepInfo.AA_SSN = QCD_DepInfo.AA_SSN)
WHERE (((UPPER([DEPmiddleNAME]))<>UPPER([EINAMM]))) OR (((UPPER([EINAMM]))<>UPPER([DEPmiddleNAME])));

-- Step 19 different relationship
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, NewValue, OldValue )
SELECT 88 AS Ord, 'Dependent Change' AS Title, 'Relationship' AS Elem, QCD_DepInfo.SUBssn, 
UPPER([REL]) AS AA, UPPER([DEPrelationship]) AS QCD
FROM AA_DepInfo INNER JOIN QCD_DepInfo ON (AA_DepInfo.[EISSN#] = QCD_DepInfo.DEPssn) AND (AA_DepInfo.AA_SSN = QCD_DepInfo.AA_SSN)
WHERE (((UPPER([DEPrelationship]))<>UPPER([REL]))) OR (((UPPER([REL]))<>UPPER([DEPrelationship])));

-- Step 20 different gender
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, NewValue, OldValue )
SELECT 92 AS Ord, 'Dependent Change' AS Title, 'Gender' AS Elem, QCD_DepInfo.SUBssn, 
UPPER([EISEX]) AS AA, UPPER([DEPgender]) AS QCD
FROM AA_DepInfo INNER JOIN QCD_DepInfo ON (AA_DepInfo.[EISSN#] = QCD_DepInfo.DEPssn) AND (AA_DepInfo.AA_SSN = QCD_DepInfo.AA_SSN)
WHERE (((UPPER([DEPgender]))<>UPPER([EISEX]))) OR (((UPPER([EISEX]))<>UPPER([DEPgender])));

-- Step 21 dropped groups
INSERT INTO tmpAA_VarianceReport ( PrtOrder, DataElementTitle, DataElement, SubSSN, AAGrpID )
SELECT 99 AS Ord, 'Dropped Group' AS Title, 'Group ID' AS Elem,  tblGrp.GROUPid,  tblGrp.GROUPid 
FROM tblGrp LEFT JOIN tblAAGroups ON tblGrp.GROUPid = tblAAGroups.SUBgroupID
WHERE tblGrp.GroupType=4 AND tblAAGroups.SUBgroupID Is Null AND tblGrp.GRcancelled = 0;
GO
