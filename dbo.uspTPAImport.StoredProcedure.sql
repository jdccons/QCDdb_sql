USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspTPAImport]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspTPAImport]
@ReturnParm VARCHAR(255) OUTPUT 

AS
/* =============================================
	Object:			uspTPAImport
	Version:		2
	Author:			John Criswell
	Create date:	2/1/2015	 
	Description:	Imports data from third party administrator file.
					Called from fdlgAASync.cmdImport in the Access 
					front end.
							
	Change Log:
	--------------------------------------------
	Change Date		Changed by		Reason
	2015-02-01		JCriswell		Created
	2015-02-20		JCriswell		Added additional code
									to port Access SQL from the
									front end into this stored
									procedure.  
	
	
============================================= */
/*  declarations  */ 
    DECLARE @LastOperation VARCHAR(128) ,
        @ErrorMessage VARCHAR(8000) ,
        @ErrorSeverity INT ,
        @ErrorState INT
          
------------------------------------------------------------------------------
	DECLARE @SubID AS INT
	DECLARE @NextSubID AS INT

 BEGIN TRY
        BEGIN TRANSACTION
        
        SELECT @LastOperation = 'populate temp table for all AA groups';
        -- populate temp table for all AA groups
        DELETE FROM tblAAGroups;        
           
        INSERT INTO tblAAGroups ( SUBgroupID ) 
        SELECT DISTINCT tblEDI_App_Subscr.SUBgroupID
               FROM tblEDI_App_Subscr;        
        
        SELECT @LastOperation = 'delete subscribers first where the GroupIDs match';
        -- delete subscribers first where the GroupID's match
        DELETE FROM tblSubscr
			FROM  tblSubscr 
				INNER JOIN tblAAGroups 
					ON tblSubscr.SubGroupID = tblAAGroups.SUBgroupID;
        
        SELECT @LastOperation = 'delete subscribers second where the SSNs match';
        -- delete subscribers second where the SSN's match
        DELETE FROM tblSubscr
            FROM tblEDI_App_Subscr
                INNER JOIN tblSubscr
                    ON tblEDI_App_Subscr.SubSSN = tblSubscr.SubSSN;
        
            
        -- populates the SubID field in tblEDI_App_Subscr
        -- for all new subscribers who have not been
        -- assigned a SubID yet
       SELECT @LastOperation = 'create SubIDs';
       SELECT @SubID = (SELECT LastSubID FROM SubIDControl);
		
        IF OBJECT_ID('tempdb..#SubID') IS NOT NULL 
            DROP TABLE #SubID
        
        SELECT IDENTITY( INT,1,1 ) AS [ID], @SubID AS SubID, 0 AS NextSubID,
                SubSSN
            INTO #SubID
            FROM (             
					SELECT     SubSSN
					FROM       tblEDI_App_Subscr
					WHERE     (SubID = '') 
								OR (SubID IS NULL)					
				) s
            
        UPDATE a
            SET NextSubID = ( b.SubID + b.Id )
            FROM #SubID a 
            INNER JOIN #SubID b
                ON a.Id = b.Id; 
        
        -- update the import table with SubIDs        
        SELECT @LastOperation = 'update the import table with SubIDs';
        UPDATE  tblEDI_App_Subscr
		SET tblEDI_App_Subscr.SubID = CAST(#SubID.NextSubID AS VARCHAR(8))
	    FROM tblEDI_App_Subscr  
			INNER JOIN #SubID
				ON tblEDI_App_Subscr.SubSSN = #SubID.SubSSN;
			
        -- save the last SubID used        
        SELECT @LastOperation = 'save the last SubID used';        
        IF EXISTS ( SELECT 1 FROM #SubID ) 
            BEGIN
                SELECT  @NextSubID = MAX(NextSubID)
                    FROM #SubID
		        
                UPDATE SubIDControl
                    SET LastSubID = @NextSubID + 1
            END
		
		-- insert TPA data into tblSubscr
        SELECT  @LastOperation = 'Insert TPA data into tblSubscr.'
			INSERT INTO tblSubscr
								  (SubSSN, SubID, EIMBRID, PlanID, CoverID, RateID, 
								  SubCancelled,
								  SubFirstName, SubMiddleName, SubLastName, 
								  SubStreet1, SubStreet2, SubCity, SubState, SubZip, 
								  SubPhoneWork, SubPhoneHome, SubGroupID, SubDOB, DepCnt, SubStatus, PreexistingDate, 
								  SubEffDate, SubExpDate, SubCardPrt, SubCardPrtDte, 
								  SubNotes, SubContBeg, SubContEnd, SubPymtFreq, SUB_LUname, SubGeoID, 
								  DateCreated, DateUpdated, SUBbankDraftNo, Flag, 
								  SubGender, SubAge)
			SELECT				  SubSSN, SubID, EIMBRID, PlanID, CoverID, RateID, 
								  1 AS SubCanelled,
								  UPPER(SubFirstName) AS FirstName, UPPER(SubMiddleName) AS MiddleName, UPPER(SubLastName) AS LastName, SubStreet1, SubStreet2, SubCity, SubState, SubZip, 
								  SubPhoneWork, SubPhoneHome, SubGroupID, SUBdob, DepCnt, SubStatus, PreexistingDate, 
								  SubEffDate, SubExpDate, SubCardPrt, SubCardPrtDte, 
								  SubNotes, SubContBeg, SubContEnd, SubPymtFreq, UPPER(SUB_LUname) AS LU_Name, SubGeoID, 
								  DateCreated, DateUpdated, SUBbankDraftNo, Flag, 
								  (CASE WHEN edis.SubGender IS NULL THEN 'O' 
								   ELSE edis.SubGender 
								   END) AS Gender, SubAge
			FROM         tblEDI_App_Subscr AS edis
		
		-- insert TPA data into tblDependent	
		SELECT  @LastOperation = 'Insert TPA data into tblDependent.'	
			INSERT INTO tblDependent
								  (DepSSN, DepSubID, EIMBRID, DepFirstName, DepMiddleName, DepLastName, 
								  DepDOB, DepAge, 
								  DepGender, DepRelationship, DepEffDate, PreexistingDate)
			SELECT				  edid.DepSSN, edid.DepSubID, edid.EIMBRID, UPPER(edid.DepFirstName) AS FirstName, UPPER(edid.DepMiddleName) AS MI, UPPER(edid.DepLastName) AS LastName, 
								  edid.DepDOB, edid.DepAge, 
								  (CASE WHEN DepGender IS NULL THEN 'O' 
								   ELSE DepGender 
								   END) AS Gender, edid.DepRelationship, edid.DepEffDate, 
								  edid.PreexistingDate
			FROM         tblEDI_App_Subscr AS edis RIGHT OUTER JOIN
								  tblEDI_App_Dep AS edid ON edis.SubSSN = edid.DepSubID
		COMMIT TRANSACTION
		SET @ReturnParm = 'Procedure succeeded' 
    END TRY

	-- Error Handler
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
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'Imports data from third party administrator file.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'uspTPAImport'
GO
