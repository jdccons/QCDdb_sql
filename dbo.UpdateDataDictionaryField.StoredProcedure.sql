USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[UpdateDataDictionaryField]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDataDictionaryField]
    @SchemaName sysname = N'dbo',
    @TableName sysname, 
    @FieldName sysname, 
    @FieldDescription VARCHAR(7000) = '' 
AS 
    SET NOCOUNT ON
    UPDATE  dbo.DataDictionary_Fields
    SET     FieldDescription = ISNULL(@FieldDescription, '')
    WHERE   SchemaName = @SchemaName
            AND TableName = @TableName
            AND FieldName = @FieldName
    RETURN @@ROWCOUNT
GO
