################################################################
#
# イベントログチェックを展開するための TM セットアップ
#
#  1.00 2014/12/04 S.Murashima
#
################################################################
#
# 手順
#	1.このスクリプト(install\SetupTM.ps1) にプロジェクト リポジトリを設定して実行
#	2.メンバー展開スクリプト(install\Deploy.ps1)実行
#
################################################################

# プロジェクト リポジトリ
$G_ProjectRepository = ""


$G_ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$DriveLetter = Split-Path $G_ScriptDir -Qualifier

# ディレクトリー構造
$G_RootPath = Join-Path $DriveLetter "\CheckEventlog2"
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_InstallerPath = Join-Path $G_RootPath "\Install"
$G_DeployFilesPath = Join-Path $G_RootPath "\DeployFiles"
$G_LogPath = Join-Path $G_RootPath "\Log"

# File Server
$FileServer = "\\172.24.3.72"

# File Server アクセス アカウント
$FileServerAccessAccunt = "jp\ApLogManager"

# File Server アクセス 資格情報
$FileServerAccessCredential = "ApLogManager.txt"

# 拇印
$Thumbprint = "InfraBatch.txt"

# 資格情報ディレクトリ
$CredentialFileDir = "C:\Authentication"

# 資格情報配布元
$SourceCredentialFileDir = "\InfraBackup\Credential"




$G_LogName = "SetupTM"
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

#######################################################
# 証明書復号
#######################################################
function Encrypt(
				$ThumbprintFile,
				$PasswordFile
				){

	if( -not (test-path $PasswordFile )){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Password file " + $PasswordFile + " not found !!"
		Log $ErrorMessage
		return $null
	}

	if( -not (test-path $ThumbprintFile )){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Thumbprint file " + $ThumbprintFile + " not found !!"
		Log $ErrorMessage
		return $null
	}

	### 証明書復号のメイン処理
	# 暗号化や復号化に必要な System.Security アセンブリを読み込む
	Add-type –AssemblyName System.Security

	# 証明書の拇印(Thumbprint)の読み込み
	$Thumbprint = Get-Content $ThumbprintFile

	$CertPath = "cert:\LocalMachine\MY\" + $Thumbprint
	if(-not(test-path $CertPath)){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Certificate not found !!"
		Log $ErrorMessage
		return $null
	}

	# 証明書を取得
	$Cert = get-item $CertPath

	# 暗号化したパスワードの読み込み
	$Password = Get-Content $PasswordFile

	# Base64でエンコードされたパスワードをデコードし、証明書を使って復号化(encrypt)
	$environment = new-object Security.Cryptography.Pkcs.EnvelopedCms
	$environment.Decode([Convert]::FromBase64String( $Password ))
	$environment.Decrypt( $Cert )

	# バイト型からストリング型に変換
	$PlainPassword = [Text.Encoding]::UTF8.GetString($environment.ContentInfo.Content)

	# 平文に復号されたパスワード
	return $PlainPassword
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

Log "[INFO] 環境変数登録"
$env:home = $G_RootPath
$env:path += ";C:\Program Files\Git\bin"

$GitCommand = "C:\Program Files\Git\bin\git.exe"
if( test-path $GitCommand ){
	Log "[INFO] Git for Windows インストール OK"
}
else{
	Log "[FAIL] Git for Windows がインストールされていない"
	exit
}


#---------------------
Log "[INFO] 共通スクリプト pull"
if(-not(test-path $G_CommonPath)){
	md $G_CommonPath
	Log "[INFO] $G_CommonPath 作成"
}

cd $G_CommonPath

$GitInitedChk = Join-Path $G_CommonPath ".git"
if(-not( test-path $GitInitedChk )){
	git init
}

git pull "git@github.com:SyuichiMurashima/checkeventlog_core.git"

if( $LastExitCode -eq 0 ){
	Log "[INFO] 共通スクリプト pull 成功"
}
else{
	Log "[FAIL] 共通スクリプト pull 失敗"
	exit
}

#---------------------
Log "[INFO] プロジェクトスクリプト pull"
if(-not(test-path $G_RootPath)){
	md $G_RootPath
	Log "[INFO] $G_CommonPath 作成"
}

cd $G_RootPath

$GitInitedChk = Join-Path $G_RootPath ".git"
if( -not(test-path $GitInitedChk )){
	git init
}

git pull $G_ProjectRepository

if( $LastExitCode -eq 0 ){
	Log "[INFO] プロジェクト スクリプト pull 成功"
}
else{
	Log "[FAIL] プロジェクト スクリプト pull 失敗"
	exit
}

#---------------------
Log "[INFO] プロジェクト情報の読み込み"
$Include = Join-Path $G_CommonPath "CommonConfig.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_ProjectPath "ProjectConfig.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

Log "[INFO] 共有接続解除"
net use /delete * /yes

Log "[INFO] ファイルサーバー接続"

$CredentialFileName = Join-Path $CredentialFileDir $FileServerAccessCredential
if( -not(Test-Path $CredentialFileName) ){
	Log "[FAIL] $CredentialFileName not found!!"
	exit
}

$ThumbprintFileName = Join-Path $CredentialFileDir $Thumbprint
if(-not( Test-Path $ThumbprintFileName )){
	Log "[FAIL] $ThumbprintFileName not found!!"
	exit
}

$Credential = Encrypt $ThumbprintFileName $CredentialFileName
if( $Credential -ne $null ){
	net use $FileServer "$Credential" /user:$FileServerAccessAccunt /PERSISTENT:NO
	if( $LastExitCode -eq 0 ){
		Log "[INFO] ファイルサーバー接続 / $FileServerAccessAccunt"
	}
	else{
		Log "[FAIL] ファイルサーバー接続失敗"
		exit
	}
}
else{
	Log "[FAIL] 資格情報取得失敗"
	exit
}

$Share = Join-Path $FileServer $SourceCredentialFileDir

$ServerCredential = $C_APServerCredentialFileName
$SourceFile = Join-Path $Share $ServerCredential
if( Test-Path $SourceFile ){
	copy $SourceFile $CredentialFileDir -Force
	Log "[INFO] $ServerCredential copied"
}
else{
	Log "[FAIL] $SourceFile not found!!"
	exit
}

$ServerCredential = $C_DBServerCredentialFileName
if(($ServerCredential -ne "none") -and `
	($ServerCredential -ne "") -and `
	($ServerCredential -ne "### Edit Here ###" )){
	$SourceFile = Join-Path $Share $ServerCredential
	if( Test-Path $SourceFile ){
		copy $SourceFile $CredentialFileDir -Force
		Log "[INFO] $ServerCredential copied"
	}
	else{
		Log "[FAIL] $SourceFile not found!!"
		exit
	}
}

$ServerCredential = $C_ADServerCredentialFileName
if(($ServerCredential -ne "none") -and `
	($ServerCredential -ne "") -and `
	($ServerCredential -ne "### Edit Here ###" )){
	$SourceFile = Join-Path $Share $ServerCredential
	if( Test-Path $SourceFile ){
		copy $SourceFile $CredentialFileDir -Force
		Log "[INFO] $ServerCredential copied"
	}
	else{
		Log "[FAIL] $SourceFile not found!!"
		exit
	}
}

$ServerCredential = $C_HVServerCredentialFileName
if(($ServerCredential -ne "none") -and `
	($ServerCredential -ne "") -and `
	($ServerCredential -ne "### Edit Here ###" )){
	$SourceFile = Join-Path $Share $ServerCredential
	if( Test-Path $SourceFile ){
		copy $SourceFile $CredentialFileDir -Force
		Log "[INFO] $ServerCredential copied"
	}
	else{
		Log "[FAIL] $SourceFile not found!!"
		exit
	}
}

Log "[INFO] ============== セットアップ終了 =============="
