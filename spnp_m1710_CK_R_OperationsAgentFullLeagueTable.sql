/******************************************************************************
   
Description:spnp_m1710_CK_R_OperationsAgentLeagueTable 

User who last changed the file
$Author: Paul $ 

Date and time of last check in
$Date: 13/02/17 16:29 $ 

Date and time of last modification
$Modtime: 9/02/17 10:24 $ 

VSS version number
$Revision: 2 $ 

*******************************************************************************/
IF EXISTS (
		SELECT
			*
		FROM dbo.sysobjects
		WHERE Id = OBJECT_ID(N'[dbo].[spnp_m1710_CK_R_OperationsAgentFullLeagueTable]')
			AND OBJECTPROPERTY(Id, N'IsProcedure') = 1
	)
	DROP PROCEDURE [dbo].spnp_m1710_CK_R_OperationsAgentFullLeagueTable
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].spnp_m1710_CK_R_OperationsAgentFullLeagueTable (@EmpID INT
, @StartDate DATETIME
, @EndDate DATETIME
, @AuditBy VARCHAR(MAX)
)

AS

	DECLARE @channel INT

	SELECT
		@channel = CHANNEL
	FROM WS_PERSONAL_DETAIL
	WHERE EMP_ID = @EmpID

SELECT *,SUM(Data.Total1to3)OVER() AS Channel1to3, SUM(Data.Total)OVER() AS ChannelTotal FROM
(
	SELECT
		mcacd.People_AgentId
	,	mcacd.People_AgentCode
	,	mcacd.People_Agent
	,	SUM(CASE
			WHEN mcacd.AuditResults_FinalRiskCategory IN ('Category 1', 'Category 2', 'Category 3') THEN 1
			ELSE 0
		END) AS Total1to3
	,	COUNT(mcacd.AuditResults_FinalRiskCategory) AS Total
	,	dbo.UFWS_CALC_PERCENT_100(SUM(CASE
			WHEN mcacd.AuditResults_FinalRiskCategory IN ('Category 1', 'Category 2', 'Category 3') THEN 1
			ELSE 0
		END), COUNT(mcacd.AuditResults_FinalRiskCategory)) AS Percent1to3
	,	ROW_NUMBER() OVER (ORDER BY dbo.UFWS_CALC_PERCENT_100(SUM(CASE
			WHEN mcacd.AuditResults_FinalRiskCategory IN ('Category 1', 'Category 2', 'Category 3') THEN 1
			ELSE 0
		END), COUNT(mcacd.AuditResults_FinalRiskCategory)), COUNT(mcacd.AuditResults_FinalRiskCategory) DESC) AS RNK
	,	CASE
			WHEN ROW_NUMBER() OVER (ORDER BY dbo.UFWS_CALC_PERCENT_100(SUM(CASE
				WHEN mcacd.AuditResults_FinalRiskCategory IN ('Category 1', 'Category 2', 'Category 3') THEN 1
				ELSE 0
			END), COUNT(mcacd.AuditResults_FinalRiskCategory)), COUNT(mcacd.AuditResults_FinalRiskCategory) DESC) = (COUNT(mcacd.People_AgentId) OVER () / 2) THEN 1
			ELSE 0
		END AS MiddleRow
	,	CASE
			WHEN People_AgentId = @EmpID THEN 1
			ELSE 0
		END AS MyPosition
	,	COUNT(mcacd.People_AgentId) OVER () AS TotalAgents
	,	NTILE(20) OVER (ORDER BY dbo.UFWS_CALC_PERCENT_100(SUM(CASE
			WHEN mcacd.AuditResults_FinalRiskCategory IN ('Category 1', 'Category 2', 'Category 3') THEN 1
			ELSE 0
		END), COUNT(mcacd.AuditResults_FinalRiskCategory)), COUNT(mcacd.AuditResults_FinalRiskCategory) DESC) * 5 AS Percentile
	FROM M1710_CK_AllCaseData mcacd --ON mcul.ChildEmpId = mcacd.People_AgentId
	JOIN EMP e ON e.EMP_ID = mcacd.People_AgentId
	JOIN EMP e1 ON e.GROUP_EMP_ID = e1.EMP_ID
	JOIN WS_PERSONAL_DETAIL wpd ON e.EMP_ID = wpd.EMP_ID AND wpd.CHANNEL = @channel
	WHERE mcacd.AuditResults_FinalRiskCategory IS NOT NULL
		AND mcacd.AuditResults_DateOfAudit BETWEEN @StartDate AND @EndDate
		AND (mcacd.People_AuditorRole LIKE @AuditBy + '%'
		OR @AuditBy = 'All')
	GROUP BY
		mcacd.People_AgentId
	,	mcacd.People_AgentCode
	,	mcacd.People_Agent
) AS Data

GO
IF EXISTS (
		SELECT
			*
		FROM dbo.sysobjects
		WHERE Id = OBJECT_ID(N'[dbo].[spnp_m1710_CK_R_OperationsAgentFullLeagueTable]')
			AND OBJECTPROPERTY(Id, N'IsProcedure') = 1
	)
BEGIN
	IF EXISTS (
			SELECT
				1
			FROM sys.database_principals
			WHERE name = 'wsmart'
		)
		GRANT EXECUTE ON [dbo].spnp_m1710_CK_R_OperationsAgentFullLeagueTable TO [wsmart]
	IF EXISTS (
			SELECT
				1
			FROM sys.database_principals
			WHERE name = 'cswa'
		)
		GRANT EXECUTE ON [dbo].spnp_m1710_CK_R_OperationsAgentFullLeagueTable TO [cswa]
END

-- the code below needs to be commented out when testing the procedure 

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

IF EXISTS (
		SELECT
			*
		FROM dbo.sysobjects
		WHERE Id = OBJECT_ID(N'[dbo].[S_SQL_UPDATES]')
			AND OBJECTPROPERTY(Id, N'IsUserTable') = 1
	)
BEGIN
	DECLARE	@JOBDESC VARCHAR(1000)
		,	@SCRIPTNAME VARCHAR(50)
		,	@SCRIPTDATE DATETIME
		,	@SCRIPTTYPE VARCHAR(20)
	SET @JOBDESC = 'Aviva OTM'
	SET @SCRIPTNAME = 'spnp_m1710_CK_R_OperationsAgentFullLeagueTable.sql'
	SET @SCRIPTDATE = CONVERT(DATETIME, '09/02/2017', 103)
	SET @SCRIPTTYPE = 'M1710 Script'
	EXEC dbo.SPWS_SQL_UPDATE_ADD	@SCRIPTNAME
								,	@SCRIPTTYPE
								,	@JOBDESC
								,	@SCRIPTDATE
END
GO