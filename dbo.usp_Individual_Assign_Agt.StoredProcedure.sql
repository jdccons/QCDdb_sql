USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[usp_Individual_Assign_Agt]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Individual_Assign_Agt] 
		(
		@SubID NCHAR(8),
		@CustKey NCHAR(5)
		)
AS
INSERT INTO tblIndivAgt (
	AgentID
	, SubscrID
	, PltCustKey
	, [PRIMARY]	
	, AgentRate
	, CommOwed
	)
VALUES (
	'CORPT'
	, @SubID
	, @CustKey
	, 1
	, 0
	, 0
	)
	RETURN 1
	;
GO
EXEC sys.sp_addextendedproperty @name=N'Purpose', @value=N'creates the default agent for individuals' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'usp_Individual_Assign_Agt'
GO
