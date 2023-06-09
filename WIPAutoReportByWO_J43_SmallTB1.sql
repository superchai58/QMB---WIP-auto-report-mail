USE [SMT]
GO
/****** Object:  StoredProcedure [dbo].[WIPAutoReportByWO_J43_SmallTB1]    Script Date: 2023/03/13 10:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec WIPAutoReportByWO_J43_MLBTB1 ''

ALTER PROCEDURE [dbo].[WIPAutoReportByWO_J43_SmallTB1] @OutPutEmailContent nvarchar(MAX)  output--, @Stage nvarchar(10) output
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    ----------------------------------------------------------------------------------
	--Declare @Line varchar(10) = 'B16'

	---------------------------Packing uaion (Begin)----------------------------------
	Select * into #Packing From SMT_Packing with(nolock) Where /*Line = @Line AND*/ ModelName IN (Select Distinct ModelName From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	UNION ALL
	Select * From SMTHistory..SMT_Packing with(nolock) Where /*Line = @Line AND*/ ModelName IN (Select Distinct ModelName From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	---------------------------Packing uaion (End)----------------------------------

	---------------------------NGPacking uaion (Begin)----------------------------------
	Select * into #NGPacking From SMT_NGPacking with(nolock) Where /*Line = @Line AND*/ ModelName IN (Select Distinct ModelName From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	UNION ALL
	Select * From SMTHistory..SMT_NGPacking with(nolock) Where /*Line = @Line AND*/ ModelName IN (Select Distinct ModelName From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	---------------------------NGPacking uaion (End)----------------------------------

	---------------------------RCTO_Packing uaion (Begin)----------------------------------
	Select * into #RCTO_Packing From RCTO_Packing with(nolock) Where /*Line = @Line AND*/ QCI_PN IN (Select Distinct SUBSTRING(ModelName, 1, 11) From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	UNION ALL
	Select * From SMTHistory..RCTO_Packing with(nolock) Where /*Line = @Line AND*/ QCI_PN IN (Select Distinct SUBSTRING(ModelName, 1, 11) From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	---------------------------RCTO_Packing uaion (End)----------------------------------

	---------------------------[Packing pass] column (Begin)--------------------------
	Select case when A.WorkOrder is null then B.QCI_WO else A.WorkOrder end as WorkOrder, case when A.SerialNumber is null then B.SN else A.SerialNumber end as SerialNumber into #TmpStatusByWO_Packing
	From #Packing AS A with(nolock) full outer join #RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join #NGPacking AS C with(nolock) ON A.SerialNumber = C.SerialNumber
	--From SMT_Packing AS A with(nolock) inner join RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join SMT_NGPacking AS C with(nolock) ON A.SerialNumber = C.SerialNumber
		 --inner join SMTHistory..SMT_Packing AS D with(nolock) ON A.SerialNumber = D.SerialNumber
	Where C.SerialNumber IS NULL --AND B.Line = @Line --AND C.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'
	order by B.QCI_WO

	--Select * From #TmpStatusByWO_Packing		--superchaiTest
	---------------------------[Packing pass] column (End)--------------------------

	----------------------------[QC] column (Begin)--------------------------------- 
	--Status in SMT_SP
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO 
	From SMT_SP Where [Status] IN ('A+', 'A-', 'B+', 'B-', '*B', 'C+', 'C-', '*C', 'D+', 'D-', 'E+', 'E-', '*E', 'F+', 'F-', '*F') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'QC' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'QC' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder

	--No Input
	--Insert into #TmpStatusByWO
	--Select A.WO, A.SN From SN_AOI AS A with(nolock) Left join #TmpStatusByWO AS B with(nolock) ON A.WO = B.WorkOrder AND A.SN = B.SerialNumber 
	--Where B.SerialNumber IS NULL AND A.WO IN (Select distinct WorkOrder From #TmpStatusByWO)

	--Insert into #TmpStatusByWO
	----Select * From #TmpStatusByWO
	--exec rpt_Q_LostLabel_ALL
	----------------------------[QC] column (End)---------------------------------

	----------------------------[ICT] column (Begin)------------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_ICT 
	From SMT_SP Where [Status] IN ('H+') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'ICT' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'ICT' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder
	----------------------------[ICT] column (End)------------------------------

	----------------------------[USBC-CONNECTOR] column (Begin)-------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_USBC
	From SMT_SP Where [Status] IN ('I+', 'BC', 'EC') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder
	----------------------------[USBC-CONNECTOR] column (End)-------------------------

	------------------------------[UF3] column (Begin)-------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_UF
	--From SMT_SP Where [Status] IN ('I+', 'L1', 'G1', '1G', 'G2', '2G') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[UF3] column (Begin)-------------------------

	------------------------------[UF_LTS] column (Begin)-------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_UF_LTS 
	--From SMT_SP Where [Status] IN ('I+', 'L1', 'G1', '1G', 'G2', '2G', 'G3', '3G', 'UB', 'BU') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[UF_LTS] column (End)-------------------------

	------------------------------[DFU] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_DFU 
	--From SMT_SP Where [Status] IN ('G3', '3G') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'DFU' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'DFU' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[DFU] column (End)--------------------------

	------------------------------[FCT] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_FCT 
	--From SMT_SP Where [Status] IN ('KH') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'DFU' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'DFU' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[FCT] column (End)--------------------------

	------------------------------[IO] column (Begin)-------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_IO
	--From SMT_SP Where [Status] IN ('KH') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'IO' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'IO' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[IO] column (End)-------------------------

	------------------------------[SOC] column (Begin)----------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_SOC
	--From SMT_SP Where [Status] IN ('K2') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'SOC' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'SOC' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[SOC] column (End)----------------------

	------------------------------[WIFI] column (Begin)----------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_WIFI
	--From SMT_SP Where [Status] IN ('KP', 'K0', 'KI') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'SOC' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'SOC' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[WIFI] column (End)----------------------

	------------------------------[FQC] column (Begin)--------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_FQC
	--From SMT_SP Where [Status] IN ('K1', 'N+', 'T1', 'J+', 'J2', '0+') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'FQC' AND [Type] = 'P')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--/*UNION ALL
	--Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'FQC' AND [Type] = 'P')
	--AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--Order by WorkOrder
	------------------------------[FQC] column (End)--------------------
	
	----------------------------[Packing] column (Begin)--------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_Packing1
	From SMT_SP Where [Status] IN ('O+', 'U+') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'Packing' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'Packing' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder
	----------------------------[Packing] column (End)--------------

	----------------------------[QC Fail] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_QCFail
	From SMT_SP Where [Status] IN ('H-','*H', 'H<')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[QC Fail] column (End)--------------------------

	----------------------------[ICT Fail] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_ICTFail
	From SMT_SP Where [Status] IN ('I-', 'I<', '*I')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[ICT Fail] column (End)--------------------------

	----------------------------[USBC-CONNECTOR Fail] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_USBCFail
	From SMT_SP Where [Status] IN ('CB', 'CE')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[USBC-CONNECTOR Fail] column (End)--------------------------

	------------------------------[DFU Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_DFUFail
	--From SMT_SP Where [Status] IN ('HK')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	------------------------------[DFU Fail] column (End)--------------------------

	------------------------------[FCT Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_FCTFail
	--From SMT_SP Where [Status] IN ('2K')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	------------------------------[FCT Fail] column (End)--------------------------

	------------------------------[IO Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_IOFail
	--From SMT_SP Where [Status] IN ('OI')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	------------------------------[IO Fail] column (End)--------------------------

	----------------------------[SOC Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_SOCFail
	--From SMT_SP Where [Status] IN ('PK')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	----------------------------[SOC Fail] column (End)--------------------------

	------------------------------[WIFI Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_WIFIFail
	--From SMT_SP Where [Status] IN ('0K', 'IK' , '1K')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	------------------------------[WIFI Fail] column (End)--------------------------

	------------------------------[FQC/OQA Fail] column (Begin)--------------------------
	--Select WorkOrder, SerialNumber 
	--into #TmpStatusByWO_FQCFail
	--From SMT_SP Where [Status] IN ('N-', '1T', 'J-', 'O-', 'U-', 'N-', '1T', 'J-')
	--AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	--Order by WorkOrder
	------------------------------[FQC/OQA Fail] column (End)--------------------------

	----------------------------[FA-CHECK-IN/OUT] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_CHECKIN
	From SMT_SP Where [Status] IN ('O-', 'U-', 'N-', '1T', 'J-', '75', 'K<', '*K', 'FO')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[FA-CHECK-IN/OUT] column (End)--------------------------

	---------------------------[NGPacking] column (Begin)--------------------------
	Select case when A.WorkOrder is null then B.QCI_WO else A.WorkOrder end as WorkOrder, case when A.SerialNumber is null then B.SN else A.SerialNumber end as SerialNumber into #TmpStatusByWO_NGPacking
	--From SMT_NGPacking AS A with(nolock) full outer join RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join SMT_Packing AS C with(nolock) ON A.SerialNumber = C.SerialNumber
	From #NGPacking AS A with(nolock) inner join #RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join #Packing AS C with(nolock) ON A.SerialNumber = C.SerialNumber
		 --inner join SMTHistory..SMT_NGPacking AS D with(nolock) ON A.SerialNumber = D.SerialNumber
	Where C.SerialNumber IS NULL --AND B.Line = @Line-- AND C.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'
	order by B.QCI_WO
	---------------------------[NGPacking] column (End)--------------------------

	----------------------------[Scrap] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_Scrap
	From SMT_SP Where [Status] IN ('SR')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[Scrap] column (End)--------------------------

	Declare @num int = 0, @count int = 1, @sql nvarchar(max) = ''

	----------------------Fail status (Begin)--------------------
	--Create table #tmpCount (
	--	TableCount varchar(50)
	--)
	--Select @num = count(*) From TmpStatusByWOQuery Where [Type] = 'F'
	--Select * into #TmpStatusByWOQuery_Fail From TmpStatusByWOQuery Where [Type] = 'F' Order by [Status]

	--WHILE (@count <= @num)
	--BEGIN

	--	IF exists(
	--		Select Top 1 0
	--		--into ##TmpStatusByWO_Fail_' + CONVERT(varchar(10),@count) + '
	--		From SMT_SP AS A with(nolock) inner join #TmpStatusByWOQuery_Fail AS B with(nolock) ON A.[Status] = B.[Status]
	--		Where A.[Status] IN (Select TOP 1 [Status] From #TmpStatusByWOQuery_Fail Where [Type] = 'F')
	--		AND A.MFGLine = 'B16' AND A.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'
	--		/*UNION ALL
	--		Select Top 1 0
	--		From SMTHistory..SMT_SP AS A with(nolock) inner join #TmpStatusByWOQuery_Fail AS B with(nolock) ON A.[Status] = B.[Status] 
	--		Where A.[Status] IN (Select TOP 1 [Status] From #TmpStatusByWOQuery_Fail Where [Type] = 'F')
	--		AND A.MFGLine = 'B16' AND A.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	--		Order by A.WorkOrder
	--	)
	--	BEGIN
	--		--Drop table
	--		set @sql= '
	--			Drop table if exists tempdb.dbo.##TmpStatusByWO_Fail_' + CONVERT(varchar(10),@count) + '				
	--		'
	--		exec(@sql)

	--		--Insert table
	--		set @sql= '
	--			Select A.WorkOrder AS WorkOrder, A.SerialNumber AS SerialNumber, A.[Status] AS [Status], B.[Desc] AS [Desc]
	--			into tempdb.dbo.##TmpStatusByWO_Fail_' + CONVERT(varchar(10),@count) + '
	--			From SMT_SP AS A with(nolock) inner join #TmpStatusByWOQuery_Fail AS B with(nolock) ON A.[Status] = B.[Status]
	--			Where A.[Status] IN (Select TOP 1 [Status] From #TmpStatusByWOQuery_Fail Where [Type] = ''F'')
	--			AND A.MFGLine = ''B16'' AND A.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), ''yyyyMMdd'') + ''235959''
	--			/*UNION ALL
	--			Select A.WorkOrder AS WorkOrder, A.SerialNumber AS SerialNumber, A.[Status] AS [Status], B.[Desc] AS [Desc]
	--			From SMTHistory..SMT_SP AS A with(nolock) inner join #TmpStatusByWOQuery_Fail AS B with(nolock) ON A.[Status] = B.[Status] 
	--			Where A.[Status] IN (Select TOP 1 [Status] From #TmpStatusByWOQuery_Fail Where [Type] = ''F'')
	--			AND A.MFGLine = ''B16'' AND A.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), ''yyyyMMdd'') + ''235959''*/
	--			Order by A.WorkOrder
	--		'
	--		exec(@sql)

	--		insert into #tmpCount values ('##TmpStatusByWO_Fail_' + CONVERT(varchar(10),@count))
	--	END
	
	--	DELETE TOP (1) FROM #TmpStatusByWOQuery_Fail
	--	Set @count = @count + 1
	--END
	----------------------Fail status (End)--------------------

	--Set string
	--Declare @text1 varchar(max) = '', @text2 varchar(max) = '', @tmpTable varchar(50) = '', @tmpStation varchar(50) = '', @ParmDefinition nvarchar(50);
	--IF EXISTS(Select TOP 1 0 From #tmpCount)
	--BEGIN
	--	Set @count = 1
	--	Select @num = count(*) From #tmpCount
	--	--Select @num As num		--TEST
	--	WHILE (@count <= @num)
	--	BEGIN
	--		--Table name
	--		Select TOP 1 @tmpTable = TableCount From #tmpCount
		
	--		--DESC		
	--		set @sql = '
	--			Select TOP 1 @tmpOutput = [Desc] From '+@tmpTable+'			
	--		'
	--		SET @ParmDefinition = N'@tmpOutput varchar(50) OUTPUT';
	--		EXEC dbo.sp_executesql @sql, @ParmDefinition, @tmpOutput=@tmpStation output

	--		Set @tmpStation = '[' +@tmpStation+ ']'
		
	--		--Column
	--		set @text1 = @text1 + '
	--			, CONVERT(VARCHAR(50), COUNT(' + @tmpStation + '.SerialNumber)) AS '+@tmpStation+'

	--		'	
	--		--Select @text1 AS text1		--test
	--		--Join table
	--		set @text2 = @text2 + '

	--			Full outer join '+@tmpTable+' AS '+@tmpStation+' with(nolock) ON A.WO = '+@tmpStation+'.WorkOrder AND '+@tmpStation+'.SerialNumber = SMT_SP.SerialNumber

	--		'	
	--		--Select @text2 AS text2		--test
	--		DELETE TOP (1) FROM #tmpCount
	--		Set @count = @count + 1
	--	END
	--END

	--Select @text2 AS text2		--Test

	--------------------Test (Brgin)------------------------
	--set @sql= '
	--	Select * From tempDB..##tmpTableText1				
	--'
	--exec(@sql)
	--------------------Test (End)------------------------

	--Drop table
	--set @sql= '
	--	Drop table if exists tempDB..##tmpTableText1				
	--'
	--exec(@sql)
	--Drop table if exists ##tmpTableText1		--Test

	------------------Test (Brgin)------------------------
	--set @sql= '
	--	Select * From tempDB..##tmpTableText1				
	--'
	--exec(@sql)
	------------------Test (End)------------------------

	----------------------------------------------Summary table (Begin)----------------------------------------------
	Select A.Stage + ' ' + A.Config AS Config, A.Model AS QPN, A.WO, B.Qty AS [WO-Qty], B.Sap_MB_Rev AS Batch, CONVERT(VARCHAR(50), count(C.SerialNumber) - COUNT(NGPacking.SerialNumber)) AS [Packing Pass], 
		   B.Qty - ((count(C.SerialNumber) - COUNT(NGPacking.SerialNumber)) + COUNT(D.SerialNumber) + COUNT(ICT.SerialNumber) + COUNT(USBC.SerialNumber) + COUNT(Packing.SerialNumber) + COUNT(QCFail.SerialNumber) + COUNT(ICTFail.SerialNumber) + COUNT(USBCFail.SerialNumber) + COUNT(ChkIn.SerialNumber) + COUNT(NGPacking.SerialNumber) + COUNT(Scrap.SerialNumber)) AS [No Input],
		   COUNT(D.SerialNumber) AS QC, 
		   CONVERT(VARCHAR(50), COUNT(ICT.SerialNumber)) AS ICT, CONVERT(VARCHAR(50), COUNT(USBC.SerialNumber)) AS [USBC-CONNECTOR], CONVERT(VARCHAR(50), COUNT(Packing.SerialNumber)) AS Packing,
		   CONVERT(VARCHAR(50), COUNT(QCFail.SerialNumber)) AS [QC Fail], CONVERT(VARCHAR(50), COUNT(ICTFail.SerialNumber)) AS [ICT Fail], CONVERT(VARCHAR(50), COUNT(USBCFail.SerialNumber)) AS [USBC-CONNECTOR Fail], CONVERT(VARCHAR(50), COUNT(ChkIn.SerialNumber)) AS [FA-CHECK-IN/OUT],
		   CONVERT(VARCHAR(50), COUNT(NGPacking.SerialNumber)) AS NGPacking, CONVERT(VARCHAR(50), COUNT(Scrap.SerialNumber)) AS Scrap
	into #tmpTableText1
	from WO_Config AS A WITH(NOLOCK) Inner join SAP_WO_LIST AS B WITH(NOLOCK) ON  A.WO = B.WO /*Inner join SN_AOI AS SN_AOI with(nolock) ON A.WO = SN_AOI.WO */ Inner join QSMS_WOGroup AS QSMS_WOGroup with(nolock) ON A.WO = QSMS_WOGroup.Work_Order
	left join SMT_SP AS SMT_SP with(nolock) ON A.WO = SMT_SP.WorkOrder
	Full outer join #TmpStatusByWO AS D with(nolock) ON A.WO = D.WorkOrder AND D.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_ICT AS ICT with(nolock) ON A.WO = ICT.WorkOrder AND ICT.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_USBC AS USBC with(nolock) ON A.WO = USBC.WorkOrder AND USBC.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Packing1 AS Packing with(nolock) ON A.WO = Packing.WorkOrder AND Packing.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_QCFail AS QCFail with(nolock) ON A.WO = QCFail.WorkOrder AND QCFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_ICTFail AS ICTFail with(nolock) ON A.WO = ICTFail.WorkOrder AND ICTFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_USBCFail AS USBCFail with(nolock) ON A.WO = USBCFail.WorkOrder AND USBCFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_CHECKIN AS ChkIn with(nolock) ON A.WO = ChkIn.WorkOrder AND ChkIn.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Scrap AS Scrap with(nolock) ON A.WO = Scrap.WorkOrder AND Scrap.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Packing AS C With(nolock) ON A.WO = C.WorkOrder AND C.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_NGPacking AS NGPacking with(nolock) ON A.WO = NGPacking.WorkOrder AND NGPacking.SerialNumber = SMT_SP.SerialNumber
	Where /*B.Line = @Line AND*/ SMT_SP.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000' AND B.[Status] = '20' AND QSMS_WOGroup.ClosedFlag <> 'Y' AND B.PN in (Select Distinct SUBSTRING(ModelName, 1, 11) From ModelName Where ModelDesc LIKE 'J43%' AND SUBSTRING(PN , 1, 7) IN ('33P7JCB','3KP7JBB','3IP7JCB','32P7KUB','3JP7JTB','21P7KMB','21P7JMB'))
	Group by A.Stage + ' ' + A.Config, A.Model, A.WO, B.Qty, B.Sap_MB_Rev, SMT_SP.WorkOrder
	Order by A.WO
	
	--Select * From #tmpTableText1		--superchaiTest
	----------------------------------------------Summary table (End)----------------------------------------------

	--------------------Get Stage in variable (Begin)----------------------
	Declare @Stage varchar(10) = ''
	Select Top 1 @Stage = SUBSTRING(Config, 1, CHARINDEX(' ', Config)) from #tmpTableText1
	--------------------Get Stage in variable (End)----------------------

	--set @sql= '
	--	Drop table if exists #TempEmailContent			
	--'
	--exec(@sql)

	Create Table #TempEmailContent(EmailContent nvarchar(max))		--Table 1 
	--Create Table #TempEmailContent2(EmailContent nvarchar(max))		--Table 2

	--Select '##tmpTableText1' AS ##tmpTableText1, * From ##tmpTableText1		--Test

	---------------------------TEST (Begin)---------------------------
	--Select * From tempDB..##tmpTableText1

	--select '<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+ convert(varchar(50), [Config])+'</td>' AS [Config],
	--'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+convert(varchar(50), [QPN])+'</td>' AS [QPN], 
	--'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+convert(varchar(50), [WO])+'</td>' AS [WO], 
	--'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+convert(varchar(50), [WO-Qty])+'</td>' AS [WO-Qty]
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[Batch]+'</td>' AS [Batch], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[Packing Pass]+'</td>' AS [Packing Pass], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[QC]+'</td>' AS [QC], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[ICT]+'</td>' AS [ICT], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[UF_LTS]+'</td>' AS [UF_LTS], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[DFU]+'</td>' AS [DFU], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[IO]+'</td>' AS [IO], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[SOC]+'</td>' AS [SOC], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[FQC]+'</td>' AS [FQC], 
	----'<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[Packing]+'</td>' AS [Packing],
	---- '<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[DFU-NAND-INIT FAIL]+'</td>' AS [DFU-NAND-INIT FAIL], 
	---- '<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[IO FAIL]+'</td>' AS [IO FAIL], 
	---- '<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">'+[SOC-TEST FAIL]+'</td>' AS [SOC-TEST FAIL] /*into ##tmpTemplate*/ 
	-- from tempDB..##tmpTableText1
	---------------------------TEST (End)---------------------------

	--------------------Loop Qquery column (Begin)-------------------------------
	--Declare @textTd nvarchar(max) = ''
	Set @sql = ''
	
	--SELECT * FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText1')	--Test
	IF EXISTS(Select TOP 1 0 From #tmpTableText1)
	BEGIN
		IF exists(SELECT Top 1 0 FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..#tmpTableText1'))
		BEGIN
			Drop table if exists #name
			--Select Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText1')		--Test
			SELECT Distinct name into #name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..#tmpTableText1')
			Declare @name varchar(50) = ''

			------------------------------------------------------------------
			Declare @i int = 0, @tmpText1 varchar(500) = '''<td style="border-left:none;border-Top:none">''', @tmpText2 varchar(20) = '''</td>''', @tmpSpace varchar(20) = '''                  '''
			Declare @tmpText1H varchar(500) = '''<td style="border-left:none;border-Top:none; font-weight: bold;padding: 5px;text-align: center;background-color: darkgray;">'''	--Gray
			Declare @tmpText1HGreen varchar(500) = '''<td style="border-left:none;border-Top:none; font-weight: bold;padding: 5px;text-align: center;background-color: limegreen;">'''	--Green
			Declare @tmpText1Yellow varchar(500) = '''<td style="border-left:none;border-Top:none; font-weight: bold;padding: 5px;text-align: center;background-color: yellow;">'''	--Yellow
			Declare @tmpText1Blue varchar(500) = '''<td style="border-left:none;border-Top:none; font-weight: bold;padding: 5px;text-align: center;background-color: deepskyblue;">'''	--Blue
			Declare @countColor int = 1

			Select @i = count(name) From #name

			--Header
			While ((Select count(name) From #name) > 0)
			BEGIN
				SELECT TOP 1 @name = name FROM #name

				IF (@countColor = 1 OR @countColor = 2 OR @countColor = 3 OR @countColor = 4 OR @countColor = 5) 
				BEGIN
					--Last
					IF ((Select count(name) From #name) = 1)
					BEGIN
						--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1H + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + '] into ##tmpTemplate from tempDB..#tmpTableText1'
					END

					--Firt
					ELSE IF (@i = (Select count(name) From #name))
					BEGIN
				
						--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
						--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = 'select TOP 1 ' + @tmpSpace + '+' + @tmpText1H + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
					ELSE
					BEgin
						--Set @sql = @sql + ', [' + @name + ']'
						---Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1H + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
				END
				ELSE IF (@countColor = 6)
				BEGIN
					--Last
					IF ((Select count(name) From #name) = 1)
					BEGIN
						--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1HGreen + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + '] into ##tmpTemplate from tempDB..#tmpTableText1'
					END

					--Firt
					ELSE IF (@i = (Select count(name) From #name))
					BEGIN
				
						--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
						--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = 'select TOP 1 ' + @tmpSpace + '+' + @tmpText1HGreen + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
					ELSE
					BEgin
						--Set @sql = @sql + ', [' + @name + ']'
						---Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1HGreen + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
				END
				ELSE IF (@countColor = 7 OR @countColor = 8 OR @countColor = 9 OR @countColor = 10 OR @countColor = 11 /*OR @countColor = 12 OR @countColor = 13 OR @countColor = 14 OR @countColor = 15 OR @countColor = 16*/) 
				BEGIN
					--Last
					IF ((Select count(name) From #name) = 1)
					BEGIN
						--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1Yellow + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + '] into ##tmpTemplate from tempDB..#tmpTableText1'
					END

					--Firt
					ELSE IF (@i = (Select count(name) From #name))
					BEGIN
				
						--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
						--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = 'select TOP 1 ' + @tmpSpace + '+' + @tmpText1Yellow + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
					ELSE
					BEgin
						--Set @sql = @sql + ', [' + @name + ']'
						---Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1Yellow + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
				END
				ELSE
				BEGIN
					--Last
					IF ((Select count(name) From #name) = 1)
					BEGIN
						--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1Blue + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + '] into ##tmpTemplate from tempDB..#tmpTableText1'
					END

					--Firt
					ELSE IF (@i = (Select count(name) From #name))
					BEGIN
				
						--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
						--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = 'select TOP 1 ' + @tmpSpace + '+' + @tmpText1Blue + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
					ELSE
					BEgin
						--Set @sql = @sql + ', [' + @name + ']'
						---Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
						Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1Blue + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + ']'
					END
				END			
			
				--Set @textTd = @textTd + '<td width=55.2 bgcolor="#FFFF99” style="border-left:none;border-Top:none;width:41.6pt">['+@name+']</td>'
			
				Set @countColor = @countColor + 1
				DELETE TOP (1) FROM #name
			END

			--Select @sql		--Test

			EXEC (@sql)
			--Select * From ##tmpTemplate		--TEST

			--Column
			Insert into #name
			SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..#tmpTableText1')
			Select @i = count(name) From #name

			While ((Select count(name) From #name) > 0)
			BEGIN
				SELECT TOP 1 @name = name FROM #name

				--Last
				IF ((Select count(name) From #name) = 1)
				BEGIN
					--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
					--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
					Set @sql = @sql + ', ' + @tmpText1 + '+convert(varchar(50), [' + @name + '])+' + @tmpText2 + ' AS [' + @name + '] from tempDB..#tmpTableText1'
				END

				--Firt
				ELSE IF (@i = (Select count(name) From #name))
				BEGIN
				
					--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
					--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
					Set @sql = 'Insert into ##tmpTemplate select ' + @tmpText1 + '+convert(varchar(50), [' + @name + '])+' + @tmpText2 + ' AS [' + @name + ']'
				END
				ELSE
				BEgin
					--Set @sql = @sql + ', [' + @name + ']'
					---Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
					Set @sql = @sql + ', ' + @tmpText1 + '+convert(varchar(50), [' + @name + '])+' + @tmpText2 + ' AS [' + @name + ']'
				END
			
				--Set @textTd = @textTd + '<td width=55.2 bgcolor="#FFFF99” style="border-left:none;border-Top:none;width:41.6pt">['+@name+']</td>'
			
				DELETE TOP (1) FROM #name
			END

			--Select @sql		--Test
			EXEC (@sql)
			------------------------------------------------------------------

			--------------------------------------------------------------------------------------------------------------

			--Select * From ##tmpTemplate		--TEST
			--Select * From #name				--TEST

			Insert into #name
			SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTemplate')
			Set @sql = ''
			Set @sql = @sql + 'insert into #TempEmailContent
								select ''<tr height=21.6 style="height:16.2pt;">'''
			--Set @sql = @sql + '<tr  align=right height=21.6 style="height:16.2pt">'

			While ((Select count(name) From #name) > 0)
			BEGIN
				SELECT TOP 1 @name = name FROM #name

				--Set @sql = @sql + '<td width=55.2 bgcolor="#FFFF99" style="border-left:none;border-Top:none;width:41.6pt">''+['+CONVERT(INT, CONVERT(VARCHAR(50), @name))+']+''</td>'
				Set @sql = @sql + '+[' + @name + ']'
				--'+convert(varchar(50), [' + @name + '])+'
				--Set @textTd = @textTd + '<td width=55.2 bgcolor="#FFFF99” style="border-left:none;border-Top:none;width:41.6pt">['+@name+']</td>'
			
				DELETE TOP (1) FROM #name
			END

			Set @sql = @sql + '+''</tr>''
				from tempDB..##tmpTemplate
			'

			--Set @sql = @sql + '</tr>''
			--'
			--Select @sql		--Test

			--select '<tr  align=right height=21.6 style="height:16.2pt">'+[Config]+[QPN]+[WO]+[WO-Qty]+[Batch]+[Packing Pass]+[QC]+[ICT]+[UF_LTS]+[DFU]+[IO]+[SOC]+[FQC]+[Packing]+[DFU-NAND-INIT FAIL]+[IO FAIL]+[SOC-TEST FAIL]+'</tr>'     
			--from tempDB..##tmpTemplate    --TEST
			EXEC (@sql)
			--------------------------------------------------------------------------------------------------------------
	
		END
		--------------------Loop Qquery column (End)-------------------------------

		--------------------------Create table from HTML (Begin)------------------------------

		---------------------------------------------------------------------------------------------------------
		Declare @EmailContent nvarchar(max) = ''

		Set @EmailContent='<html>
							<Body><font color=black size=3 face="Tahoma">Dear All,
									&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
									<p>Update QMB J43x MLB '+@Stage+' Build <b>MLB WIP report at '+ convert(varchar, getdate(), 108) + ' PM on '+LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5)+' (Table 1)</b>, please help review it, thanks!</p>
									</font>'    
		set @EmailContent=@EmailContent+'<table  border=1 cellspacing=0 bordercolor=#000000    style="font-family:tahoma;Font-Size:9.6pt;width: 100%;" >'
	
		Select @EmailContent = @EmailContent + EmailContent From #TempEmailContent
		--Select * From #TempEmailContent		--TEST
		--Select @EmailContent = @EmailContent + @sql	--Test

		set @EmailContent=@EmailContent+'</table></body></html>'
		
		Select @OutPutEmailContent = @EmailContent
		Select @Stage

		--set @EmailContent=@EmailContent+'<br><br><font color=blue size=2 face="Tahoma">Best Regards,<br>QMS/AutoSendmail</font></body></html>' 
		Drop table ##tmpTemplate
	END

	--Select @EmailContent AS EmailContent	--Test
	--Select * From ##tmpTemplate

END
