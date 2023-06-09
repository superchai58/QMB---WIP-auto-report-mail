USE [SMT]
GO
/****** Object:  StoredProcedure [dbo].[WIPAutoReportByWO_MLBTB2]    Script Date: 2023/03/13 10:17:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[WIPAutoReportByWO_MLBTB2] @Stage nvarchar(10), @OutPutEmailContent nvarchar(MAX)  output
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Declare @Line varchar(10) = 'B16'
	
	--Create table #tmpWONoInput (
	--	WO varchar(50),
	--	SN varchar(30)
	--)

	--Insert into #tmpWONoInput
	--exec rpt_Q_LostLabel_ALL

	-----------------------------Get data (Begin)---------------------------------- 
	Select A.WO AS WO, 
				case when SMT_SP.[Status] IN ('A+', 'A-') then 'SP' 
					when SMT_SP.[Status] IN ('B+', 'B-', '*B', 'E1', '1E') then 'SAOI01' 
					when SMT_SP.[Status] IN ('C+', 'C-', '*C') then 'SAOI02' 
					when SMT_SP.[Status] in ('D+', 'D-', 'E2', '2E') then 'SP2' 
					when SMT_SP.[Status] in ('E+', 'E-', '*E', 'E3', '3E') then 'CAOI01' 
					when SMT_SP.[Status] in ('F+', 'F-', '*F') then 'CAOI02' 
					when SMT_SP.[Status] in ('H+', 'H-', '*H', 'H<', '1H') then 'QC' 
					when SMT_SP.[Status] in ('TE', 'ET') then 'TEST28' 
					when SMT_SP.[Status] in ('I+') then 'ICT' 
					when SMT_SP.[Status] in ('L1') then 'AutoLinkMachine1' 
					when SMT_SP.[Status] in ('G1, 1G') then 'UF1' 
					when SMT_SP.[Status] in ('G2', '2G') then 'UF2' 
					when SMT_SP.[Status] in ('G3', '3G') then 'UF3' 
					when SMT_SP.[Status] in ('UB', 'BU') then 'UF_BG' 
					when SMT_SP.[Status] in ('UX', 'XU') then 'UF_LTS' 
					when SMT_SP.[Status] in ('SL') then 'SSD_Link' 
					when SMT_SP.[Status] in ('SA') then 'SSD_Laser' 
					when SMT_SP.[Status] in ('KH') then 'DFU-NAND-INIT' 
					when SMT_SP.[Status] in ('IO') then 'IO' 
					when SMT_SP.[Status] in ('KP') then 'SOC-TEST' 
					when SMT_SP.[Status] in ('P1', 'P2') then 'MP1' 
					when SMT_SP.[Status] in ('P9', '9P') then 'MP2' 
					when SMT_SP.[Status] in ('AF', 'FA') then 'AM_FAI' 
					when SMT_SP.[Status] in ('GP') then 'PhotoTaking' 
					when SMT_SP.[Status] in ('O+') then 'EOLI' 
					when SMT_SP.[Status] in ('U+') then 'OQA' 
					when SMT_SP.[Status] in ('P+') then 'Packing' 
					when SMT_SP.[Status] in ('WS') then 'SMT_Weight' 
					when SMT_SP.[Status] in ('PC') then 'PalletCheck' 
					when SMT_SP.[Status] in ('WF') then 'RCTO_WHStock' 
					when SMT_SP.[Status] in ('9S') then 'Ship' 
					when SMT_SP.[Status] in ('I-', 'I<', '*I') then 'ICT Fail' 
					when SMT_SP.[Status] in ('HK') then 'DFU-NAND-INIT Fail' 
					when SMT_SP.[Status] in ('HK') then 'DFU-NAND-INIT Fail' 
					when SMT_SP.[Status] in ('OI') then 'IO Fail' 
					when SMT_SP.[Status] in ('PK') then 'SOC-TEST Fail' 
					when SMT_SP.[Status] in ('O-') then 'EOLI  Fail' 
					when SMT_SP.[Status] in ('U-') then 'OQA Fail' 
					when SMT_SP.[Status] in ('75', 'K<', '*K', 'FO') then 'FA-CHECK-IN/OUT' 
					when SMT_SP.[Status] in ('P-') then 'NGPacking' 
					when SMT_SP.[Status] in ('SR') then 'Scrap' 
				end AS [MLB Station], COUNT(SMT_SP.SerialNumber) AS Qty
	into #GetData
	From WO_Config AS A WITH(NOLOCK) Inner join SAP_WO_LIST AS B WITH(NOLOCK) ON  A.WO = B.WO 
	Inner join SMT_SP AS SMT_SP with(nolock) ON A.WO = SMT_SP.WorkOrder
	--Inner join TmpStatusByWOQuery AS C with(nolock) ON SMT_SP.[Status] = C.[Status]
	Inner join QSMS_WOGroup AS QSMS_WOGroup with(nolock) ON A.WO = QSMS_WOGroup.Work_Order
	--Full outer join #tmpWONoInput AS D with(nolock) ON A.WO = D.WO AND D.SN = SMT_SP.SerialNumber
	Where /*B.Line = @Line AND*/ SMT_SP.TransDateTime >= FORMAT(DATEADD(MM, -1, GETDATE()), 'yyyyMMdd') + '000000' AND QSMS_WOGroup.ClosedFlag <> 'Y' AND B.PN LIKE '210SCMB%' --AND SMT_SP.[Status] IN ('A+', 'A-') 
	Group by A.WO, SMT_SP.[Status], SMT_SP.ModelName
	Order by A.WO
	-----------------------------Get data (End)---------------------------------- 

	-------------------------------Loop get station (Begin)------------------------
	--DECLARE @name VARCHAR(50) -- database name 
 
	--DECLARE db_cursor CURSOR FOR 
	--SELECT [Desc] 
	--FROM TmpStatusByWOQuery
	--Where [Type] = 'MLB_TB2'
	--Order by [No]

	--OPEN db_cursor  
	--FETCH NEXT FROM db_cursor INTO @name  

	--WHILE @@FETCH_STATUS = 0  
	--BEGIN  
	--	IF Not exists(Select [MLB Station] From #GetData where [MLB Station] = @name)
	--	BEGIN
	--		Insert into #GetData values ('', @name, 0)
	--	END

	--	FETCH NEXT FROM db_cursor INTO @name 
	--END 

	--CLOSE db_cursor  
	--DEALLOCATE db_cursor 
	-------------------------------Loop get station (End)------------------------

	IF EXISTS(Select TOP 1 0 From #GetData)
	BEGIN
		-------------------------------privotData (Begin)----------------------------
		Select B.[No], A.WO, case when A.[MLB Station] is null then B.[Desc] else A.[MLB Station] END AS [MLB Station], case when A.Qty IS null then 0 else A.Qty end AS Qty 
		into #pivotData
		From #GetData AS A with(nolock) full outer join TmpStatusByWOQuery AS B with(nolock) ON A.[MLB Station] = B.[Desc]
		Where B.[Type] = 'MLB_TB2'
		Order by B.[No]

		Declare @sql nvarchar(max) = ''
		DECLARE @cols AS NVARCHAR(MAX),
			@query  AS NVARCHAR(MAX)

		select @cols = STUFF((SELECT ',' + QUOTENAME(WO) 
							from #pivotData
							group by WO
							order by WO
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)') 
				,1,1,'')

		set @query = N'SELECT distinct [No], [MLB Station], ' + @cols + N' into [tempDB]..##tmpPivotData from 
						(
						select WO, [MLB Station], Qty, [No]
						from #pivotData
					) x
					pivot 
					(
						max(Qty)
						for WO in (' + @cols + N')
					) p '
		EXEC(@query)
		-------------------------------privotData (End)----------------------------

		--Cal summary

		IF exists(SELECT Top 1 0 FROM [tempdb].sys.columns WHERE  object_id = Object_id('[tempDB]..##tmpPivotData'))
		BEGIN
			--Drop table if exists #name
			--Get total count by data type
			SELECT Distinct name into #name FROM [tempdb].sys.columns WHERE  object_id = Object_id('[tempDB]..##tmpPivotData')
			Declare @name varchar(50) = '',@i int = 1
		
			Create table ##tmpValue (
				[No] int, [value] varchar(50)
			)

			Create table ##tmpValueSum (
				[No] int, [value] varchar(50)
			)

			--Select * From #name		--Test

			While ((Select count(name) From #name) > 0)
			BEGIN
				SELECT TOP 1 @name = name FROM #name

				IF (@i = 1)
				BEGIN
					Set @sql = '
						Insert into ##tmpValue select '+Convert(varchar(10),@i)+' AS [No], ''99'' AS value
						Insert into ##tmpValueSum select '+Convert(varchar(10),@i)+' AS [No], ''99'' AS value
					'			
					exec(@sql)
					--Select @sql AS [sql]	--Test

					--Set @i = @i+1
					--DELETE TOP (1) FROM #name
			
					--CONTINUE
				END
				ELSE IF (@i = 2)
				BEGIN
					--Set @sql = '
					--	Declare @tmpvalue' +CONVERT(varchar(10),@i)+' varchar(50) = ''''
					--	Set @tmpvalue'+CONVERT(varchar(10),@i)+' = ''WO-Qty''
					--'
					Set @sql = '
						Insert into ##tmpValue Select '+Convert(varchar(10),@i)+' AS [No], ''WO-Qty'' AS value
						Insert into ##tmpValueSum Select '+Convert(varchar(10),@i)+' AS [No], ''WO-Qty'' AS value
					'
					exec(@sql)
					--Select @sql AS [sql]	--Test
				END
				ELSE
				BEGIN
					--Set @sql = '
					--	Declare @tmpvalue' +CONVERT(varchar(10),@i)+' varchar(50) = ''''
					--	Select @tmpvalue'+CONVERT(varchar(10),@i)+' = COUNT('+@name+') From [tempDB]..##tmpPivotData
					--'

					--Insert 
					Set @sql = '
						Insert into ##tmpValue Select '+Convert(varchar(10),@i)+' AS [No], SUM(['+@name+']) AS value From [tempDB]..##tmpPivotData
						Insert into ##tmpValueSum Select '+Convert(varchar(10),@i)+' AS [No], SUM(['+@name+']) AS value From [tempDB]..##tmpPivotData
					'
					exec(@sql)

			

					--Select @sql AS [sql]	--Test
				END

				Set @i = @i+1
				DELETE TOP (1) FROM #name
			END
			--Select * From ##tmpValue		--Test
			--Insert into ##tmpPivotData
			Set @name = ''
			Set @i = 1
			Set @sql = ''

			--Insert into #name
			--SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('[tempDB]..##tmpPivotData')
			--Select @num = count(name) From #name

			--Select count([value]) From ##tmpValue		--Test

			While ((Select count([value]) From ##tmpValue) > 0)
			BEGIN
				SELECT TOP 1 @name = [value] FROM ##tmpValue

				IF (@i = 1)
				BEGIN
					Set @sql = @sql + '
						Insert into [tempDB]..##tmpPivotData values ('''+@name+'''
					'
				END
				ELSE IF ((Select count([value]) From ##tmpValue) = 1)
				BEGIN
					Set @sql = @sql + '
						, '''+@name+''')
					'
				END
				ELSE
				BEGIN
					Set @sql = @sql + '
						, '''+@name+'''
					'
				END

				Set @i = @i+1
				DELETE TOP (1) FROM ##tmpValue
			END
			--Select @sql AS [Sql]		--TEst
			exec(@sql)
		END
		----------------------Loop cal total insert WO (End)-------------------------------

		----------------------Loop Qquery by WO (Begin)-------------------------------
		IF exists(SELECT Top 1 0 FROM [tempdb].sys.columns WHERE  object_id = Object_id('[tempDB]..##tmpPivotData'))
		BEGIN
			--Drop table if exists #name
			Insert into #name
			SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('[tempDB]..##tmpPivotData')
			Set @name = ''
			Set @i = 1
			Set @sql = ''
			Declare @sqlForUpdate varchar(max) = ''
			--Declare @sum int = 0
			--Declare @WoQty int = 0

			While ((Select count(name) From #name) > 0)
			BEGIN
				SELECT TOP 1 @name = name FROM #name

				IF (@i = 1)
				BEGIN
					Set @i = @i+1
					DELETE TOP (1) FROM #name
			
					CONTINUE
				END
				ELSE IF (@i = 2)
				BEGIN
					Set @sql = @sql + '
						Select case when ['+@name+'] is null then ''0'' else ['+@name+'] end AS ['+@name+']
					'
				END
				ELSE
				BEGIN
					--------Update SumQty from SAP_WO_LIST table (Begin)-----------
					Set @sqlForUpdate = '		
						Declare @sum int = 0		
						Select @Sum = [value] From ##tmpValueSum with(nolock) Where [No] = '+CONVERT(varchar(10),@i)+'
				
						Declare @WoQty int = 0
						Select @WoQty = Qty From SAP_WO_LIST with(nolock) where WO = '''+@name+'''

						Update [tempDB]..##tmpPivotData set ['+@name+'] = @WoQty - @Sum Where [MLB Station] = ''No input''
					'
					--Select @sqlForUpdate		--Test
					EXEC(@sqlForUpdate)

					Set @sqlForUpdate = '		
						Declare @WoQty int = 0
						Select @WoQty = Qty From SAP_WO_LIST with(nolock) where WO = '''+@name+'''

						Update [tempDB]..##tmpPivotData set ['+@name+'] = @WoQty Where [MLB Station] = ''WO-Qty''
					'
					--Select @sqlForUpdate		--Test
					EXEC(@sqlForUpdate)
					--------Update SumQty from SAP_WO_LIST table (End)-----------

					Set @sql = @sql + '
						, case when ['+@name+'] is null then ''0'' else ['+@name+'] end AS ['+@name+']
					'
				END

				Set @i = @i+1
				DELETE TOP (1) FROM #name
			END
			Set @sql = @sql + '
				into ##tmpTableText2 From [tempDB]..##tmpPivotData Order by [No]
			'
			--Select @sql
			EXEC(@sql)
		END

		--Select * From ##tmpTableText2		--Test
		----------------------Loop Qquery by WO (End)-------------------------------

		---------------------Create <html> (Begin)----------------------------------
		DROP TABLE IF EXISTS ##tmpTemplate2

		Declare @tmpText1 varchar(500)
		Declare @tmpText1H varchar(500)
		Declare @tmpText2 varchar(20)
		Declare @tmpSpace varchar(20)

		Delete From #name
		--Select Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText1')		--Test
		Insert into #name
		SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText2')
		Set @i = 0

		Set @tmpText1 = '''<td style="border-left:none;border-Top:none">'''
		Set @tmpText1H = '''<td style="border-left:none;border-Top:none; font-weight: bold;padding: 5px;text-align: center;background-color: darkgray;">'''
		Set @tmpText2 = '''</td>'''
		Set @tmpSpace = '''                  '''
		Select @i = count(name) From #name

		--Header
		While ((Select count(name) From #name) > 0)
		BEGIN
			SELECT TOP 1 @name = name FROM #name

			--Last
			IF ((Select count(name) From #name) = 1)
			BEGIN
				--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
				--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
				Set @sql = @sql + ', ' + @tmpSpace + '+' + @tmpText1H + '+''' + @name + '''+' + @tmpText2 + ' AS [' + @name + '] into ##tmpTemplate2 from tempDB..##tmpTableText2'
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
			
			--Set @textTd = @textTd + '<td width=55.2 bgcolor="#FFFF99” style="border-left:none;border-Top:none;width:41.6pt">['+@name+']</td>'
			
			DELETE TOP (1) FROM #name
		END

		--Select @sql		--Test

		EXEC (@sql)
		--Select * From ##tmpTemplate		--TEST

		--Column
		Insert into #name
		SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTableText2')
		Select @i = count(name) From #name

		While ((Select count(name) From #name) > 0)
		BEGIN
			SELECT TOP 1 @name = name FROM #name

			--Last
			IF ((Select count(name) From #name) = 1)
			BEGIN
				--Set @sql = @sql + ', [' + @name +'] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
				--Set @sql = @sql + ', case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + '] /*into ##tmpTemplate*/ from tempDB..##tmpTableText1'
				Set @sql = @sql + ', ' + @tmpText1 + '+convert(varchar(50), [' + @name + '])+' + @tmpText2 + ' AS [' + @name + '] from tempDB..##tmpTableText2'
			END

			--Firt
			ELSE IF (@i = (Select count(name) From #name))
			BEGIN
				
				--Set @sql = 'select ' + @tmpText1 + 'AS [tmpText1], ' + @tmpText2 + ' AS [tmpText2], [' + @name + ']'
				--Set @sql = 'select case when ISNUMERIC([' +@name+']) = 0 then ' + @tmpText1 + '+' + 'CONVERT(varchar(50), ['+@name+'])' + '+' + @tmpText2 + ' else ' + @tmpText1 + '+[' + @name + ']+' + @tmpText2 + ' end AS [' + @name + ']'
				Set @sql = 'Insert into ##tmpTemplate2 select ' + @tmpText1 + '+convert(varchar(50), [' + @name + '])+' + @tmpText2 + ' AS [' + @name + ']'
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
		--Select * From ##tmpTemplate2		--Test
		EXEC (@sql)
		------------------------------------------------------------------

		--------------------------------------------------------------------------------------------------------------
		Create Table #TempEmailContent2(EmailContent nvarchar(max))		--Table 2
		Delete from #name
		--Select * From ##tmpTemplate		--TEST
		--Select * From #name				--TEST

		Insert into #name
		SELECT Distinct name FROM [tempdb].sys.columns WHERE  object_id = Object_id('tempDB..##tmpTemplate2')
		Set @sql = ''
		Set @sql = @sql + 'insert into #TempEmailContent2
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
			from tempDB..##tmpTemplate2
		'

		--Set @sql = @sql + '</tr>''
		--'
		--Select @sql		--Test

		--select '<tr  align=right height=21.6 style="height:16.2pt">'+[Config]+[QPN]+[WO]+[WO-Qty]+[Batch]+[Packing Pass]+[QC]+[ICT]+[UF_LTS]+[DFU]+[IO]+[SOC]+[FQC]+[Packing]+[DFU-NAND-INIT FAIL]+[IO FAIL]+[SOC-TEST FAIL]+'</tr>'     
		--from tempDB..##tmpTemplate    --TEST
		EXEC (@sql)

		--Select * From ##tmpTemplate2 --Test
		--Select @sql AS [SQL]		--TEST
		--------------------------------------------------------------------------------------------------------------
		Declare @EmailContent nvarchar(max) = ''


		Set @EmailContent='<html>
						<Body><font color=black size=3 face="Tahoma">Dear All,
								&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
								<p>Update QMB 0SC MLB '+@Stage+' Build <b>MLB WIP report at '+ convert(varchar, getdate(), 108) + ' PM on '+LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5)+' (Table 2)</b>, please help review it, thanks!</p>
								</font>'    

		Set @EmailContent = @EmailContent + '<table  border=1 cellspacing=0 bordercolor=#000000    style="font-family:tahoma;Font-Size:9.6pt;width: 100%;" >'
		Select @EmailContent = @EmailContent + EmailContent From #TempEmailContent2
		--Select * From #TempEmailContent		--TEST
		--Select @EmailContent = @EmailContent + @sql	--Test

		set @EmailContent=@EmailContent+'</table></body></html>'

		Select @OutPutEmailContent = @EmailContent

		Drop table #pivotData
		Drop table ##tmpPivotData
		Drop table #name
		Drop table ##tmpValue
		Drop table ##tmpValueSum
		Drop table ##tmpTableText2
		Drop table ##tmpTemplate2
	END
	
	Drop table #GetData
	
END
