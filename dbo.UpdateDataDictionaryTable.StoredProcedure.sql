USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[UpdateDataDictionaryTable]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDataDictionaryTable]
    @SchemaName sysname = N'dbo',
    @TableName sysname, 
    @TableDescription VARCHAR(7000) = '' 
AS 
    SET NOCOUNT ON
    UPDATE  dbo.DataDictionary_Tables
    SET     TableDescription = ISNULL(@TableDescription, '')
    WHERE   SchemaName = @SchemaName
            AND TableName = @TableName
    RETURN @@ROWCOUNT
GO
