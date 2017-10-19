################################################################
#
# Git 最新版へ更新するためのTM 初期セットアップ
# (便宜上 bitbucket.org に上げているが、事前に pull したものを実行)
#
#
################################################################
#
# InflaAgentKitが以下に配置されている前提
# \\gfs\Shares\03-1_インフラ\20_サーバ関係\10_コンテンツ用サーバ\InflaAgentKit
#
################################################################

$G_ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$DriveLetter = Split-Path $G_ScriptDir -Qualifier

# ディレクトリー構造
$G_RootPath = Join-Path $DriveLetter "\CheckEventlog2"
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_InstallerPath = Join-Path $G_RootPath "\Install"
$G_DeployFilesPath = Join-Path $G_RootPath "\DeployFiles"
$G_LogPath = Join-Path $G_RootPath "\Log"

# ファイルサーバー
if( Test-Path "\\172.27.100.103\Shares" ){
	$FileServer = "\\172.27.100.103"
}
elseif(Test-Path "\\gfs.jp.gloops.com\Shares"){
	$FileServer = "\\gfs.jp.gloops.com"
}
else{
	$FileServer = "\\gfs"
}

$SourceScriptDir = "\Shares\03-1_インフラ\20_サーバ関係\10_コンテンツ用サーバ\InflaAgentKit"
$SourcePasswordFileDir = "\InfraBackup\Credential"

$DestinationDir = $G_DeployFilesPath

# 認証
$AuthenticationDir = "C:\Authentication"


$G_LogName = "GitSetupInit"
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

	$BatchLogDir = $G_LogPath

	$Now = Get-Date

	$Log = "{0:0000}-{1:00}-{2:00} " -f $Now.Year, $Now.Month, $Now.Day
	$Log += "{0:00}:{1:00}:{2:00}.{3:000} " -f $Now.Hour, $Now.Minute, $Now.Second, $Now.Millisecond
	$Log += $LogString

	if( $G_LogName -eq $null ){
		$G_LogName = "LOG"
	}

	$LogFile = $G_LogName +"_{0:0000}-{1:00}-{2:00}.log" -f $Now.Year, $Now.Month, $Now.Day

	# ログフォルダーがなかったら作成
	if( -not (Test-Path $BatchLogDir) ) {
		New-Item $BatchLogDir -Type Directory
	}

	$LogFileName = Join-Path $BatchLogDir $LogFile

	Write-Output $Log | Out-File -FilePath $LogFileName -Encoding Default -append
	return $Log
}

################################################################
#
# Main
#
################################################################

Log "[INFO] ============== セットアップ開始 =============="
if (-not(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
	Log "実行には管理権限が必要です"
	exit
}

# ドライブ構成確認
#if( -not(Test-Path "e:\" )){
#	echo "[FAIL] E: ドライブが存在しない"
#	exit
#}

Log "[INFO] Git for Windows インストーラー"
if( -not(test-path $DestinationDir )){
	Log "[INFO] $DestinationDir 作成"
	md $DestinationDir
}

$CopyFile = $FileServer + $SourceScriptDir + "\git-*"
$RemoveFile = Join-Path $DestinationDir "\git-*"
if( test-path $CopyFile ){
	Log "[INFO] Remove File : $RemoveFile"
	del $RemoveFile
	Log "[INFO] Copy File : $CopyFile"
	copy $CopyFile $DestinationDir -Force
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

Log "[INFO] ============== セットアップ終了 =============="
