USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_tpa_import_dep]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_tpa_import_dep ''

CREATE PROCEDURE [dbo].[usp_tpa_import_dep]
@ReturnParm VARCHAR(255) OUTPUT 
AS
/* =============================================
	Object:			usp_tpa_import_dep
	Author:			John Criswell
	Create date:	10/17/2015 
	Description:	inserts dependent records into tpa_data_exchange_dep
								
							
	Change Log:
	--------------------------------------------
	Change Date	Version		Changed by		Reason
	2015-10-17	1.0			J Criswell		Created
	2015-11-14	2.0			J Criswell		Added FK
	
============================================= */
/*  declarations  */ 
SET NOCOUNT ON;
SET XACT_ABORT ON;
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT



BEGIN TRY
   BEGIN TRANSACTION


		-- copy dependents from data exchange table to dependent data exchange table
		SELECT  @LastOperation = 'truncate tpa_data_exchange_dep'
		DELETE FROM tpa_data_exchange_dep


        SELECT
            @LastOperation = 'populate tpa_data_exchange_dep';
        INSERT  INTO tpa_data_exchange_dep        
                ( FK_ID,
				  GRP_TYPE ,
                  RCD_TYPE ,
                  SSN ,
                  SUB_ID ,
                  DEP_SSN ,
                  LAST_NAME ,
                  FIRST_NAME ,
                  MI ,
                  DOB ,
                  GRP_ID ,
                  EFF_DT ,
                  PREX_DT ,
                  GENDER ,
                  REL ,
                  CARD_PRT ,
                  CARD_PRT_DT ,
                  MBR_ST ,
                  DT_UPDT ,
                  GUID
                )
                SELECT
					rs.ID,
                    r.GRP_TYPE ,
                    r.RCD_TYPE ,
                    r.SSN ,
                    r.SUB_ID ,
                    r.DEP_SSN ,
                    r.LAST_NAME ,
                    r.FIRST_NAME ,
                    r.MI ,
                    r.DOB ,
                    r.GRP_ID ,
                    r.EFF_DT ,
                    r.PREX_DT ,
                    r.GENDER ,
                    r.REL ,
                    r.CARD_PRT ,
                    r.CARD_PRT_DT ,
                    r.MBR_ST ,
                    r.DT_UPDT ,
                    r.[GUID]
                FROM
                    tpa_data_exchange AS r
						inner join tpa_data_exchange_sub rs
							on r.SSN = rs.SSN
                WHERE
                    ( r.RCD_TYPE = N'D' )
                    AND ( r.GRP_TYPE = 4 );
			
		/*  update EIMBRID on tpa_data_exchange_dep  */
        SELECT
            @LastOperation = 'create unique EIMBRID for each dependent';
        UPDATE
            d
        SET
            MBR_ID = m.MBR_ID
        FROM
            tpa_data_exchange_dep d
            INNER JOIN ( SELECT
                            ID ,
                            SSN + '0' + CONVERT(NVARCHAR(2), RANK() OVER ( PARTITION BY SSN ORDER BY ISNULL(DOB, '1901-01-01 00:00:00'), LAST_NAME, FIRST_NAME )) MBR_ID
                         FROM
                            tpa_data_exchange_dep
                       ) m
                ON d.ID = m.ID;
				
	COMMIT TRANSACTION
	SET @ReturnParm = 'Procedure succeeded'
END TRY

BEGIN CATCH 
	IF @@TRANCOUNT > 0 
		ROLLBACK

	SELECT  @ErrorMessage = ERROR_MESSAGE() + ' Last Operation: '
			+ @LastOperation ,
			@ErrorSeverity = ERROR_SEVERITY() ,
			@ErrorState = ERROR_STATE()
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    EXEC usp_CallProcedureLog 
	@ObjectID       = @@PROCID,
	@AdditionalInfo = @LastOperation;
    SET @ReturnParm = 'Procedure Failed'
END CATCH
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Imports dependent data from tpa_data_exchange into tpa_data_exchange_dep...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_tpa_import_dep'
GO
