################################################################
#
# Git の最新版をメンバーサーバーに展開
# (DeployCore.ps1 が Invoke-Command するスクリプト)
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

$G_LogName = "GitUpdateMe"
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

################################################################
#
# Main
#
################################################################
Log "[INFO] ============== セットアップ開始 =============="
if( ($ProjectRepository -eq $Null) -or ($TergetDrive -eq $Null) ){
	Log "[FAIL] 引数異常 Repository:$ProjectRepository Drive:$TergetDrive"
	Return $G_FAIL
}

Log "[INFO] Git for Windows インストール"

$InstallFileName = $G_RootPath + "\git-*"

$Installer = (Get-ChildItem $InstallFileName).FullName
if( test-path $Installer ){
	$GitLog = Join-Path $G_LogPath "GitInstall.log"
	. $Installer /VERYSILENT /LOG=$GitLog
	while((Get-Process | ? { $_.path -match "git-"}) -ne $null){
		sleep 1
	}
}
else{
	Log "[FAIL] $Installer not found!!"
	return $G_FAIL
}

Log "[INFO] ============== セットアップ終了 =============="

Return $G_OK
