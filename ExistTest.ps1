##########################################################################
#
# イベントログチェック
#  存在するサーバーだけに CSV データーを絞る
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
$G_LogName = "ExitTest"
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
Log "[INFO] ============== 開始 =============="

# 存在しているサーバ
$ExistServers = @()

$Nodes = Import-Csv $C_ServerInformation

foreach( $Node in $Nodes ){
	if( $Node.Role -eq "TM" ){
		Log "[INFO] TM は無条件 OK"
		$ExistServers += $Node
	}
	else{
		$IPaddress = $Node.IPAddress
		[array]$Rtn = IsExist5Times $IPaddress
		$State = $Rtn[$Rtn.Length - 1]
		if( $State -eq $true ){
			Log "[INFO] $IPaddress は存在する"
			$ExistServers += $Node
		}
		else{
			Log "[WARNING] $IPaddress は存在しない"
		}
	}
}

$NewServerInformation = $C_ServerInformation + ".New.Csv"

$ExistServers | Export-Csv -Path $NewServerInformation -Encoding Default

Log "[INFO] ============== 終了 =============="
