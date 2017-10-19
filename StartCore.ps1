################################################################
#
# イベントログチェックを再開
# (DeployCore.ps1 が Invoke-Command するスクリプト)
#
#  1.00 2014/12/04 S.Murashima
#
################################################################
param ( $TergetDrive, $IP )

# ディレクトリー構造
$DriveLetter = $TergetDrive + ":"
$G_RootPath = Join-Path $DriveLetter "\CheckEventlog2"
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_InstallerPath = Join-Path $G_RootPath "\Install"
$G_LogPath = Join-Path $G_RootPath "\Log"

$Include = Join-Path $G_CommonPath "CommonConfig.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	return $G_FAIL
}
. $Include

$Include = Join-Path $G_ProjectPath "ProjectConfig.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	return $G_FAIL
}
. $Include

$G_LogName = "StartMe"
$Include = Join-Path $G_CommonPath "f_Log.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$HostName = hostname

### 戻り値
$G_FAIL = $IP + " " + $HostName + " Return FAIL"
$G_ERROR = $IP + " " + $HostName + " Return ERROR"
$G_OK = $IP + " " + $HostName + " Return OK"

#################################################################################
# スケジュール開始
#################################################################################
function StartSchedule(
	[String]$ScheduleName
){

	$ScheduleFllName = $ScheduleName

	Log "[INFO] スケジュール : $ScheduleFllName 開始"

	# 実行終了しているかの確認
	$ScheduleStatus = schtasks /Query /TN $ScheduleFllName
	if($LastExitCode -ne 0){
		Log "[FAIL] スケジュール : $ScheduleFllName は存在しない"
		return 99
	}

	if( $ScheduleStatus[4] -match "無効" ){
		Log "[INFO] スケジュール : $ScheduleFllName が無効になっている"
		Log "[INFO] スケジュール : $ScheduleFllName 開始"
		schtasks /Change /ENABLE /TN "$ScheduleFllName"
		if($LastExitCode -ne 0){
			Log "[FAIL] スケジュール : $ScheduleFllName 開始失敗"
			Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
			return 99
		}
		Log "[INFO] スケジュール : $ScheduleFllName 開始完了"
		return 0
	}
	else{
		Log "[INFO] スケジュール : $ScheduleFllName が有効になっている"
		return 0
	}
}


################################################################
#
# Main
#
################################################################
Log "[INFO] ============== 処理開始 =============="
if( $TergetDrive -eq $Null ){
	Log "[FAIL] 引数異常 Drive:$TergetDrive"
	Return $G_FAIL
}

$GitCommand = "C:\Program Files (x86)\Git\bin\git.exe"
if( test-path $GitCommand ){
	Log "[INFO] Git for Windows インストール 済み"
}
else{
	Log "[INFO] Git for Windows インストール されていない"
	Return $G_ERROR
}

Log "[INFO] 環境変数登録"
$env:home = $G_RootPath
$env:path += ";C:\Program Files (x86)\Git\bin"

#---------------------
Log "[INFO] プロジェクトスクリプト pull"
if( -not (test-path $G_ProjectPath)){
	Log "[INFO] $G_ProjectPath が存在しない"
	Return $G_ERROR
}

cd $G_RootPath

$GitInitedChk = Join-Path $G_RootPath ".git"
if( -not (test-path $GitInitedChk) ){
	Log "[INFO] $GitInitedChk が存在しない"
	Return $G_ERROR
}

git pull $C_ProjectRepository
if( $LastExitCode -eq 0 ){
	Log "[INFO] プロジェクト スクリプト pull 成功"
}
else{
	Log "[FAIL] プロジェクト スクリプト pull 失敗"
	return $G_FAIL
}


#------------------------------
Log "[INFO] Node Config 設定"

if( Test-Path $C_ServerInformation ){
	# ノード設定情報取得
	$HostName = hostname
	$Node = Import-Csv $C_ServerInformation | ? {$_.HostName -eq $HostName}
}
else{
	Log "[FAIL] ●○●○ $C_ServerInformation not found !!●○●○"
	Return $G_FAIL
}

if( $Node.Length -eq 0 ){
	Log "[FAIL] $HostName はヒットしなかった"
	Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
	Return $G_ERROR
}
elseif( $Node.Length -ne $null ){
	Log "[FAIL] $HostName は重複している"
	Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
	Return $G_ERROR
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
	Log "[FAIL] ●○●○ $C_ServerInformation 不整合 !! 引数:$IP  CSV:$IPaddress ●○●○"
	Return $G_ERROR
}

Log "[INFO] Start for $Role"

# 前回の処理開始時刻ファイルがあったら削除
if( Test-Path $C_GetTimeFile ){
	Log "[INFO] $C_GetTimeFile があったので削除"
	del $C_GetTimeFile
}

#------------------------------
Log "[INFO] イベントログチェック本体開始"
$TaskPath = $C_ScheduleDir
$TaskName = $C_CheckEventLogTaskName
$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(StartSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Log "[FAIL] スケジュール $TaskName 開始失敗"
	Return $G_ERROR
}
Log "[INFO] スケジュール : $FullTaskName 開始完了"

#------------------------------
Log "[INFO] 実行ログ削除開始"
$TaskPath = $C_ScheduleDir
$TaskName = $C_RemoveExecLogTaskName
$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(StartSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Log "[FAIL] スケジュール $TaskName 開始失敗"
	Return $G_ERROR
}
Log "[INFO] スケジュール : $FullTaskName 開始完了"

#------------------------------
Log "[INFO] スクリプト更新開始"
$TaskPath = $C_ScheduleDir
$TaskName = $C_UpdateTaskName
$FullTaskName = $TaskPath + "\" + $TaskName

$Returns = @(StartSchedule $FullTaskName)
$Return = $Returns[$Returns.Length-1]
if( $Return -ne 0 ){
	Log "[FAIL] スケジュール $TaskName 開始失敗"
	Return $G_ERROR
}

Log "[INFO] スケジュール : $FullTaskName 開始完了"

Log "[INFO] ============== 処理終了 =============="

Return $G_OK
