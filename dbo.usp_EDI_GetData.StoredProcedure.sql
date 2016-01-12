USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_GetData]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_EDI_GetData](
      @FileID uniqueidentifier
)

with execute as owner

as

set nocount on

begin

declare @SQL nvarchar(max), @Fields nvarchar(max)

create table #Data (FileID uniqueidentifier,
                    EntitySeq int,
                    OutcomeName varchar(max),
                    FieldValue varchar(max))

--set @Fields = stuff((select ',[' + OutcomeName + ']'
--                       from EDI_SearchOutcome
--                     for xml path('')), 1, 1, space(0))

--set @SQL = N'select * from #Data pivot (max(FieldValue) for OutcomeName in (' + @Fields + N')) x'

set @SQL = N'select x.EntitySeq, ' +
           stuff((select N', [' + cast(SearchOutcomeID as nvarchar(50)) +
                         N'].[' + cast(OutcomeName as nvarchar(max)) + N']'
                    from EDI_SearchOutcome
                   order by OutcomeName
                  for xml path('')), 1, 2, space(0)) + 
           N' from (select EntitySeq from #Data group by EntitySeq) x ' +
           stuff((select N' left join (select EntitySeq, FieldValue as [' + cast(OutcomeName as nvarchar(max)) +
                         N'] from #Data where OutcomeName = ''' + cast(OutcomeName as nvarchar(max)) + N''') as [' +
                         cast(SearchOutcomeID as nvarchar(50)) + N'] on x.EntitySeq = [' + 
                         cast(SearchOutcomeID as nvarchar(50)) + N'].EntitySeq'
                from EDI_SearchOutcome
               order by OutcomeName
              for xml path('')), 1, 1, space(1)) +
           N' order by x.EntitySeq'

;with CTE as (
select pe.FileID, pe.EntitySeq, pe.RecordType, pe.ParentID,
       x.SearchID, cast(null as int) as SearchOrder, 1 as NextSearchOrder
  from EDI_Parse pe
  join (select distinct s.SearchID, sf.RecordType
          from EDI_Search s
          join EDI_SearchField sf
            on s.SearchID = sf.SearchID) x
    on pe.RecordType = x.RecordType
 where pe.FileID = @FileID
   and pe.[Level] = 1

union all

select pe.FileID, pe.EntitySeq, c.RecordType, pe.ParentID,
       sf.SearchID, sf.SearchOrder, sf.SearchOrder + 1 as NextSearchOrder
  from CTE c
  join EDI_SearchField sf
    on c.SearchID = sf.SearchID
   and c.NextSearchOrder = sf.SearchOrder
   and c.RecordType = sf.RecordType
  join EDI_Parse pe
    on c.FileID = pe.FileID
   and c.EntitySeq = pe.EntitySeq
   and sf.RecordType = pe.RecordType
   and sf.FieldSeq = pe.Seq
   and isnull(sf.FieldValue, pe.Value) = pe.Value
 where pe.[Level] >= 2)

insert into #Data (FileID, EntitySeq, OutcomeName, FieldValue)
select pe.FileID, pe.EntitySeq, so.OutcomeName, pe.Value
  from (select c.FileID, c.EntitySeq, c.SearchID, c.ParentID
          from CTE c
          join EDI_Search s
            on c.SearchID = s.SearchID
         group by c.FileID, c.EntitySeq, c.SearchID, c.ParentID, s.MatchBitmap
        having sum(distinct power(2, c.SearchOrder - 1)) = s.MatchBitmap) x
  join EDI_Parse pe
    on x.FileID = pe.FileID
   and x.EntitySeq = pe.EntitySeq
   and x.ParentID = pe.ParentID
  join EDI_SearchOutcome so
    on x.SearchID = so.SearchID
   and pe.RecordType = so.RecordType
   and pe.Seq = so.FieldSeq
 where pe.[Level] >= 2

union all

select pe.FileID, pe.EntitySeq, so.OutcomeName, pe.Value
  from EDI_Parse pe
  join EDI_SearchOutcome so
    on pe.RecordType = so.RecordType
   and pe.Seq = so.FieldSeq
  join EDI_Search s
    on so.SearchID = s.SearchID
 where pe.FileID = @FileID
   and pe.[Level] >= 2
   and isnull(s.MatchBitmap, 0) = 0

create clustered index IX_#Data on #Data (EntitySeq)

exec (@SQL)

end
GO
