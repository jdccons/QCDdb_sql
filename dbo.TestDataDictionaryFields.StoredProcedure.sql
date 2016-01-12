USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[TestDataDictionaryFields]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TestDataDictionaryFields]
AS 
    SET NOCOUNT ON
    DECLARE @RecordCount INT
    DECLARE @FieldList TABLE
        (
          SchemaName sysname NOT NULL,
          TableName sysname NOT NULL,
          FieldName sysname NOT NULL,
          PRIMARY KEY CLUSTERED ( SchemaName, TableName, FieldName )
        )
    EXEC dbo.PopulateDataDictionary -- Ensure the dbo.DataDictionary tables are up-to-date.
    INSERT  INTO @FieldList
            (
              SchemaName,
              TableName,
              FieldName
            )
            SELECT  SchemaName,
                    TableName,
                    FieldName
            FROM    dbo.DataDictionary_Fields
            WHERE   TableName NOT LIKE 'MSp%' -- ???
                    AND TableName NOT LIKE 'sys%' -- Exclude standard system tables.
                    AND FieldDescription = ''
    SET @RecordCount = @@ROWCOUNT
    IF @RecordCount > 0 
        BEGIN
            PRINT ''
            PRINT 'The following recordset shows the tables/fields for which data dictionary descriptions are missing'
            PRINT ''
            SELECT  LEFT(SchemaName, 15) AS SchemaName,
                    LEFT(TableName, 30) AS TableName,
                    LEFT(FieldName, 30) AS FieldName
            FROM    @FieldList
            UNION ALL
            SELECT  '',
                    '',
                    '' -- Used to force a blank line
            RAISERROR ( '%i field(s) lack descriptions', 16, 1, @RecordCount )
                WITH NOWAIT
        END
GO
