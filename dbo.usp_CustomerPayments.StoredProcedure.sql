USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_CustomerPayments]    Script Date: 01/11/2016 21:18:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_CustomerPayments](@CheckDate DATETIME)
AS
/* =============================================
	Object:			usp_CustomerPayments
	Version:		7
	Author:			John Criswell
	Create date:	2014-09-16	 
	Description:	Pulls new "receive payments" from QuickBooks
					and populates ARTRANH_local.  
					
	Parameters:		@CheckDate datetime						
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2014-09-17		JCriswell		Added the vw_GrpAgt view in order to 
									pull the AgentId as SalesPersonKey
									for the group; includes a where
									to pull only the level 1 Agent
	2014-09-25		JCriswell		Added invoice type as Spare3
	
============================================= */

/*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT 
        
    DECLARE @SysDocID AS INTEGER
      
------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION

        SELECT  @LastOperation = 'create SysDocIds'

		/*  generate SysDocIds  */
		SET @SysDocID = ( SELECT    dbo.udf_GetNextSysDocID()
						)
		IF OBJECT_ID('tempdb..#SysDoc') IS NOT NULL
			DROP TABLE #SysDoc
		
		/*  this left outer join insures that only
		    new payments get processed.  */    
		SELECT  IDENTITY( INT,1,1 ) AS [ID] ,
				@SysDocID SysDocID ,
				0 AS NextSysDocID ,
				TxnId
		INTO    #SysDoc
		FROM    vw_CustomerPayments cp
					LEFT OUTER JOIN ARTRANH_local art  
						ON cp.TxnId = art.OrderNumber
		WHERE   MONTH(cp.DocumentDate) = MONTH(@CheckDate)
				AND YEAR(cp.DocumentDate) = YEAR(@CheckDate)
				AND art.OrderNumber IS NULL
		ORDER BY cp.TxnID
			
		UPDATE a
		SET NextSysDocID  = (b.SysDocId + b.Id)
		FROM #SysDoc a
		INNER JOIN #SysDoc b
			ON a.ID = b.ID
			
			
        IF EXISTS ( SELECT  1
                    FROM    #SysDoc )	
			/*  save the last SysDocID */ 
            UPDATE  dbo.ARNEXTSY_local
            SET     NextSysDocID = ( SELECT MAX(NextSysDocID)
                                     FROM   #SysDoc
                                   )

		SELECT  @LastOperation = 'create SysDocIds'
		/* populate ARTRANH_local */
		INSERT  INTO ARTRANH_local
				( DocumentNumber ,
				  TerritoryKey ,
				  SalespersonKey ,
				  CustomerKey ,
				  CustomerClassKey ,
				  OrderNumber ,
				  TransactionType ,
				  DocumentDate ,
				  DocumentAmt ,
				  SysDocID ,
				  Spare,
				  Spare2,
				  Spare3,
				  RecUserID ,
				  RecDate ,
				  RecTime
				)
				SELECT  cp.DocumentNumber ,
						c.TerritoryKey ,
						ga.AgentId SalespersonKey ,
						cp.CustomerKey ,
						cp.CustomerClassKey ,
						cp.TxnID OrderNumber ,
						cp.TransactionType ,
						cp.DocumentDate ,
						cp.DocumentAmt ,
						sd.NextSysDocID AS SysDocId ,
						c.Spare,
						c.Spare2,
						cp.Spare3,
						cp.RecUser ,
						cp.RecDate ,
						cp.RecTime
				FROM    vw_CustomerPayments cp
					INNER JOIN #SysDoc sd
						ON cp.TxnID = sd.TxnId
					LEFT OUTER JOIN vw_Customer c  -- provides TerritoryKey
						ON cp.CustomerKey = c.CustomerKey
					LEFT OUTER JOIN dbo.vw_GrpAgt ga  -- provides SalesPersonKey
						ON cp.CustomerKey = ga.GroupId
				WHERE   MONTH(DocumentDate) = MONTH(@CheckDate)
				AND YEAR(DocumentDate) = YEAR(@CheckDate)
				AND ga.Level = 1;
				
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH 
		IF @@TRANCOUNT > 0 
			ROLLBACK

		SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
				+ @LastOperation ,
				@ErrorSeverity = ERROR_SEVERITY() ,
				@ErrorState = ERROR_STATE()
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Pulls new receive payments from QuickBooks and populates ARTRANH_local..' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_CustomerPayments'
GO
