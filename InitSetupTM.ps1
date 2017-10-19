################################################################
#
# イベントログチェックを展開するためのTM 初期セットアップ
# (便宜上 bitbucket.org に上げているが、事前に pull したものを実行)
#
#  1.00 2014/11/21 S.Murashima
#
################################################################
#
# 手順
#	1.プロジェクト用のリポジトリ作成
#	2.リポジトリのSubTreeにテンプレート追加(フォルダー名:Project)
#	3.プロジェクト用設定(Project\ProjectConfig.ps1 と Project\HostRole.csv)
#	4.git commit & push
#	5.証明書インストール
#		copy \\gfs\Shares\03-1_インフラ\20_サーバ関係\10_コンテンツ用サーバ\証明書でパスワード暗号化\InstallCert.ps1
#		.\InstallCert.ps1
#	6.このスクリプト(InitSetupTM.ps1)を適当なフォルダーにコピーして実行
#	7.展開された install\SetupTM.ps1 にプロジェクトリポジトリーを設定して実行
#	8.展開された install\Deploy.ps1 実行
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

# インストールリポジトリー
$G_InitInstallRepository = "git@github.com:SyuichiMurashima/checkeventlog_install.git"

# ファイルサーバー
if( Test-Path "\\172.24.3.72\Shares" ){
	$FileServer = "\\172.24.3.72"
}
elseif(Test-Path "\\d03713-fsa.common.gloops.local\Shares"){
	$FileServer = "\\d03713-fsa.common.gloops.local"
}
else{
	$FileServer = "\\d03713-fsa"
}

$SourceScriptDir = "\Shares\03-1_インフラ\20_サーバ関係\10_コンテンツ用サーバ\InflaAgentKit"
$SourcePasswordFileDir = "\InfraBackup\Credential"

$DestinationDir = $G_DeployFilesPath

# 認証
$AuthenticationDir = "C:\Authentication"


$G_LogName = "InitSetupTM"
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

Log "[INFO] Git for Windows インストーラー + 設定ファイル コピー"
if( -not(test-path $DestinationDir )){
	Log "[INFO] $DestinationDir 作成"
	md $DestinationDir
}

$CopyFile = $FileServer + $SourceScriptDir + "\git-*"
if( test-path $CopyFile ){
	Log "[INFO] CopyFile : $CopyFile"
	copy $CopyFile $DestinationDir -Force
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

$CopyFile = $FileServer + $SourceScriptDir + "\config"
if( test-path $CopyFile ){
	Log "[INFO] CopyFile : $CopyFile"
	copy $CopyFile $DestinationDir -Force
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

$CopyFile = $FileServer + $SourceScriptDir + "\id_rsa"
if( test-path $CopyFile ){
	Log "[INFO] CopyFile : $CopyFile"
	copy $CopyFile $DestinationDir -Force
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

if( -not (Test-Path $AuthenticationDir)){
	Log "[FAIL] 証明書がインストールされていない"
	exit
}

$CopyFile = $FileServer + $SourcePasswordFileDir + "\ApLogmanager.txt"
if( test-path $CopyFile ){
	Log "[INFO] CopyFile : $CopyFile"
	copy $CopyFile $AuthenticationDir -Force
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

#--------------------
Log "[INFO] Git for Windows インストール"

$GitCommand = "C:\Program Files\Git\bin\git.exe"
if( test-path $GitCommand ){
	Log "[INFO] Git for Windows インストール 済み"
}
else{
	$InstallFileName = $DestinationDir + "\git-*"

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
			Log "[FAIL] Git for Windows インストール 失敗"
			exit
		}
	}
	else{
		Log "[FAIL] $Installer not found!!"
		exit
	}
}


#--------------------
Log "[INFO] Git 環境構築"
$sshDir = Join-Path $G_RootPath "\.ssh"

if(-not(test-path $sshDir)){
	md $sshDir
	Log "[INFO] $sshDir 作成"
}

$CopyFile = Join-Path $DestinationDir  "\config"
if(test-path $CopyFile){
	copy $CopyFile $sshDir -Force
	Log "[INFO] copy $CopyFile"
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

$CopyFile = Join-Path $DestinationDir "\id_rsa"
if(test-path $CopyFile){
	copy $CopyFile $sshDir -Force
	Log "[INFO] copy $CopyFile"
}
else{
	Log "[FAIL] $CopyFile not found!!"
	exit
}

Log "[INFO] 環境変数登録"
$env:home = $G_RootPath
$env:path += ";C:\Program Files\Git\bin"

#---------------------
Log "[INFO] インストーラー pull"
if(-not(test-path $G_InstallerPath)){
	md $G_InstallerPath
	Log "[INFO] $G_InstallerPath 作成"
}

cd $G_InstallerPath

$GitInitedChk = Join-Path $G_InstallerPath ".git"
if( -not(test-path $GitInitedChk) ){
	git init
}

git pull $G_InitInstallRepository

if( $LastExitCode -eq 0 ){
	Log "[INFO] インストーラー pull 成功"
}
else{
	Log "[FAIL] インストーラー pull 失敗"
	exit
}

Log "[INFO] ============== セットアップ終了 =============="
