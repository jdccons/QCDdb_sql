USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[TestDataDictionaryTables]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TestDataDictionaryTables]
AS 
    SET NOCOUNT ON
    DECLARE @TableList TABLE
        (
          SchemaName sysname NOT NULL,
          TableName sysname NOT null
          PRIMARY KEY CLUSTERED ( SchemaName, TableName )
        )
    DECLARE @RecordCount INT
    EXEC dbo.PopulateDataDictionary -- Ensure the dbo.DataDictionary tables are up-to-date.
    INSERT  INTO @TableList ( SchemaName, TableName )
            SELECT  SchemaName,
                    TableName
            FROM    dbo.DataDictionary_Tables
            WHERE   TableName NOT LIKE 'MSp%' -- ???
                    AND TableName NOT LIKE 'sys%' -- Exclude standard system tables.
                    AND TableDescription = ''
    SET @RecordCount = @@ROWCOUNT
    IF @RecordCount > 0 
        BEGIN
            PRINT ''
            PRINT 'The following recordset shows the tables for which data dictionary descriptions are missing'
            PRINT ''
            SELECT  LEFT(SchemaName, 15) AS SchemaName,
                    LEFT(TableName, 30) AS TableName
            FROM    @TableList
            UNION ALL
            SELECT  '',
                    '' -- Used to force a blank line
            RAISERROR ( '%i table(s) lack descriptions', 16, 1, @RecordCount )
                WITH NOWAIT
        END
GO
