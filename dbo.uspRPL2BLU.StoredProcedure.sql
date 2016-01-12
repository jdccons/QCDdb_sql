USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspRPL2BLU]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspRPL2BLU]

@SubscriberID nvarchar(11),
@EffDate nvarchar(8),
@TermDate nvarchar(8)



AS
-- add the BLU records for both the subscriber
-- and the dependents - these are the old records that
-- are being brought back
-- in this instance we need two records for each
-- person:  one QCDBLU-MNL and one QCDBLU-QCD

declare @counter int
declare @planname nvarchar(10)

set @counter = 0
while @counter < 2
begin
set @counter = @counter + 1
if @counter = 1
	select @planname = 'QCDRPL-MNL'
else 
	select @planname = 'QCDRPL-QCD'

INSERT INTO tmpExportAllAmerican ( EIRECID
, EIMBRID
, EIMBRRF
, EISBRID
, EISSN
, EINAML
, EINAMF
, EINAMM
, EIDTBR
, EISEX
, EISSNEXT
, EIADD1
, EIADD2
, EIADD3
, EICITY
, EICTY
, EISTE
, EIZIP
, EIZIP4
, EIHEMAIL
, EIWEMAIL
, EIWPHR
, EIWEXG
, EIDPT
, EIHPHR
, EIACTDB
, EICRDCR
, EIBANK
, [EIACDB#]
, EIDTEXPR
, EIGRPID
, EISGRPID
, EINMPLAN
, EIDTEFF
, EIDTCVEF
, EIDTCVEN
, EIMBRDP
, EISPC
, EIFACCN
, EIPRVCN
, EIDTPNEF
, EIDTPNEN
, EISTUSTS
, EIEXTCVG
, EITRNID
, EIDTHIRE
, EIDTTERM
, [EIPRMSC@]
, [EIPRMCL@]
, [EIDSCL@],DepID,Coverage)
SELECT tmpExportAllAmerican.EIRECID, tmpExportAllAmerican.EIMBRID, tmpExportAllAmerican.EIMBRRF, tmpExportAllAmerican.EISBRID, 
tmpExportAllAmerican.EISSN, tmpExportAllAmerican.EINAML, tmpExportAllAmerican.EINAMF, tmpExportAllAmerican.EINAMM, 
tmpExportAllAmerican.EIDTBR, tmpExportAllAmerican.EISEX, tmpExportAllAmerican.EISSNEXT, tmpExportAllAmerican.EIADD1, 
tmpExportAllAmerican.EIADD2, tmpExportAllAmerican.EIADD3, tmpExportAllAmerican.EICITY, tmpExportAllAmerican.EICTY, 
tmpExportAllAmerican.EISTE, tmpExportAllAmerican.EIZIP, tmpExportAllAmerican.EIZIP4, tmpExportAllAmerican.EIHEMAIL, 
tmpExportAllAmerican.EIWEMAIL, tmpExportAllAmerican.EIWPHR, tmpExportAllAmerican.EIWEXG, tmpExportAllAmerican.EIDPT, 
tmpExportAllAmerican.EIHPHR, tmpExportAllAmerican.EIACTDB, tmpExportAllAmerican.EICRDCR, tmpExportAllAmerican.EIBANK, 
tmpExportAllAmerican.[EIACDB#], tmpExportAllAmerican.EIDTEXPR, tmpExportAllAmerican.EIGRPID, tmpExportAllAmerican.EISGRPID, 
@planname, tmpExportAllAmerican.EIDTEFF, tmpExportAllAmerican.EIDTCVEF, tmpExportAllAmerican.EIDTCVEN, 
tmpExportAllAmerican.EIMBRDP, tmpExportAllAmerican.EISPC, tmpExportAllAmerican.EIFACCN, tmpExportAllAmerican.EIPRVCN, 
tmpExportAllAmerican.EIDTPNEF, tmpExportAllAmerican.EIDTPNEN, tmpExportAllAmerican.EISTUSTS, 
tmpExportAllAmerican.EIEXTCVG, tmpExportAllAmerican.EITRNID, tmpExportAllAmerican.EIDTHIRE, 
tmpExportAllAmerican.EIDTTERM, tmpExportAllAmerican.[EIPRMSC@], tmpExportAllAmerican.[EIPRMCL@], tmpExportAllAmerican.[EIDSCL@]
,tmpExportAllAmerican.DepID, tmpExportAllAmerican.Coverage
FROM tmpExportAllAmerican
WHERE (((tmpExportAllAmerican.EISBRID)= @SubscriberID ) AND ((tmpExportAllAmerican.EINMPLAN)='QCDBLU-MNL'))
end

-- term the red plus coverages
UPDATE tmpExportAllAmerican
SET EIDTCVEN = @TermDate
WHERE ((tmpExportAllAmerican.EISBRID)= @SubscriberID ) 
AND (SubString(tmpExportAllAmerican.EINMPLAN, 4,3) = 'RPL')

-- the new blue records are already there
-- through previous processes
-- need to update the effective date field
-- with the new effective date for the BLU plan
UPDATE tmpExportAllAmerican
SET EIDTCVEF = @EffDate
WHERE ((tmpExportAllAmerican.EISBRID)= @SubscriberID ) 
AND (SubString(tmpExportAllAmerican.EINMPLAN, 4,3) = 'BLU')
GO
