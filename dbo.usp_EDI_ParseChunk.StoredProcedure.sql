USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_ParseChunk]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_EDI_ParseChunk](
      @FileID uniqueidentifier,
      @EDI varchar(max),
      @ChunkNum int
)

as

set nocount on

begin

declare @Level int,
        @Separator varchar(max),
        @IdentifierType varchar(max),
        @RowID int,
        @LastRowID int,
        @EntryID uniqueidentifier,
        @RecordType varchar(max),
        @Value varchar(max)

set @Level = 1

create table #EDI_Parse (RowID int identity(1, 1),
                         FileID uniqueidentifier,
                         ParentID uniqueidentifier,
                         EntryID uniqueidentifier default (newid()),
                         ChunkNum int,
                         [Level] int,
                         Seq int,
                         [Value] varchar(max),
                         RecordType varchar(20),
                         EntitySeq int)

insert into #EDI_Parse (FileID, ChunkNum, [Level], Seq, Value)
values (@FileID, @ChunkNum, 0, @ChunkNum, @EDI)

while exists (select 1
                from EDI_ParseIdentifier
               where FileID = @FileID
                 and @Level <= [Level])
  begin
    select @Separator = pei.[Value],
           @IdentifierType = ei.IdentifierType
      from EDI_ParseIdentifier pei
      join EDI_Identifier ei
        on pei.IdentifierID = ei.IdentifierID
     where pei.FileID = @FileID
       and pei.[Level] = @Level

    select @LastRowID = (select max(RowID) from #EDI_Parse where RowID > isnull(@LastRowID, 0))
    
    while isnull(@RowID, 0) < @LastRowID
      begin
        select @RowID = (select min(RowID) from #EDI_Parse where RowID > isnull(@RowID, 0))
        
        select @EntryID = EntryID,
               @RecordType = RecordType,
               @Value = [Value]
          from #EDI_Parse
         where RowID = @RowID

        insert into #EDI_Parse (FileID, ChunkNum, ParentID, [Level], Seq, [Value], RecordType)
        select @FileID, @ChunkNum, @EntryID, @Level, si.id - 1, si.item, @RecordType
          from dbo.udf_SplitItems(@Value, @Separator) si
         where @Value != si.item
           -- remove record types -- they're recorded separately
           and not (@IdentifierType = 'Field'
                and si.id = 1)
      end

    if @IdentifierType = 'Component'
      begin
        update pe
           set pe.RecordType = substring(pe.Value, 1, charindex(pei_Field.Value, pe.Value, 1) - 1)
          from EDI_ParseIdentifier pei_Component
          join EDI_Identifier ei_Component
            on pei_Component.IdentifierID = ei_Component.IdentifierID
          join EDI_ParseIdentifier pei_Field
            on pei_Component.FileID = pei_Field.FileID
          join EDI_Identifier ei_Field
            on pei_Field.IdentifierID = ei_Field.IdentifierID
          join #EDI_Parse pe
            on pei_Component.FileID = pe.FileID
           and pei_Component.[Level] = pe.[Level]
         where pei_Component.FileID = @FileID
           and ei_Component.IdentifierType = 'Component'
           and ei_Field.IdentifierType = 'Field'
      end

    set @Level = @Level + 1
  end

declare @cnt int,
        @msg varchar(max)

set @cnt = 31

while (@cnt > 0)
  begin
    set @cnt = @cnt - 1

    begin try
      insert into EDI_Parse (FileID, ParentID, EntryID, ChunkNum, [Level], Seq, [Value], RecordType, EntitySeq)
      select FileID, ParentID, EntryID, ChunkNum, [Level], Seq, [Value], RecordType, EntitySeq
        from #EDI_Parse
      
      set @cnt = 0
    end try
    begin catch
      if error_number() != 1205
        begin
          set @msg = error_message()
          raiserror(@msg, 16, 1)
        end
    end catch
  end

drop table #EDI_Parse

end
GO
