USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_FinishFile]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_EDI_FinishFile](
      @FileID uniqueidentifier
)

as

/* ================================================================
  Object:			usp_EDI_FinishFile
  Author:			Ryan Wicks
  Create date:		2012-10-15 
  Description:		Processes data from HIPAA ANSI 834 5010 file
					
					
  Parameters:		FileID uniqueidentifer
  Where Used:		F:\EDI\QCDProcessEDI.exe
					
				
  Change Log:
  -----------------------------------------------------------------
  Change Date		Version		Changed by		Reason
  2012-10-15		1.0			RWicks			Created	
	
	
=================================================================== */

set nocount on

begin

declare @BegSeq int, @EndSeq int, @Lvl int

update pe
   set pe.Seq = x.NewSeq
  from EDI_Parse pe
  join (select pe.EntryID,
               row_number() over (Order by pe.ChunkNum, pe.Seq) as NewSeq
          from EDI_Parse pe
          join EDI_ParseIdentifier pei
            on pe.FileID = pei.FileID
           and pe.[Level] = pei.[Level]
          join EDI_Identifier ei
            on pei.IdentifierID = ei.IdentifierID
         where pe.FileID = @FileID
           and ei.IdentifierType = 'Component') x
    on pe.EntryID = x.EntryID

select @BegSeq = (select min(Seq)
                    from EDI_Parse
                   where FileID = @FileID
                     and RecordType = 'INS'
                     and [Level] = 1),
       @EndSeq = (select min(Seq) - 1
                    from EDI_Parse
                   where FileID = @FileID
                     and RecordType = 'SE'
                     and [Level] = 1)

update pe
   set pe.EntitySeq = x.EntitySeq
  from EDI_Parse pe
  join (select pe1.FileID, pe1.[Level], pe1.Seq,
               isnull((select min(pe2.Seq) - 1
                         from EDI_Parse pe2
                        where pe1.FileID = pe2.FileID
                          and pe1.[Level] = pe2.[Level]
                          and pe1.RecordType = pe2.RecordType
                          and pe1.Seq < pe2.Seq),
                      (select max(pe3.Seq)
                         from EDI_Parse pe3
                        where pe1.FileID = pe3.FileID
                          and pe1.[Level] = pe3.[Level]
                          and pe3.Seq <= @EndSeq)) as LastSeq,
               row_number() over (Order by pe1.Seq) as EntitySeq
          from EDI_ParseIdentifier pei
          join EDI_Identifier ei
            on pei.IdentifierID = ei.IdentifierID
          join EDI_Parse pe1
            on pei.FileID = pe1.FileID
           and pei.[Level] = pe1.[Level]
         where pei.FileID = @FileID
           and ei.IdentifierType = 'Component'
           and pe1.RecordType = 'INS'
           and pe1.Seq between @BegSeq and @EndSeq) x
    on pe.FileID = x.FileID
   and pe.[Level] = x.[Level]
   and pe.Seq between x.Seq and x.LastSeq
 where pe.FileID = @FileID

update EDI_Parse
   set EntitySeq = 0
 where EntitySeq is null
   and [Level] = 1

set @Lvl = 1

while exists (select 1 from EDI_ParseIdentifier where [Level] >= @Lvl and FileID = @FileID)
  begin
    update pe2
       set pe2.EntitySeq = pe1.EntitySeq
      from EDI_Parse pe1
      join EDI_Parse pe2
        on pe1.EntryID = pe2.ParentID
     where pe1.[Level] = @Lvl

    set @Lvl = @Lvl + 1
  end

update EDI_ParseFile
   set ChunkCnt = (select count(EntryID) from EDI_Parse where FileID = @FileID and [Level] = 0),
       ComponentCnt = (select count(EntryID) from EDI_Parse where FileID = @FileID and [Level] = 1),
       FieldValueCnt = (select count(EntryID) from EDI_Parse where FileID = @FileID and [Level] = 2),
       TotalRecordCnt = (select count(EntryID) from EDI_Parse where FileID = @FileID),
       LoadCompleted = getdate()
 where FileID = @FileID

end
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Processes data from HIPAA ANSI 834 5010 file.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_EDI_FinishFile'
GO
