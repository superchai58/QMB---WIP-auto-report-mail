USE [SMT]
GO
/****** Object:  StoredProcedure [dbo].[WIPAutoReportByWO_SSDTB1]    Script Date: 2023/03/13 10:17:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[WIPAutoReportByWO_SSDTB1] @OutPutEmailContent nvarchar(MAX)  output

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    ----------------------------------------------------------------------------------
	--Declare @Line varchar(10) = 'B16'

	---------------------------Packing uaion (Begin)----------------------------------
	Select * into #Packing From SMT_Packing with(nolock) Where /*Line = @Line AND*/ (ModelName LIKE '320SCSB%' OR ModelName LIKE '3P0SCSD%')
	UNION ALL
	Select * From SMTHistory..SMT_Packing with(nolock) Where /*Line = @Line AND*/ (ModelName LIKE '320SCSB%' OR ModelName LIKE '3P0SCSD%')
	---------------------------Packing uaion (End)----------------------------------

	---------------------------NGPacking uaion (Begin)----------------------------------	
	Select * into #NGPacking From SMT_NGPacking with(nolock) Where /*Line = @Line AND*/ (ModelName LIKE '320SCSB%' OR ModelName LIKE '3P0SCSD%')
	UNION ALL	
	Select * From SMTHistory..SMT_NGPacking with(nolock) Where /*Line = @Line AND*/ (ModelName LIKE '320SCSB%' OR ModelName LIKE '3P0SCSD%')
	---------------------------NGPacking uaion (End)----------------------------------	

	---------------------------RCTO_Packing uaion (Begin)----------------------------------	
	Select * into #RCTO_Packing From RCTO_Packing with(nolock) Where /*Line = @Line AND*/ (QCI_PN LIKE '320SCSB%' OR QCI_PN LIKE '3P0SCSD%')
	UNION ALL	
	Select * From SMTHistory..RCTO_Packing with(nolock) Where /*Line = @Line AND*/ (QCI_PN LIKE '320SCSB%' OR QCI_PN LIKE '3P0SCSD%')
	---------------------------RCTO_Packing uaion (End)----------------------------------

	---------------------------[Packing pass] column (Begin)--------------------------
	Select case when A.WorkOrder is null then B.QCI_WO else A.WorkOrder end as WorkOrder, case when A.SerialNumber is null then B.SN else A.SerialNumber end as SerialNumber into #TmpStatusByWO_Packing
	From #Packing AS A with(nolock) full outer join #RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join #NGPacking AS C with(nolock) ON A.SerialNumber = C.SerialNumber
	--From #Packing AS A with(nolock) inner join RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join SMT_NGPacking AS C with(nolock) ON A.SerialNumber = C.SerialNumber
		 --inner join SMTHistory..SMT_Packing AS D with(nolock) ON A.SerialNumber = D.SerialNumber
	Where C.SerialNumber IS NULL --AND B.Line = @Line-- AND C.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'
	order by B.QCI_WO
	---------------------------[Packing pass] column (End)--------------------------

	----------------------------[QC] column (Begin)--------------------------------- 
	--Status in SMT_SP
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO 
	From SMT_SP Where [Status] IN ('A+', 'A-', 'B+', 'B-', '*B', 'E1', '1E', 'C+', 'C-', '*C', 'D+', 'D-', 'E2', '2E', 'E+', 'E-', '*E', 'E3', '3E', 'F+', 'F-', '*F') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'QC' AND [Type] = 'P')
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

	----------------------------[Dispensing] column (Begin)-------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_Dispensing 
	From SMT_SP Where [Status] IN ('I+', 'L1', 'G1', 'G2') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'UF_LTS' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder
	----------------------------[Dispensing] column (End)-------------------------

	----------------------------[FQC] column (Begin)--------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_FQC
	From SMT_SP Where [Status] IN ('N+') --(Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'FQC' AND [Type] = 'P')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	/*UNION ALL
	Select WorkOrder, SerialNumber From SMTHistory..SMT_SP Where [Status] IN (Select Distinct [Status] From TmpStatusByWOQuery Where CodeSeq = 'FQC' AND [Type] = 'P')
	AND MFGLine = 'B16' AND TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '235959'*/
	Order by WorkOrder
	----------------------------[FQC] column (End)--------------------
	
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
	From SMT_SP Where [Status] IN ('H-', '*H', 'H<', '1H')
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

	----------------------------[UF Fail] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_UFFail
	From SMT_SP Where [Status] IN ('1G', '2G')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[UF Fail] column (End)--------------------------

	----------------------------[FQC/OQA Fail] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_FQCFail
	From SMT_SP Where [Status] IN ('O-', 'U-')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[FQC/OQA Fail] column (End)--------------------------

	----------------------------[FA-CHECK-OUT] column (Begin)--------------------------
	Select WorkOrder, SerialNumber 
	into #TmpStatusByWO_CHECKOut
	From SMT_SP Where [Status] IN ('FO')
	AND /*MFGLine = @Line AND*/ TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000'
	Order by WorkOrder
	----------------------------[FA-CHECK-OUT] column (End)--------------------------

	---------------------------[NGPacking] column (Begin)--------------------------
	Select case when A.WorkOrder is null then B.QCI_WO else A.WorkOrder end as WorkOrder, case when A.SerialNumber is null then B.SN else A.SerialNumber end as SerialNumber into #TmpStatusByWO_NGPacking
	From #NGPacking AS A with(nolock) inner join #RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join #Packing AS C with(nolock) ON A.SerialNumber = C.SerialNumber
	--From SMT_NGPacking AS A with(nolock) inner join RCTO_Packing AS B with(nolock) ON A.SerialNumber = B.SN left join SMT_Packing AS C with(nolock) ON A.SerialNumber = C.SerialNumber
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
	

	----------------------------------------------Summary table (Begin)----------------------------------------------
	Select A.Stage + ' ' + A.Config AS Config, A.Model AS QPN, A.WO, B.Qty AS [WO-Qty], B.Sap_MB_Rev AS Batch, CONVERT(VARCHAR(50), count(C.SerialNumber) - COUNT(NGPacking.SerialNumber)) AS [Packing Pass], 
		   B.Qty - ((count(C.SerialNumber) - COUNT(NGPacking.SerialNumber)) + COUNT(D.SerialNumber) + COUNT(ICT.SerialNumber) + COUNT(Dispensing.SerialNumber) + COUNT(FQC.SerialNumber) + COUNT(Packing.SerialNumber) + COUNT(QCFail.SerialNumber) + COUNT(ICTFail.SerialNumber) + COUNT(UFFail.SerialNumber) + COUNT(FQCFail.SerialNumber) + COUNT(ChkOut.SerialNumber) + COUNT(NGPacking.SerialNumber) + COUNT(Scrap.SerialNumber)) AS [No Input],
		   COUNT(D.SerialNumber) AS QC, 
		   CONVERT(VARCHAR(50), COUNT(ICT.SerialNumber)) AS ICT, CONVERT(VARCHAR(50), COUNT(Dispensing.SerialNumber)) AS Dispensing, CONVERT(VARCHAR(50), COUNT(FQC.SerialNumber)) AS FQC, 
		   CONVERT(VARCHAR(50), COUNT(Packing.SerialNumber)) AS Packing, CONVERT(VARCHAR(50), COUNT(QCFail.SerialNumber)) AS [QC Fail], CONVERT(VARCHAR(50), COUNT(ICTFail.SerialNumber)) AS [ICT Fail], 
		   CONVERT(VARCHAR(50), COUNT(UFFail.SerialNumber)) AS [UF Fail], CONVERT(VARCHAR(50), COUNT(FQCFail.SerialNumber)) AS [FQC/OQA Fail], CONVERT(VARCHAR(50), COUNT(ChkOut.SerialNumber)) AS [FA-CHECK-OUT], 
		   CONVERT(VARCHAR(50), COUNT(NGPacking.SerialNumber)) AS [NGPacking], CONVERT(VARCHAR(50), COUNT(Scrap.SerialNumber)) AS Scrap
	into #tmpTableText1
	from WO_Config AS A WITH(NOLOCK) Inner join SAP_WO_LIST AS B WITH(NOLOCK) ON  A.WO = B.WO /*Inner join SN_AOI AS SN_AOI with(nolock) ON A.WO = SN_AOI.WO */Inner join QSMS_WOGroup AS QSMS_WOGroup with(nolock) ON A.WO = QSMS_WOGroup.Work_Order
	left join SMT_SP AS SMT_SP with(nolock) ON A.WO = SMT_SP.WorkOrder
	Full outer join #TmpStatusByWO AS D with(nolock) ON A.WO = D.WorkOrder AND D.SerialNumber = SMT_SP.SerialNumber	
	Full outer join #TmpStatusByWO_ICT AS ICT with(nolock) ON A.WO = ICT.WorkOrder AND ICT.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Dispensing AS Dispensing with(nolock) ON A.WO = Dispensing.WorkOrder AND Dispensing.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_FQC AS FQC with(nolock) ON A.WO = FQC.WorkOrder AND FQC.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Packing1 AS Packing with(nolock) ON A.WO = Packing.WorkOrder AND Packing.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_QCFail AS QCFail with(nolock) ON A.WO = QCFail.WorkOrder AND QCFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_ICTFail AS ICTFail with(nolock) ON A.WO = ICTFail.WorkOrder AND ICTFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_UFFail AS UFFail with(nolock) ON A.WO = UFFail.WorkOrder AND UFFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_FQCFail AS FQCFail with(nolock) ON A.WO = FQCFail.WorkOrder AND FQCFail.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_CHECKOut AS ChkOut with(nolock) ON A.WO = ChkOut.WorkOrder AND ChkOut.SerialNumber = SMT_SP.SerialNumber	
	Full outer join #TmpStatusByWO_Scrap AS Scrap with(nolock) ON A.WO = Scrap.WorkOrder AND Scrap.SerialNumber = SMT_SP.SerialNumber
	Full outer join #TmpStatusByWO_Packing AS C With(nolock) ON A.WO = C.WorkOrder AND C.SerialNumber = SMT_SP.SerialNumber	
	Full outer join #TmpStatusByWO_NGPacking AS NGPacking with(nolock) ON A.WO = NGPacking.WorkOrder AND NGPacking.SerialNumber = SMT_SP.SerialNumber
	Where /*B.Line = @Line AND*/ SMT_SP.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000' AND B.[Status] = '20' AND QSMS_WOGroup.ClosedFlag <> 'Y' AND (B.PN LIKE '320SCSB%' OR B.PN LIKE '3P0SCSD%')
	Group by A.Stage + ' ' + A.Config, A.Model, A.WO, B.Qty, B.Sap_MB_Rev, SMT_SP.WorkOrder
	Order by A.WO
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
	
	IF exists(Select TOP 1 0 From #tmpTableText1)
	BEGIN
		--SELECT * FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText1')	--Test
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
				ELSE IF (@countColor = 7 OR @countColor = 8 OR @countColor = 9 OR @countColor = 10 OR @countColor = 11 OR @countColor = 12) 
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
									<p>Update QMB 0SC SSD '+@Stage+' Build <b>SSD WIP report at '+ convert(varchar, getdate(), 108) + ' PM on '+LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5)+' (Table 1)</b>, please help review it, thanks!</p>
									</font>'    
		set @EmailContent=@EmailContent+'<table  border=1 cellspacing=0 bordercolor=#000000    style="font-family:tahoma;Font-Size:9.6pt;width: 100%;" >'
	
		Select @EmailContent = @EmailContent + EmailContent From #TempEmailContent
		--Select * From #TempEmailContent		--TEST
		--Select @EmailContent = @EmailContent + @sql	--Test

		set @EmailContent=@EmailContent+'</table></body></html>'
		
		Select @OutPutEmailContent = @EmailContent
		Select @Stage
		--set @EmailContent=@EmailContent+'<br><br><font color=blue size=2 face="Tahoma">Best Regards,<br>QMS/AutoSendmail</font></body></html>' 

		--Select @EmailContent AS EmailContent	--Test
		--Select * From ##tmpTemplate
		Drop table ##tmpTemplate
	END

END
