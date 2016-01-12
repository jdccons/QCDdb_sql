USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_EDI_RecordIdentifiers]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_EDI_RecordIdentifiers](
      @FileID uniqueidentifier,
      @IdentifierID uniqueidentifier,
      @Level int,
      @Value varchar(max)
)

as

set nocount on

begin

  insert into EDI_ParseIdentifier (FileID, IdentifierID, [Level], Value)
  values (@FileID, @IdentifierID, @Level, @Value)

end
GO
