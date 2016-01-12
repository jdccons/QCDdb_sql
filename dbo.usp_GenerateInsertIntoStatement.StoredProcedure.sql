USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateInsertIntoStatement]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tomaž Kaštrun
-- Place:       Kranjska Gora, Slovenija
-- Creation date: 20100606
-- Description:	Procedure generates INSERT code to populate 
--              empty table from an existing one
-- Usage:       See below comment tag
/*

USAGE:
exec usp_GenerateInsertIntoStatement
		 @Table = 'MyTable'
		,@SelectList = 'Column1', Column2'
		,@NOfRows = 10
		,@RandomValues = 'N'

    
*/
-- =============================================

CREATE PROCEDURE [dbo].[usp_GenerateInsertIntoStatement]



(
	 @Table nvarchar(100)              --TABLE NAME
	,@SelectList nvarchar(100)  = '*'  --COLUMNS SEPARATED BY COMMA; DEFAULT VALUE = * /ALL COLUMNS
	,@NOfRows int  = 100			   --NUMBER OF ROWS; DEFAULT VALUE = 100 
	,@RandomValues nvarchar(2) = 'N'   --RETURN RANDOM ORDERED ROWS; DEFAULT VALUE = N /ORDER BY PHYSICAL ORDER
)


AS

SET NOCOUNT ON

-- 1.STEP
-- CREATE TEMPORARY TABLE FOR STORED PROCEDURE PURPOSES TO 
-- HOLD DATA FROM PASSED PARAMETERS
declare @table2 nvarchar(100)
set @Table2 = @Table

if exists ( select * from sys.objects where object_id = object_id (N'GIIS'))
drop table dbo.GIIS

declare @SqlStatement nvarchar(1000)

IF @RandomValues = 'N'
   set @SqlStatement = 'select top '+ cast(@NOfRows as varchar(10)) + @SelectList+ ' into GIIS from ' +@Table2
else
   set @SqlStatement = 'select top '+ cast(@NOfRows as varchar(10)) + @SelectList+ ' into GIIS from ' +@Table2 
       + ' order by newid()' 

execute SP_executesql @SqlStatement


-- COMMENT THIS IF YOU DO NOT WANT TO SEE RESULTS OF EXPORT
-- select * from dbo.GIIS
-- COMMENT THIS IF YOU DO NOT WANT TO SEE RESULTS OF EXPORT

set @Table = 'GIIS'

declare @SqlCreate nvarchar(1000)
declare @CT_min int 
declare @CT_max int
declare @CT_column_name nvarchar(100)
declare @CT_data_type nvarchar(100)
declare @CT_character_maximum_length nvarchar(50)

select @CT_min = min(ordinal_position) from information_schema.columns where table_name = @Table
select @CT_max = max(ordinal_position) from information_schema.columns where table_name = @Table

--DROP PREVIOUSLY CREATED TBL_TALLY TABLE 
if exists (Select * from sys.objects where object_id = object_id(N'TBL_Tally'))
drop table TBL_Tally

-- 1. DYNAMICALLY CREATES TBL_TALLY TABLE SCRIPT WITH LEADING IDENTITY COLUMN
 set @SqlCreate = 'create table TBL_Tally (identiti int identity(1,1), '

while @CT_max >= @CT_min
	begin
		select @CT_column_name = column_name 
						from information_schema.columns where table_name = @Table and ordinal_position = @CT_min
		select @CT_data_type = data_type 
						from information_schema.columns where table_name = @Table and ordinal_position = @CT_min
		select @CT_character_maximum_length = isnull(character_maximum_length,0) 
						from information_schema.columns where table_name = @Table and ordinal_position = @CT_min
	
		set @SqlCreate = @SqlCreate 
								+ ' ' 
								+ quotename(@CT_column_name) 
								+ ' ' 
								+ @CT_data_type
								+ ' ('
								+ @CT_character_maximum_length
								+ '),'
		set @CT_min = @CT_min + 1
	end
	set @SqlCreate = @SqlCreate + ')'

  declare @temp table
  (SqlCreate nvarchar(1000))
  
  insert into @temp 
  select replace(replace(@SqlCreate,',)',')') ,'(0)','')
  
  select @SqlCreate = SqlCreate from @temp


	execute SP_executesql @SqlCreate

-- 2. INSERT VALUES INTO TBL_TALLY TABLE

declare @Into_TBL_Tally_Sql nvarchar(200) 
set @Into_TBL_Tally_Sql = 'insert into TBL_Tally select * From '+@Table
execute SP_ExecuteSQL @Into_TBL_Tally_Sql

--- 3.step - BEGIN
--- GENERATES INSERT INTO T-SQL CODE BASED ON TALLY TABLE

declare @table_name_v varchar(100)
set @table_name_v = 'TBL_Tally'

declare @min_v int
select @min_v = min(identiti) from TBL_Tally

declare @max_v int
select @max_v = max(identiti) from TBL_Tally

declare @text_v varchar(8000)
set  @text_v = ''

declare @column_type varchar(100)
set @column_type = ''

declare @ime_kolone varchar(100)
set @ime_kolone = ''

declare @ime_kolone_value varchar(100)
set @ime_kolone_value = ''

declare @replace_string varchar(2) 
set @replace_string = ',)'

-- 3.1. MAIN LOOP
-- LOOP GOES THROUGH ALL ROWS 
-- FROM: MIN|first TO: MAX|last
while @min_v <= @max_v
	begin
		set @text_v = 'INSERT INTO ' + @Table2 + ' ('


-- 3.2. NESTED LOOP
-- FOR EACH SELECTED ROW
-- NESTED LOOP RETURNS NAME OF ALL COLUMNS

-- VARIABLES FOR ALL COLUMNS IN TABLE
-- USING min(ordinal_position)+1 SO WE DO NOT TAKE INTO CONSIDERATION IDENTITY COLUMNS
-- DYNAMICALLY DECLARING VARIABLES WITHIN LOOP FOR DYNAMIC PASSING VALUES TO VARIABLES 
		declare @min_p int
		select @min_p = min(ordinal_position)+1 from information_schema.columns where table_name = @table_name_v

		declare @max_p int
		select @max_p = max(ordinal_position) from information_schema.columns where table_name = @table_name_v

		 while @min_p <= @max_p
			begin
				select @ime_kolone = column_name from information_schema.columns where table_name = @table_name_v
						and ordinal_position = @min_p
				set @min_p = @min_p + 1
				set @text_v = @text_v + quotename(@ime_kolone) + ','
			end

		set @text_v = @text_v + ') VALUES ('

		
-- VARIABLES FOR ALL COLUMNS IN TABLE
-- USING min(ordinal_position)+1 SO WE DO NOT TAKE INTO CONSIDERATION IDENTITY COLUMNS
-- DYNAMICALLY DECLARING VARIABLES WITHIN LOOP FOR DYNAMIC PASSING VALUES TO VARIABLES
-- USING usp_EXECUTESQL STORED PROCEDURE TO PASS THE VALUE OF PROCEDURE TO VARIABLE
		declare @min_vp int
		select @min_vp = min(ordinal_position)+1 from information_schema.columns where table_name = @table_name_v

		declare @max_vp int
		select @max_vp = max(ordinal_position) from information_schema.columns where table_name = @table_name_v

		 while @min_vp <= @max_vp
			begin
				select @ime_kolone_value = column_name from information_schema.columns where table_name = @table_name_v
						and ordinal_position = @min_vp
				
				declare @vrednost_out varchar(90)
				declare @parametri nvarchar(200)
				declare @sql as nvarchar(1000)
				
				declare @table_name nvarchar(100)
				declare @id nvarchar(10)
				declare @vrednost nvarchar(100)

				set @vrednost = @ime_kolone_value
				set @table_name = @table_name_v
				set @id = @min_v


				set @sql = 'select @vrednost_outOUT = ' + @vrednost + '  from ' + @table_name + ' where identiti = ' + @id
				set @parametri = N'@vrednost_outOUT varchar(90) OUTPUT'
				exec SP_ExecuteSQL @sql, @parametri, @vrednost_outOUT = @vrednost_out OUTPUT


				set @min_vp = @min_vp + 1
				set @text_v = @text_v + '''' + @vrednost_out + ''','
			end

		  set @text_v = @text_v + ')'

		  declare @temp2 table
		  (text_v varchar(1000))
		  
		  insert into @temp2 

		  select replace(@text_v,',)',')') 
		  
		 select @text_v = text_v from @temp2
		  print @text_v
		
		set @min_v = @min_v + 1

	end


--- 4. STEP 
-- DROP ALL TEMPORARY TABLES

-- DROP TBL_TALLY TABLE
if exists (select * from sys.objects where objecT_id = object_id(N'TBL_Tally'))
drop table dbo.TBL_Tally

-- DROP GIIS TABLE
if exists ( select * from sys.objects where object_id = object_id (N'GIIS'))
drop table dbo.GIIS
GO
