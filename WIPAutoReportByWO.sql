USE [SMT]
GO
/****** Object:  StoredProcedure [dbo].[WIPAutoReportByWO]    Script Date: 2023/03/13 10:16:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

--exec WIPAutoReportByWO

ALTER PROCEDURE [dbo].[WIPAutoReportByWO] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @EmailContent nvarchar(max) = '', @Stage nvarchar(10) = ''
	create table #Stage (
		Stage nvarchar(10)
	)

	Declare @Subject varchar(100)
	--------------------MLB WIP TB1 (Begin)-----------------------
	Insert into #Stage
	exec WIPAutoReportByWO_MLBTB1 @OutPutEmailContent = @EmailContent output--, @Stage output

	Select TOP 1 @Stage = Stage From #Stage
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--Test

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB 0SC MLB '+@Stage+' Build MLB WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 1)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		@GroupTo='WIPAutoMail',
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END
	--------------------MLB WIP TB1 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------MLB WIP TB2 (Begin)-----------------------
	--Declare @EmailContent nvarchar(max) = ''		--Test
	Set @EmailContent = ''

	exec WIPAutoReportByWO_MLBTB2 @Stage, @OutPutEmailContent = @EmailContent output
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--Test

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB 0SC MLB '+@Stage+' Build MLB WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 2)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		@GroupTo='WIPAutoMail',
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END	
	--------------------MLB WIP TB2 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------SSD WIP TB1 (Begin)-----------------------
	--Declare @EmailContent nvarchar(max) = ''		--Test
	--Declare @Subject varchar(100)					--Test

	Delete From #Stage
	Set @EmailContent = ''
	Set @Stage = ''

	Insert into #Stage
	exec WIPAutoReportByWO_SSDTB1 @OutPutEmailContent = @EmailContent output
	--Select @EmailContent AS EmailContent

	Select TOP 1 @Stage = Stage From #Stage
	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB 0SC SSD '+@Stage+' Build SSD WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 1)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		@GroupTo='WIPAutoMail',
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END
	--------------------SSD WIP TB1 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------SSD WIP TB2 (Begin)-----------------------
	--Declare @EmailContent nvarchar(max) = ''		--Test
	
	Set @EmailContent = ''
	exec WIPAutoReportByWO_SSDTB2 @Stage, @OutPutEmailContent = @EmailContent output
	--Select @EmailContent AS EmailContent

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB 0SC SSD '+@Stage+' Build SSD WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 2)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		@GroupTo='WIPAutoMail',
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END	
	--------------------SSD WIP TB2 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------J43x MLB WIP TB1 (Begin)-----------------------
	Delete From #Stage
	Set @EmailContent = ''
	Set @Stage = ''

	Insert into #Stage
	exec WIPAutoReportByWO_J43_MLBTB1 @OutPutEmailContent = @EmailContent output--, @Stage output

	Select TOP 1 @Stage = Stage From #Stage
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--Test

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB J43x MLB '+@Stage+' Build MLB WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 1)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		--@MailLoopType=2,		--superchaiTest
		@GroupTo='WIPAutoMail',
		--@GroupTo='apisit.sirichoke@quantaqmb.com',		--superchaiTest
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END
	--------------------J43x MLB WIP TB1 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------J43x MLB WIP TB2 (Begin)-----------------------
	--Declare @EmailContent nvarchar(max) = ''		--Test
	Set @EmailContent = ''

	exec WIPAutoReportByWO_J43_MLBTB2 @Stage, @OutPutEmailContent = @EmailContent output
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--superchaiTest

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB J43x MLB '+@Stage+' Build MLB WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 2)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		--@MailLoopType=2,	--superchaiTest
		@GroupTo='WIPAutoMail',
		--@GroupTo='apisit.sirichoke@quantaqmb.com',		--superchaiTest
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END	
	--------------------J43x MLB WIP TB2 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------J43x Small WIP TB1 (Begin)-----------------------
	Delete From #Stage
	Set @EmailContent = ''
	Set @Stage = ''

	Insert into #Stage
	exec WIPAutoReportByWO_J43_SmallTB1 @OutPutEmailContent = @EmailContent output--, @Stage output

	Select TOP 1 @Stage = Stage From #Stage
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--Test

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB J43x Small '+@Stage+' Build Small WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 1)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		--@MailLoopType=2,		--superchaiTest
		@GroupTo='WIPAutoMail',
		--@GroupTo='apisit.sirichoke@quantaqmb.com',		--superchaiTest
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END
	--------------------J43x Small WIP TB1 (End)-----------------------

	WAITFOR DELAY '00:00:05'

	--------------------J43x Small WIP TB2 (Begin)-----------------------
	--Declare @EmailContent nvarchar(max) = ''		--Test
	Set @EmailContent = ''

	exec WIPAutoReportByWO_J43_SmallTB2 @Stage, @OutPutEmailContent = @EmailContent output
	--Select @EmailContent AS EmailContent

	--Select @EmailContent	--superchaiTest

	IF @EmailContent <> ''
	BEGIN
		Set @Subject = 'QMB J43x Small '+@Stage+' Build Small WIP report on ' +LEFT(CONVERT(VARCHAR(15), Getdate(), 103), 5) + ' (Table 2)'
		exec sp_send_dbmail_qms 
		@MailLoopType=0,
		--@MailLoopType=2,	--superchaiTest
		@GroupTo='WIPAutoMail',
		--@GroupTo='apisit.sirichoke@quantaqmb.com',		--superchaiTest
		@GroupCc='',
		@GroupBcc='',
		@Subject=@Subject,
		@Body=@EmailContent,
		@Attachment='',
		@Importance=1,
		@HtmlText=1
	END	
	--------------------J43x Small WIP TB2 (End)-----------------------

END