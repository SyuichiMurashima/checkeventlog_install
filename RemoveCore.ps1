################################################################
#
# イベントログチェックをメンバーサーバーに展開
# (RemoveCore.ps1 が Invoke-Command するスクリプト)
#
#  1.00 2014/12/04 S.Murashima
#
################################################################
param ( $ProjectRepository, $TergetDrive, $IP )

# ディレクトリー構造
$DriveLetter = $TergetDrive + ":"
$G_RootPath = Join-Path $DriveLetter "\CheckEventlog2"
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_InstallerPath = Join-Path $G_RootPath "\Install"
$G_LogPath = Join-Path $G_RootPath "\Log"

$HostName = hostname

### 戻り値
$G_FAIL = $IP + " " + $HostName + " Return FAIL"
$G_ERROR = $IP + " " + $HostName + " Return ERROR"
$G_OK = $IP + " " + $HostName + " Return OK"

$G_LogName = "RemoveMe"
##########################################################################
#
# ログ出力
#
# グローバル変数 $G_LogName にログファイル名をセットする
#
##########################################################################
function Log(
			$LogString
			){


	$Now = Get-Date

	$Log = "{0:0000}-{1:00}-{2:00} " -f $Now.Year, $Now.Month, $Now.Day
	$Log += "{0:00}:{1:00}:{2:00}.{3:000} " -f $Now.Hour, $Now.Minute, $Now.Second, $Now.Millisecond
	$Log += $LogString

	if( $G_LogName -eq $null ){
		$G_LogName = "LOG"
	}

	$LogFile = $G_LogName +"_{0:0000}-{1:00}-{2:00}.log" -f $Now.Year, $Now.Month, $Now.Day

	# ログフォルダーがなかったら作成
	if( -not (Test-Path $G_LogPath) ) {
		New-Item $G_LogPath -Type Directory
	}

	$LogFileName = Join-Path $G_LogPath $LogFile

	Write-Output $Log | Out-File -FilePath $LogFileName -Encoding Default -append
	return $Log
}

##########################################################################
# 強制終了
##########################################################################
function Abort( $Message ){
	Log $Message
	$ErrorActionPreference = "Stop"
	throw $Message
}


#################################################################################
# スケジュール削除
#################################################################################
function RemoveSchedule(
	[String]$ScheduleName
){

	$ScheduleFllName = $ScheduleName

	Log "[INFO] スケジュール : $ScheduleFllName 削除開始"

	# 実行終了しているかの確認
	$ScheduleStatus = schtasks /Query /TN $ScheduleFllName
	if($LastExitCode -ne 0){
		Log "[INFO] スケジュール : $ScheduleFllName は存在しない"
		return 0
	}

	if( -not(($ScheduleStatus[4] -match "準備完了") -or ($ScheduleStatus[4] -match "無効")) ){
		# 実行終了していなかったら 15 秒待つ
		Log "[INFO] スケジュール : $ScheduleFllName が終了していないので15秒待つ"
		sleep 15
		$ScheduleStatus = schtasks /Query /TN $ScheduleFllName
		if($LastExitCode -ne 0){
			Log "[FAIL] スケジュール : $ScheduleFllName 状態確認失敗"
			Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
			return 99
		}
		if( -not(($ScheduleStatus[4] -match "準備完了") -or ($ScheduleStatus[4] -match "無効")) ){
			Log "[FAIL] スケジュール : $ScheduleFllName 終了せず"
			Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
			return 99
		}
	}

	Log "[INFO] スケジュール : $ScheduleFllName 削除開始"
	schtasks /Delete /TN "$ScheduleFllName" /F
	if($LastExitCode -ne 0){
		Log "[FAIL] スケジュール : $ScheduleFllName 削除失敗"
		Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
		return 99
	}
	Log "[INFO] スケジュール : $ScheduleFllName 削除完了"
	return 0
}


################################################################
#
# Main
#
################################################################
Log "[INFO] ============== 開始 =============="
if( ($ProjectRepository -eq $Null) -or ($TergetDrive -eq $Null) ){
	Abort "[FAIL] 引数異常 Repository:$ProjectRepository Drive:$TergetDrive"
	exit
}

<##################################
Log "[INFO] Git for Windows インストール"

$GitCommand = "C:\Program Files\Git\bin\git.exe"
if( test-path $GitCommand ){
	Log "[INFO] Git for Windows インストール 済み"
}
else{
	$InstallFileName = $G_RootPath + "\git-*"

	$Installer = (Get-ChildItem $InstallFileName).FullName
	if( test-path $Installer ){
		. $Installer /VERYSILENT
		while((Get-Process | ? { $_.path -match "git-"}) -ne $null){
			sleep 1
		}

		if( test-path $GitCommand ){
			Log "[INFO] Git for Windows インストール 完了"
		}
		else{
			Abort "[ERROR] Git for Windows インストール 失敗"
			exit
		}
	}
	else{
		Abort "[FAIL] $Installer not found!!"
		exit
	}
}

Log "[INFO] 環境変数登録"
$env:home = $G_RootPath
$env:path += ";C:\Program Files\Git\bin"


#---------------------
Log "[INFO] 共通スクリプト pull"
###########################>

if(test-path $G_CommonPath){
	Log "[INFO] $G_CommonPath が存在していたので削除"
	del $G_CommonPath -Recurse -Force
}

<###############################
md $G_CommonPath
Log "[INFO] $G_CommonPath 作成"

cd $G_CommonPath

git init
Log "[INFO] 共通スクリプト init"

git pull "git@github.com:SyuichiMurashima/checkeventlog_core.git"
if( $LastExitCode -eq 0 ){
	Log "[INFO] 共通スクリプト pull 成功"
}
else{
	Abort "[FAIL] 共通スクリプト pull 失敗"
	exit
}

#---------------------
Log "[INFO] プロジェクトスクリプト pull"
########################>


if(test-path $G_ProjectPath){
	Log "[INFO] $G_ProjectPath が存在していたので削除"
	del $G_ProjectPath -Recurse -Force
}

<####################################
md $G_ProjectPath
Log "[INFO] $G_ProjectPath 作成"

cd $G_RootPath

$GitInitedChk = Join-Path $G_RootPath ".git"
if( test-path $GitInitedChk ){
	Log "[INFO] $GitInitedChk が存在していたので削除"
	del $GitInitedChk -Recurse -Force
}
git init
Log "[INFO] プロジェクト スクリプト init"


git pull $ProjectRepository
if( $LastExitCode -eq 0 ){
	Log "[INFO] プロジェクト スクリプト pull 成功"
}
else{
	Abort "[FAIL] プロジェクト スクリプト pull 失敗"
	exit
}


#------------------------------
Log "[INFO] Node Config 設定"
###################>

# 変数 Include
$Include = Join-Path $G_CommonPath "CommonConfig.ps1"
if( -not(Test-Path $Include)){
	Abort "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_ProjectPath "ProjectConfig.ps1"
if( -not(Test-Path $Include)){
	Abort "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

if( Test-Path $C_ServerInformation ){
	# ノード設定情報取得
	$HostName = hostname
	$Node = Import-Csv $C_ServerInformation | ? {$_.HostName -eq $HostName}
}
else{
	Abort "[FAIL] ●○●○ $C_ServerInformation not found !!●○●○"
	exit
}

if( $Node.Length -eq 0 ){
	Log "[FAIL] $HostName はヒットしなかった"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	exit
}
elseif( $Node.Length -ne $null ){
	Log "[FAIL] $HostName は重複している"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	Exit
}


$Project		= $Node.Project
$IPaddress		= $Node.IPAddress
$HostName		= $Node.HostName
$CNAME			= $Node.CNAME
$Role			= $Node.Role
$MailServer 	= $Node.MailServer
$CheckAPLogName = $Node.CheckAPLogName
$IsAPServer 	= $Node.IsAPServer

# CSV が正しいかの確認

if(( $IP -ne "127.0.0.1" ) -and ($IP -ne $IPaddress)){
	Abort "[FAIL] ●○●○ $C_ServerInformation 不整合 !! 引数:$IP  CSV:$IPaddress ●○●○"
	exit
}

Log "[INFO] Setup for $Role"

# インストール前に前回の処理開始時刻ファイルがあったら削除
if( Test-Path $C_GetTimeFile ){
	Log "[INFO] $C_GetTimeFile があったので削除"
	del $C_GetTimeFile
}

# 出力するファイル名
$NewFileName = Join-Path $G_ProjectPath "NodeConfig.ps1"

if( Test-Path $NewFileName ){
	Log "[INFO] $NewFileName があったので削除"
	del $NewFileName
}

<#####################

$OutputFile = $NewFileName
$InputFile = Join-Path $G_ProjectPath "NodeConfigORG.ps1"
if( -not (Test-Path $InputFile)){
	Abort "[FAIL] $InputFile not found !!"
	exit
}


### ノード別に文字列置き換え
# メールサーバー
$NodelData = $(Get-Content $InputFile ) -replace "#MailServer#", $MailServer

# サーバータイプ
$NodelData = $NodelData -replace "#ServerType#", $Role

# CNAME
$NodelData = $NodelData -replace "#CNAME#", $CNAME

# AppLog
if( $CheckAPLogName -ne ""){
	$LogArr = $CheckAPLogName -replace ":", "`",`""
	$CheckAPLogName = "`"" + $LogArr + "`""
}

$NodelData = $NodelData -replace "#AppLog#", $CheckAPLogName

Try{
	Write-Output $NodelData | Out-File -FilePath $OutputFile -Encoding utf8 -Force
	Log "[INFO] ノード設定ファイル($OutputFile)出力成功"
} catch [Exception] {
	Log "[FAIL] ノード設定ファイル($OutputFile)出力失敗"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	exit
}

################>

#------------------------------
Log "[INFO] イベントログチェック本体削除"
$TaskPath = $C_ScheduleDir
$TaskName = $C_CheckEventLogTaskName
$RunTime = "00:00"
$SubmitMinute = 10
$Script = Join-Path $G_CommonPath $C_CheckEventLogTaskScriptName

$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(RemoveSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Abort "[FAIL] スケジュール $TaskName 削除失敗"
	exit
}

<#############
SCHTASKS /Create /tn $FullTaskName /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc minute /mo $SubmitMinute /st $RunTime

if($LastExitCode -ne 0){
	Log "[FAIL] スケジュール : $FullTaskName 登録失敗"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	exit
}
Log "[INFO] スケジュール : $FullTaskName 登録完了"
##################>

#------------------------------
Log "[INFO] 実行ログ削除 削除"

$TaskPath = $C_ScheduleDir
$TaskName = $C_RemoveExecLogTaskName
$RunTime = "08:00"
$Script = Join-Path $G_CommonPath $C_RemoveExecLogTaskScriptName

$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(RemoveSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Abort "[FAIL] スケジュール $TaskName 削除失敗"
	exit
}

<#######################
SCHTASKS /Create /tn $FullTaskName /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc daily /st $RunTime

if($LastExitCode -ne 0){
	Log "[FAIL] スケジュール : $FullTaskName 登録失敗"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	exit
}
Log "[INFO] スケジュール : $FullTaskName 登録完了"

############>
#------------------------------
Log "[INFO] スクリプト更新 削除"
$TaskPath = $C_ScheduleDir
$TaskName = $C_UpdateTaskName
$RunTime = "04:05"
$Script = Join-Path $G_CommonPath $C_UpdateTaskScriptName

$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(RemoveSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Abort "[FAIL] スケジュール $TaskName 削除失敗"
	exit
}

<#######################
SCHTASKS /Create /tn $FullTaskName /tr "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $Script" /ru "SYSTEM" /sc daily /st $RunTime

if($LastExitCode -ne 0){
	Log "[FAIL] スケジュール : $FullTaskName 登録失敗"
	Abort "[FAIL] ●○●○ 処理異常終了 ●○●○"
	exit
}
Log "[INFO] スケジュール : $FullTaskName 登録完了"
####################>

Log "[INFO] ============== 終了 =============="
