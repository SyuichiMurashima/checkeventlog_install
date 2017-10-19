イベントログチェック

概要
	以下リポジトリーがイベントログチェックのメンバーです

		コア(プロジェクト共通)
			CheckEventLog_Core

		プロジェクト依存部テンプレート
			CheckEventLog_Project

		インストーラー
			CheckEventLog_Install

		各プロジェクト展開用
			CheckEventLog_プロジェクト名

	リポジトリーには以下 ACL を割り当てています
		インフラ : 更新可
		実行アカウント : 読み取り専用

		実行アカウントは、イントール/自動更新時にリポジトリ pull する際に使用するアカウントです。
		鍵ペアは作成済みです(スクリプトそのもののセキュリティレベルは低いのでノンパスワードになっています)


従来からある機能
	イベントログにエラーを検出したら指定メアドにメール飛ばす(10分毎)
	無視するエラー設定
	実行ログ記録
	古い実行ログ削除(1日1回)
	展開(煩雑)

新機能
	情報、警告に指定イベントが検出されたら指定メアドにメール飛ばす
	スクリプトのbitbucket管理
	プロジェクト別設定のbitbucket管理
	展開(大幅簡便化)
		公開鍵方式のパスワード管理
	スクリプト自動更新(1日1回)
	プロジェクト別管理機能
		検出イベント
			警告
			情報
		宛先指定
			エラー時
			警告時
			情報時

展開手順
	プロジェクト別リポジトリー作成

	プロジェクト別設定
		プロジェクト別リポジトリー pull

		Dummy.txt(size 0) を作成し commit & push(リポジトリ実体作成)

		サブツリーにプロジェクト別テンプレート(git@bitbucket.org:gloops-system/checkeventlog_project.git)追加(ローカル相対パス: Project)

		Dummy.txt を削除(リポジトリ実体作成後不要なので)

		Project\HostRole.csv更新
			イベントログ監視をするサーバーを登録
				HostName
					ホスト名

				IPAddress
					Internal(無ければメンテ)

				CNAME
					CNAME

				Role
					AP Serverは任意文字列
					TM
					DB
					ADDS(ドメコン)
					Hyper-V(母艦)
					FileServer

				MailServer
					使用するメールサーバー

				CheckAPLogName
					特定のアプリケーションイベントログを監視する場合に指定する
					複数指定する場合は : で区切る

					Hyper-V
						Microsoft-Windows-Hyper-V-*

					ADDS
						DFS Replication:Directory Service:DNS Server

				IsAPServer
					AP/バッチ/ADMIN/TMは "Y"

		Project\ProjectConfig.ps1更新
			プロジェクト名、
			展開先サーバー資格情報
			その他必要に応じて

		プロジェクト別リポジトリー push

	TM セットアップ
		インストーラーセットアップ
			InitSetupTM.ps1 を TM の任意場所にコピーし実行

		スクリプトセットアップ
			TM の e:\CheckEventlog2\install\SetupTM.ps1 にプロジェクトリポジトリーをセットし実行

	スクリプト展開
		e:\CheckEventlog2\install\Deploy.ps1 実行

詳細情報
	フォルダー構成
		TM(展開元)
			E:\CheckEventlog2
				.git : Git for Windows 管理フォルダー(プロジェクト情報)
				.ssh : Git for Windows 管理フォルダー(鍵等)
				Core : 共通スクリプト
					.git : Git for Windows 管理フォルダー(共通スクリプト)
				Project : プロジェクト別設定
				Log : インストール/実行ログ
				Install : 展開/運用スクリプト
					.git : Git for Windows 管理フォルダー(インストーラースクリプト)
				DeployFiles : 展開用ファイル

		メンバー(展開先)
			ドライブ:\CheckEventlog2
				.git : Git for Windows 管理フォルダー(プロジェクト情報)
				.ssh : Git for Windows 管理フォルダー(鍵等)
				Core : 共通スクリプト
					.git : Git for Windows 管理フォルダー(共通スクリプト)
				Project : プロジェクト別設定
				Log : インストール/実行ログ

			AP : ドライブ E: or D:(E:が無い場合)
			DB、ADDS、Hyper-V : C:

	ファイル/スクリプト構成
		.ssh : Git for Windows 管理フォルダー(鍵等)
			config : bitbucket接続情報
			id_rsa : bitbucket接続鍵
			known_hosts : bitbucket接続情報(Git for Windows が自動生成)

		Core : 共通スクリプト
			CommonConfig.ps1 : 共通設定
			CheckEventLog.ps1 : イベントログ監視スクリプト
			RemoveExecLog.ps1 : 実行ログ削除スクリプト
			UpdateScript.ps1 : スクリプト自動更新スクリプト
			f_encrypt.ps1 : 公開鍵方式ハンドリングファンクション
			f_FomatXML.ps1 : XML 整形ファンクション
			f_Log.ps1 : ログ出力ファンクション
			f_SendMail.ps1 : メール送信ファンクション

		Project : プロジェクト別設定
			ProjectConfig.ps1 : プロジェクト別設定
			HostRole.csv : サーバー構成情報リスト
			NodeConfig.ps1 : ノード設定(インストーラーが自動生成)
			NodeConfigORG.ps1 : ノード設定の元

		Install : 展開/運用スクリプト
			InitSetupTM.ps1 : 初期セットアップスクリプト(Git for Windows install & installer pull)
			SetupTM.ps1 : 展開用TMセットアップスクリプト(Core & Project pull)
			Deploy.ps1 : 展開スクリプト
			DeployCore.ps1 : 展開スクリプト(Invoke-Commandされる側)
			StopSchdule.ps1 : 全台イベントログ監視停止
			StopCore.ps1 : 全台イベントログ監視停止(Invoke-Commandされる側)
			StartSchdule.ps1 : 全台イベントログ監視再開スクリプト
			StartCore.ps1 : 全台イベントログ監視再開スクリプト(Invoke-Commandされる側)

		DeployFiles : 展開用ファイル
			Git-1.9.4-preview20140929.exe : Git for Windows インストーラー
			config : bitbucket接続情報
			id_rsa : bitbucket接続鍵

	リポジトリー
		共通スクリプト
			git@bitbucket.org:gloops-system/checkeventlog_core.git
			https://bitbucket.org/gloops-system/checkeventlog_core

		プロジェクト別テンプレート
			git@bitbucket.org:gloops-system/checkeventlog_project.git
			https://bitbucket.org/gloops-system/checkeventlog_project

		インストーラー
			git@bitbucket.org:gloops-system/checkeventlog_install.git
			https://bitbucket.org/gloops-system/checkeventlog_install

		プロジェクト別設定
			git@bitbucket.org:gloops-system/checkeventlog_プロジェクト名.git

		Permissions
			team infrastracture : 書き込み
			infraagent: 読み取り(スクリプト実行アカウント)

