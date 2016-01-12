USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_StartFile]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_EDI_StartFile](
      @EDIVersion char(5),
      @FilePath varchar(max),
      @FileID uniqueidentifier = null out
)

as

set nocount on

begin

  declare @ErrorMsg varchar(max)

  if not exists (select 1
                   from EDI_Version
                  where [Version] = @EDIVersion 
                    and EndDtTm is null)
    begin
      set @ErrorMsg = 'No active entries for EDI file format [' + @EDIVersion + ']'
      raiserror(@ErrorMsg, 16, 1)
    end
  else
    begin
      set @FileID = newid()

      truncate table EDI_Parse
      truncate table EDI_ParseIdentifier

      insert into EDI_ParseFile (FileID, FilePath, VersionID)
      select @FileID, @FilePath, VersionID
        from EDI_Version
       where [Version] = @EDIVersion
         and EndDtTm is null

      select i.IdentifierID, i.IdentifierType, il.[Level], i.Position, i.[Length], i.RelativeIdentifier
        from EDI_Version v
        join EDI_Identifier i on v.VersionID = i.VersionID
        join EDI_IdentifierLevel il on i.IdentifierID = il.IdentifierID
       where v.[Version] = @EDIVersion
         and v.EndDtTm is null
       order by il.[Level]
    end

end
GO
