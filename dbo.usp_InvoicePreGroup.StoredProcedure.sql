USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicePreGroup]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InvoicePreGroup]
    (
      @InvoiceDate AS DATETIME ,
      @GroupType AS NVARCHAR(12)
    )
AS /* =============================================
	Object:			usp_InvoicePreGroup
	Author:			John Criswell
	Version:		3
	Create date:	9/8/2014	 
	Description:	Creates bulk invoices for groups;
					inserts records into staging tables;
					transaction numbers are assigned in
					this stage to each invoice - one for
					each group.  Group invoices are first
					inserted into tblInvHdrPreliminary
					and then into tblInvHdr.
					Subscribers for each group
					are inserted into tblInvLin along with
					their dependents				  
					
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2014-09-22		JCriswell		Changed approach on generating
									NextTranNos
	2015-01-03		JCriswell		Added a where clause to subscriber
									section.  Where clause is SubCancelled != 3.
									Changed frmGrpSubscr so that deleted subscribers
									are now marked as cancelled instead of a record
									deletion.
	2015-01-20		JCriswell		Added where clause to generate new trans nos
									i.e. where CustomerClassKey = 'GROUP'
	
============================================= */

 /*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT   
    
    
    DECLARE @TranNo AS INTEGER 
    DECLARE @NextTranNo AS INTEGER             
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION
		
        SELECT  @LastOperation = 'generate new tran nos - one for each group'
		
        SET @TranNo = ( SELECT dbo.udf_GetNextTranNo() )
		
        IF OBJECT_ID('tempdb..#TranNo') IS NOT NULL 
            DROP TABLE #TranNo
        
        SELECT IDENTITY( INT,1,1 ) AS [ID], @TranNo AS TranNo, 0 AS NextTranNo,
                CustKey
            INTO #TranNo
            FROM ( SELECT CustomerKey AS CustKey
                    FROM vw_Customer
                    WHERE RTRIM(Spare3) = RTRIM(@GroupType)
                        AND CreditHold = 'N'
                        AND CustomerClassKey = 'GROUP'
                 ) g;

        UPDATE a
            SET NextTranNo = ( b.TranNo + b.Id )
            FROM #TranNo a 
            INNER JOIN #TranNo b
                ON a.Id = b.Id; 
                
        SELECT  @LastOperation = 'save NextTranNo';
        
        IF EXISTS ( SELECT 1 FROM #TranNo ) 
            BEGIN
                SELECT  @NextTranNo = MAX(NextTranNo)
                    FROM #TranNo
		        
                UPDATE dbo.ARONE_R9_local
                    SET NextTransaction = @NextTranNo + 1
            END
		
        SELECT  @LastOperation = 'insert customers into tblInvHdrPreliminary from tblGrp ';
		--inserts records into temp table - tblInvHdrPreliminary
        TRUNCATE TABLE dbo.tblInvHdrPreliminary;		
        INSERT INTO tblInvHdrPreliminary ( Custkey, Custname, Custaddr1,
                                           Custaddr2, Custcity, Custstate,
                                           Custzip, Tranno, Invdate, Custclass,
                                           Territkey, Salespkey, Spare, Spare2,
                                           Spare3, RecUserID, RecDate, RecTime )
                SELECT c.CustomerKey AS Custkey,
                        ISNULL(c.CustomerName, N'') AS Custname,
                        ISNULL(c.CustomerAddress1, N'') AS Custaddr1,
                        ISNULL(c.CustomerAddress2, N'') AS Custaddr2,
                        ISNULL(c.CustomerCity, N'') AS Custcity,
                        ISNULL(c.CustomerState, N'') AS Custstate,
                        ISNULL(c.CustomerZipCode, N'') AS Custzip,
                        tn.NextTranNo, @InvoiceDate AS InvoiceDte,
                        c.CustomerClassKey AS Custclass,
                        ISNULL(c.TerritoryKey, N'') AS SubGeoId,
                        ga.AGENTid AS AgentID, 
                        '' AS Spare,	-- SubID (not at this level) 
                        '' AS Spare2,	--SubSSN (not at this level)
                        c.Spare3,		--group type
                        'QCD db' AS RecUser,
                        CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
                        LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
                        AS RecTime
                    FROM vw_Customer AS c
                    LEFT OUTER JOIN vw_GrpAgt ga
                        ON c.CustomerKey = ga.GroupID 
                    INNER JOIN #TranNo tn
                        ON c.CustomerKey = tn.CustKey
                    WHERE ga.[Level] = 1;
                
        SELECT  @LastOperation = 'insert data into header staging table ';  
		--inserts records into tblInvHdr from tblInvHdrPreliminary for each subscriber in the group   
		
		DELETE FROM tblInvHdr;   
        
        INSERT INTO tblInvHdr ( [CUST KEY], [CUST NAME], [ADDRESS 1],
                                [ADDRESS 2], CITY, [STATE], [ZIP CODE],
                                ATTENTION, [TRANS NO], [INV DATE], [CHECK NO],
                                [CHECK AMTR], [TERRITORY KEY], [SALESP    KEY],
                                [CUST CLASS], SPARE, SPARE2, SPARE3,
                                [INVOICE NO], RecUserID, RecDate, RecTime,
                                SYSDOCID )
                SELECT Custkey, Custname, Custaddr1, Custaddr2, Custcity,
                        Custstate, Custzip, CustAttn,
                        SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10,
                                  1) + CONVERT(NVARCHAR(9), Tranno) AS [Trans No],
                        @InvoiceDate AS Invdate, Checkno, Checkamt, Territkey,
                        Salespkey, Custclass, Spare, Spare2, Spare3,
                        SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10,
                                  1) + CONVERT(NVARCHAR(9), Tranno) AS [INVOICE NO],
                        'QCD db' AS RecUser,
                        CONVERT(VARCHAR(10), GETDATE(), 101) AS RecDate,
                        LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7))
                        AS RecTime, Sysdocid
               FROM tblInvHdrPreliminary;
                    
        SELECT  @LastOperation = 'insert subscribers into line item staging table ';     
		--creates records in tblInvLin for each subscriber in the group
        INSERT INTO tblInvLin ( LineItemTy, [DOCUMENT NO], [CUST KEY],
                                [ITEM KEY], [DESCRIPTION], [QTY ORDERED],
                                [QTY SHIPPED], [REV ACCT], [REV SUB],
                                [UNIT PRICE], SPARE, SPARE2, SPARE3 )
                SELECT '1' AS LineItemType,
                        SUBSTRING(CONVERT(NVARCHAR(10), @InvoiceDate, 101), 10,
                                  1) + CONVERT(NVARCHAR(9), ihp.Tranno) AS [DOCUMENT NO],
                        s.SubGroupID AS [CUST KEY], s.SubSSN AS [ITEM KEY],
                        s.SUB_LUname AS [Description], 1 AS QtyOrdered,
                        1 AS QtyShipped, '5100' AS Acct, '2000' AS Dept,
                        r.Rate, 
                        s.SubID AS Spare,        -- SubID 
                        s.SubSSN AS Spare2,      -- SubSSN
                        ihp.Spare3               -- GroupType
                    FROM tblSubscr AS s
                    INNER JOIN tblInvHdrPreliminary AS ihp
                        ON s.SubGroupID = ihp.Custkey 
                    INNER JOIN tblRates AS r
                        ON s.RateID = r.RateID
                    WHERE s.SubCancelled != 3;
                       
        SELECT  @LastOperation = 'insert dependents in line item staging table ';                 
		--creates dependent records in tblInvLin for each group subscriber
        INSERT INTO tblInvLin ( LineItemTy, [DOCUMENT NO], [CUST KEY],
                                [ITEM KEY], [DESCRIPTION], [QTY ORDERED],
                                [QTY SHIPPED], [UNIT PRICE], [REV ACCT],
                                [REV SUB], SPARE, SPARE2, SPARE3 )
                SELECT CONVERT(NVARCHAR(2), CONVERT(INTEGER, RANK() OVER ( PARTITION BY s.spare ORDER BY RTRIM(COALESCE(NULLIF(RTRIM(d.[DepLastName]),
                                                              '') + ', ', '')
                                                              + COALESCE(NULLIF(RTRIM(d.[DepFirstName]),
                                                              '') + ' ', '')
                                                              + COALESCE(d.[DepMiddleName],
                                                              '')) )) + 1) AS LineItemType,
                        s.[DOCUMENT NO], s.[CUST KEY],
                        ISNULL(d.DepSSN, N'') AS [ITEM KEY],
                        RTRIM(COALESCE(NULLIF(RTRIM(d.DepLastName), N'')
                                       + ', ', N'')
                              + COALESCE(NULLIF(RTRIM(d.DepFirstName), N'')
                                         + ' ', N'')
                              + COALESCE(d.DepMiddleName, N'')) AS [DESCRIPTION],
                        1 AS QtyOrdered, 1 AS QtyShipped, 0 AS [UNIT PRICE],
                        '5100' AS Acct, '2000' AS Dept, 
                        s.SPARE,			--SubID
                        s.SPARE2,			--SubSSN
                        s.SPARE3			--GroupType
                    FROM tblInvLin AS s 
						INNER JOIN tblDependent AS d
							ON s.SPARE = d.SubID;
                        
        COMMIT TRANSACTION
    END TRY

    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK

        SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
                + @LastOperation, @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE()
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Creates bulk invoices for groups.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_InvoicePreGroup'
GO
