USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspUpdateAAImport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspUpdateAAImport]
@ReturnParm VARCHAR(255) OUTPUT 

AS
/* =============================================
	Object:			uspUpdateAAImport
	Version:		2
	Author:			John Criswell
	Create date:	2/1/2015	 
	Description:	Copies data over for certain fields from 
					tblSubscr to tblEDI_App_Subscr
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	
	
	
============================================= */

/*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT
-----------------------------------------------        
 BEGIN TRY
        BEGIN TRANSACTION
			SELECT  @LastOperation = 'Update PreexistingDate with date in correct format.'


		--populates the PreexistingDate field on tblEDI_App_Subscr
		--with the proper format of mm/dd/yyyy
		UPDATE tblEDI_App_Subscr 
		SET tblEDI_App_Subscr.PreexistingDate = substring([EIDTCVEF],1,2) + '/' + substring([EIDTCVEF],3,2) + '/' + substring([EIDTCVEF],5,4)
		FROM tblEDI_App_Subscr
		INNER JOIN AAPreexistingDates ON AAPreexistingDates.[EISSN#] = tblEDI_App_Subscr.SUBssn
	

		SELECT  @LastOperation = 'Update tblEDI_App_Subscr with data from tblSubscr.'
		--populates fields on the tblEDI_App_Subscr table from data that is on the 
		--the production QCD subscriber table (tblSubscr) i.e. SubID, etc -- things
		--that are not on the GroupLink table
		UPDATE  edis
		SET     edis.SubID = s.SubID,
				edis.SubCancelled = s.SubCancelled,  
				edis.SubCardPrt = s.SubCardPrt, 
				edis.SubCardPrtDte = s.SubCardPrtDte, 
				edis.SubNotes = s.SubNotes, 
				edis.DateCreated = s.DateCreated, 
				edis.DateUpdated = s.DateUpdated
		FROM tblEDI_App_Subscr AS edis
			INNER JOIN tblSubscr s
				ON edis.SubSSN = s.SubSSN		
		 
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
