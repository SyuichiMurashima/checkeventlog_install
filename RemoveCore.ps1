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

# スケジュールフォルダー
$C_ScheduleDir = "gloops\CheckEventLog"

# イベントチェックタスク名と実行スクリプト
$C_CheckEventLogTaskName = "Check EventLog Schedule"
$C_CheckEventLogTaskScriptName = "CheckEventLog.ps1"

# 実行ログ削除登録タスク名と実行スクリプト
$C_RemoveExecLogTaskName = "Remove ExecLog Schedule"
$C_RemoveExecLogTaskScriptName = "RemoveExecLog.ps1"

# スクリプト更新登録タスク名と実行スクリプト
$C_UpdateTaskName = "Check Update"
$C_UpdateTaskScriptName = "UpdateScript.ps1"


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

if(test-path $G_RootPath){
	Log "[INFO] $G_RootPath が存在していたので削除"
	del $G_RootPath -Recurse -Force
}



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

Log "[INFO] ============== 終了 =============="
