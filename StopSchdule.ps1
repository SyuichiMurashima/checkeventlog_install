##########################################################################
#
# イベントログチェック
#  全対象に対し一斉サービス停止
#
# 2014/12/09 1.00 新規作成 s.murashima
#
##########################################################################

$G_ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$DriveLetter = Split-Path $G_ScriptDir -Qualifier

# ディレクトリー構造
$G_RootPath = Join-Path $DriveLetter "\CheckEventlog2"
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_InstallerPath = Join-Path $G_RootPath "\Install"
$G_DeployFiles = Join-Path $G_RootPath "\DeployFiles"
$G_LogPath = Join-Path $G_RootPath "\Log"

# 変数 Include
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

# 処理ルーチン
$G_LogName = "Stop"
$Include = Join-Path $G_CommonPath "f_Log.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_CommonPath "f_encrypt.ps1"
if( -not(Test-Path $Include)){
	Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

### 戻り値
$G_FAIL = "Return FAIL"
$G_ERROR = "Return ERROR"
$G_OK = "Return OK"

##########################################################################
# server存在確認
##########################################################################
function IsExist( $IPAddress ){
	$Results = ping -w 1000 -n 1 $IPAddress | Out-String
	if( $Results -match "ms" ){
			Return $true
	}
	else{
		Return $false
	}
}

##########################################################################
# server存在確認(5回回す)
##########################################################################
function IsExist5Times( $IPAddress ){
	# 存在確認(5回まで ping 飛ばす)
	$i = 0
	while( $true ){
		$Rtn = @(IsExist $IPAddress)
		$State = $Rtn[$Rtn.Length - 1]
		if( $State -eq $true ){
			return $true
		}

		# 5回失敗した時
		if( $i -ge 5 ){
			return $false
		}
		$i++
	}
}


##########################################################
# main
##########################################################
Log "[INFO] ============== 処理開始 =============="
if (-not(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
	Log "実行には管理権限が必要です"
	exit
}

# ドライブ構成確認
#if( -not(Test-Path "e:\" )){
#	echo "[FAIL] E: ドライブが存在しない"
#	exit
#}

<# ------ Git チェックしない ------

Log "[INFO] 環境変数登録"
$env:home = $G_RootPath
$env:path += ";C:\Program Files\Git\bin"

# プロジェクト情報最新へ更新
Log "[INFO] プロジェクトスクリプト pull"
if(-not(test-path $G_RootPath)){
	Log "[FAIL] 環境異常 $G_RootPath が存在しない"
	exit
}

cd $G_RootPath

$GitInitedChk = Join-Path $G_RootPath ".git"
if( -not(test-path $GitInitedChk) ){
	Log "[FAIL] 環境異常 $GitInitedChk が存在しない"
	exit
}

git pull $C_ProjectRepository

if( $LastExitCode -eq 0 ){
	Log "[INFO] プロジェクト スクリプト pull 成功"
}
else{
	Log "[FAIL] プロジェクト スクリプト pull 失敗"
	exit
}

# ------ Git チェックしない ------
#>

Log "[INFO] 資格情報取得"
$APCredential = Encrypt $C_ThumbprintFile $C_APServerCredential
if( $APCredential -eq $null ){
	Log "[FAIL] AP 資格情報取得失敗"
	exit
}
$Password = ConvertTo-SecureString –String $APCredential –AsPlainText -Force
$APInvokeCredential = New-Object System.Management.Automation.PSCredential($C_APServerAccount, $Password)

$DBCredential = Encrypt $C_ThumbprintFile $C_DBServerCredential
if( $DBCredential -eq $null ){
	Log "[FAIL] DB 資格情報取得失敗"
	exit
}
$Password = ConvertTo-SecureString –String $DBCredential –AsPlainText -Force
$DBInvokeCredential = New-Object System.Management.Automation.PSCredential($C_DBServerAccount, $Password)


$TmpCredential = $C_ADServerCredential
$TmpCredentialFileName = $C_ADServerCredentialFileName
if( ( $TmpCredentialFileName -ne "" ) -and `
	( $TmpCredentialFileName -ne $Null ) -and `
	( $TmpCredentialFileName -ne "None" ) -and `
	( $TmpCredentialFileName -ne "### Edit Here ###" ) ){
	$Credential = Encrypt $C_ThumbprintFile $TmpCredential
	if( $Credential -eq $null ){
		Log "[FAIL] AD 資格情報取得失敗"
		exit
	}
	$ADCredential = $Credential

	$Password = ConvertTo-SecureString –String $ADCredential –AsPlainText -Force
	$ADInvokeCredential = New-Object System.Management.Automation.PSCredential($C_ADServerAccount, $Password)
}

$TmpCredential = $C_HVServerCredential
$TmpCredentialFileName = $C_HVServerCredentialFileName
if( ( $TmpCredentialFileName -ne "" ) -and `
	( $TmpCredentialFileName -ne $Null ) -and `
	( $TmpCredentialFileName -ne "None" ) -and `
	( $TmpCredentialFileName -ne "### Edit Here ###" ) ){
	$Credential = Encrypt $C_ThumbprintFile $TmpCredential
	if( $Credential -eq $null ){
		Log "[FAIL] Hyper-V 資格情報取得失敗"
		exit
	}
	$HVCredential = $Credential

	$Password = ConvertTo-SecureString –String $HVCredential –AsPlainText -Force
	$HVInvokeCredential = New-Object System.Management.Automation.PSCredential($C_HVServerAccount, $Password)
}

if( Test-Path $C_ServerInformation ){
	# ノード設定情報取得
	$Nodes = Import-Csv $C_ServerInformation | ? {$_.IPAddress -ne ""}
}
else{
	Log "[FAIL] ●○●○ $C_ServerInformation not found!! ●○●○"
	exit
}

foreach( $Node in $Nodes ){
	$Project		= $Node.Project
	$IPaddress		= $Node.IPAddress
	$HostName		= $Node.HostName
	$CNAME			= $Node.CNAME
	$Role			= $Node.Role
	$MailServer 	= $Node.MailServer
	$CheckAPLogName = $Node.CheckAPLogName
	$IsAPServer 	= $Node.IsAPServer

	# 戻り値の初期化
	$Return = $Null


	# CSV の整合性確認
	if( $IsAPServer -ne "" ){
		if( ($Role -eq "DB") -or `
			($Role -eq "ADDS") -or `
			($Role -eq "Hyper-V")){
			Log "[ERROR] 組み合わせ異常 $IPaddress Type AP / Role $Role"
			continue
		}
	}

	Log "[INFO] ------------ $IPaddress Schedule Stop($Role) ------------"


	$ServerName = "\\" + $IPaddress

	Log "[INFO] 接続解除"
	net use /delete * /yes

	### インストール先のドライブ決めとリモート接続
	if( $IsAPServer -ne "" ){
		$ServerCredential = $APBCredential
		$ServerAccount = $C_APServerAccount
		if( $Role -ne "TM" ){
			# AP Server

			Log "[INFO] $IPaddress の存在確認"
			$Rtn = @(IsExist5Times $IPaddress)
			$Results = $Rtn[$Rtn.Length - 1]
			if( $Results -eq $True ){
				Log "[INFO] $IPaddress は存在する"

				$ServerAccount = $C_APServerAccount
				$ServerCredential = $APCredential
				$InvokeCredential = $APInvokeCredential

				net use $ServerName "$ServerCredential" /user:$ServerAccount
				if( $LastExitCode -ne 0 ){
					Log "[FAIL] $IPaddress 接続失敗"
					exit
				}
				else{
					Log "[INFO] $IPaddress 接続"
				}

				# E: があるかの確認
				$TestDrive = Join-Path $ServerName "E$"
				if( test-path $TestDrive ){
					$TergetDriveLetter = "E"
					$TergetDrive = $TestDrive
					Log "[INFO] TergetDrive : $TergetDrive"
				}
				else{
					$TestDrive = Join-Path $ServerName "D$"
					if( test-path $TestDrive ){
						$TergetDriveLetter = "D"
						$TergetDrive = $TestDrive
						Log "[INFO] TergetDrive : $TergetDrive"
					}
					else{
						Log "[ERROR] $IPaddress は AP だが E: D: が無い"
						continue
					}
				}
			}
			else{
				Log "[ERROR] $IPaddress が存在しない"
				continue
			}
		}
		else{
			# TM
			$TergetDriveLetter = "Local"
		}
	}
	else{
		Log "[INFO] $IPaddress の存在確認"
		$Rtn = @(IsExist5Times $IPaddress)
		$Results = $Rtn[$Rtn.Length - 1]
		if( $Results -eq $True ){
			Log "[INFO] $IPaddress は存在する"
			if( $Role -EQ "DB"){
				### DB
				$ServerCredential = $DBCredential
				$ServerAccount = $C_DBServerAccount
				$InvokeCredential = $DBInvokeCredential
				Log "[INFO] Terget Server is DB"
			}
			elseif($Role -EQ "ADDS"){
				### ドメコン
				if( $ADCredential -eq $null ){
					Log "[FAIL] ドメコン用の設定が入っていない"
					exit
				}
				$ServerCredential = $ADCredential
				$ServerAccount = $C_ADServerAccount
				$InvokeCredential = $ADInvokeCredential
				Log "[INFO] Terget Server is ADDS"
			}
			elseif($Role -EQ "Hyper-V"){
				### Hyper-V
				if( $HVCredential -eq $null ){
					Log "[FAIL] Hyper-V用の設定が入っていない"
					exit
				}
				$ServerCredential = $HVCredential
				$ServerAccount = $C_HVServerAccount
				$InvokeCredential = $HVInvokeCredential
				Log "[INFO] Terget Server is ADDS"
			}
			else{
				Log "[ERROR] $IPaddress の Role 異常 : $Role"
				continue
			}
		}
		else{
			Log "[ERROR] $IPaddress が存在しない"
			continue
		}

		net use $ServerName "$ServerCredential" /user:$ServerAccount
		if( $LastExitCode -ne 0 ){
			Log "[ERROR] $IPaddress 接続失敗"
			continue
		}
		else{
			Log "[INFO] $IPaddress 接続"
		}

		$TergetDriveLetter = "C"
	}

	# インストール先
	if( $TergetDriveLetter -ne "Local" ){
		Log "[INFO] リモート($ServerName)開始"

		$SubmitScript = Join-Path $G_InstallerPath "StopCore.ps1"

		$TergetServer = $IPaddress
		$SubmitJob = Invoke-Command $TergetServer -Credential $InvokeCredential -FilePath $SubmitScript -ArgumentList $TergetDriveLetter, $TergetServer -AsJob
	}
	else{
		Log "[INFO] ローカル開始"


		$SubmitScript = Join-Path $G_InstallerPath "StopCore.ps1"
		$TergetServer = "127.0.0.1"
		$TergetDriveLetter = "E"

		$SubmitJob = Invoke-Command $TergetServer -FilePath $SubmitScript -ArgumentList $TergetDriveLetter, $TergetServer -AsJob

	}
}

Log "[INFO] +-+-+-+-+-+-+-+-+ インストールジョブ投入終了 +-+-+-+-+-+-+-+-+"

# -AsJob 投入した ジョブの状態確認
do{
	$RunningJobs = get-job | ?{ $_.State -eq "Running"}
	$CompletedJobs = get-job | ?{ $_.State -eq "Completed"}
	if( $CompletedJobs -ne $null ){
		foreach( $Job in $CompletedJobs ){
			$Location = $Job.Location
			Log "[INFO] $Location Completed"
			Remove-Job -Id $Job.Id
		}
	}
	$AllJobs = get-job
	if( $AllJobs -ne $null ){
		$Now = Get-Date
		$Message = "未処理ジョブ " + $Now
		echo $Message
		echo $AllJobs | Format-Table -Property Id,Name,State,Location -AutoSize
		echo ""
		echo ""
		echo ""
		sleep 5
	}
}
while( $RunningJobs -ne $null )

# コケたジョブ
$FailedJobs = get-job | ?{ $_.State -eq "Failed"}
if( $FailedJobs -ne $null ){
	foreach( $Job in $FailedJobs ){
		$Location = $Job.Location

		Log "[ERROR] $Location Failed"
		Log "[ERROR] ------------ $Location Log Start ------------"
		$FailLogs = Receive-Job -Id $Job.Id
		if( $FailLogs -ne $null ){
			foreach( $FailLog in $FailLogs ){
				Log $FailLog
			}
		}
		Log "[ERROR] ------------ $Location Log End ------------"
		Remove-Job -Id $Job.Id
	}
}


Log "[INFO] ============== 処理終了 =============="
