�C�x���g���O�`�F�b�N

�T�v
	�ȉ����|�W�g���[���C�x���g���O�`�F�b�N�̃����o�[�ł�

		�R�A(�v���W�F�N�g����)
			CheckEventLog_Core

		�v���W�F�N�g�ˑ����e���v���[�g
			CheckEventLog_Project

		�C���X�g�[���[
			CheckEventLog_Install

		�e�v���W�F�N�g�W�J�p
			CheckEventLog_�v���W�F�N�g��

	���|�W�g���[�ɂ͈ȉ� ACL �����蓖�ĂĂ��܂�
		�C���t�� : �X�V��
		���s�A�J�E���g : �ǂݎ���p

		���s�A�J�E���g�́A�C���g�[��/�����X�V���Ƀ��|�W�g�� pull ����ۂɎg�p����A�J�E���g�ł��B
		���y�A�͍쐬�ς݂ł�(�X�N���v�g���̂��̂̃Z�L�����e�B���x���͒Ⴂ�̂Ńm���p�X���[�h�ɂȂ��Ă��܂�)


�]�����炠��@�\
	�C�x���g���O�ɃG���[�����o������w�胁�A�h�Ƀ��[����΂�(10����)
	��������G���[�ݒ�
	���s���O�L�^
	�Â����s���O�폜(1��1��)
	�W�J(�ώG)

�V�@�\
	���A�x���Ɏw��C�x���g�����o���ꂽ��w�胁�A�h�Ƀ��[����΂�
	�X�N���v�g��bitbucket�Ǘ�
	�v���W�F�N�g�ʐݒ��bitbucket�Ǘ�
	�W�J(�啝�ȕ։�)
		���J�������̃p�X���[�h�Ǘ�
	�X�N���v�g�����X�V(1��1��)
	�v���W�F�N�g�ʊǗ��@�\
		���o�C�x���g
			�x��
			���
		����w��
			�G���[��
			�x����
			���

�W�J�菇
	�v���W�F�N�g�ʃ��|�W�g���[�쐬

	�v���W�F�N�g�ʐݒ�
		�v���W�F�N�g�ʃ��|�W�g���[ pull

		Dummy.txt(size 0) ���쐬�� commit & push(���|�W�g�����̍쐬)

		�T�u�c���[�Ƀv���W�F�N�g�ʃe���v���[�g(git@bitbucket.org:gloops-system/checkeventlog_project.git)�ǉ�(���[�J�����΃p�X: Project)

		Dummy.txt ���폜(���|�W�g�����̍쐬��s�v�Ȃ̂�)

		Project\HostRole.csv�X�V
			�C�x���g���O�Ď�������T�[�o�[��o�^
				HostName
					�z�X�g��

				IPAddress
					Internal(������΃����e)

				CNAME
					CNAME

				Role
					AP Server�͔C�ӕ�����
					TM
					DB
					ADDS(�h���R��)
					Hyper-V(���)
					FileServer

				MailServer
					�g�p���郁�[���T�[�o�[

				CheckAPLogName
					����̃A�v���P�[�V�����C�x���g���O���Ď�����ꍇ�Ɏw�肷��
					�����w�肷��ꍇ�� : �ŋ�؂�

					Hyper-V
						Microsoft-Windows-Hyper-V-*

					ADDS
						DFS Replication:Directory Service:DNS Server

				IsAPServer
					AP/�o�b�`/ADMIN/TM�� "Y"

		Project\ProjectConfig.ps1�X�V
			�v���W�F�N�g���A
			�W�J��T�[�o�[���i���
			���̑��K�v�ɉ�����

		�v���W�F�N�g�ʃ��|�W�g���[ push

	TM �Z�b�g�A�b�v
		�C���X�g�[���[�Z�b�g�A�b�v
			InitSetupTM.ps1 �� TM �̔C�ӏꏊ�ɃR�s�[�����s

		�X�N���v�g�Z�b�g�A�b�v
			TM �� e:\CheckEventlog2\install\SetupTM.ps1 �Ƀv���W�F�N�g���|�W�g���[���Z�b�g�����s

	�X�N���v�g�W�J
		e:\CheckEventlog2\install\Deploy.ps1 ���s

�ڍ׏��
	�t�H���_�[�\��
		TM(�W�J��)
			E:\CheckEventlog2
				.git : Git for Windows �Ǘ��t�H���_�[(�v���W�F�N�g���)
				.ssh : Git for Windows �Ǘ��t�H���_�[(����)
				Core : ���ʃX�N���v�g
					.git : Git for Windows �Ǘ��t�H���_�[(���ʃX�N���v�g)
				Project : �v���W�F�N�g�ʐݒ�
				Log : �C���X�g�[��/���s���O
				Install : �W�J/�^�p�X�N���v�g
					.git : Git for Windows �Ǘ��t�H���_�[(�C���X�g�[���[�X�N���v�g)
				DeployFiles : �W�J�p�t�@�C��

		�����o�[(�W�J��)
			�h���C�u:\CheckEventlog2
				.git : Git for Windows �Ǘ��t�H���_�[(�v���W�F�N�g���)
				.ssh : Git for Windows �Ǘ��t�H���_�[(����)
				Core : ���ʃX�N���v�g
					.git : Git for Windows �Ǘ��t�H���_�[(���ʃX�N���v�g)
				Project : �v���W�F�N�g�ʐݒ�
				Log : �C���X�g�[��/���s���O

			AP : �h���C�u E: or D:(E:�������ꍇ)
			DB�AADDS�AHyper-V : C:

	�t�@�C��/�X�N���v�g�\��
		.ssh : Git for Windows �Ǘ��t�H���_�[(����)
			config : bitbucket�ڑ����
			id_rsa : bitbucket�ڑ���
			known_hosts : bitbucket�ڑ����(Git for Windows ����������)

		Core : ���ʃX�N���v�g
			CommonConfig.ps1 : ���ʐݒ�
			CheckEventLog.ps1 : �C�x���g���O�Ď��X�N���v�g
			RemoveExecLog.ps1 : ���s���O�폜�X�N���v�g
			UpdateScript.ps1 : �X�N���v�g�����X�V�X�N���v�g
			f_encrypt.ps1 : ���J�������n���h�����O�t�@���N�V����
			f_FomatXML.ps1 : XML ���`�t�@���N�V����
			f_Log.ps1 : ���O�o�̓t�@���N�V����
			f_SendMail.ps1 : ���[�����M�t�@���N�V����

		Project : �v���W�F�N�g�ʐݒ�
			ProjectConfig.ps1 : �v���W�F�N�g�ʐݒ�
			HostRole.csv : �T�[�o�[�\����񃊃X�g
			NodeConfig.ps1 : �m�[�h�ݒ�(�C���X�g�[���[����������)
			NodeConfigORG.ps1 : �m�[�h�ݒ�̌�

		Install : �W�J/�^�p�X�N���v�g
			InitSetupTM.ps1 : �����Z�b�g�A�b�v�X�N���v�g(Git for Windows install & installer pull)
			SetupTM.ps1 : �W�J�pTM�Z�b�g�A�b�v�X�N���v�g(Core & Project pull)
			Deploy.ps1 : �W�J�X�N���v�g
			DeployCore.ps1 : �W�J�X�N���v�g(Invoke-Command����鑤)
			StopSchdule.ps1 : �S��C�x���g���O�Ď���~
			StopCore.ps1 : �S��C�x���g���O�Ď���~(Invoke-Command����鑤)
			StartSchdule.ps1 : �S��C�x���g���O�Ď��ĊJ�X�N���v�g
			StartCore.ps1 : �S��C�x���g���O�Ď��ĊJ�X�N���v�g(Invoke-Command����鑤)

		DeployFiles : �W�J�p�t�@�C��
			Git-1.9.4-preview20140929.exe : Git for Windows �C���X�g�[���[
			config : bitbucket�ڑ����
			id_rsa : bitbucket�ڑ���

	���|�W�g���[
		���ʃX�N���v�g
			git@bitbucket.org:gloops-system/checkeventlog_core.git
			https://bitbucket.org/gloops-system/checkeventlog_core

		�v���W�F�N�g�ʃe���v���[�g
			git@bitbucket.org:gloops-system/checkeventlog_project.git
			https://bitbucket.org/gloops-system/checkeventlog_project

		�C���X�g�[���[
			git@bitbucket.org:gloops-system/checkeventlog_install.git
			https://bitbucket.org/gloops-system/checkeventlog_install

		�v���W�F�N�g�ʐݒ�
			git@bitbucket.org:gloops-system/checkeventlog_�v���W�F�N�g��.git

		Permissions
			team infrastracture : ��������
			infraagent: �ǂݎ��(�X�N���v�g���s�A�J�E���g)

