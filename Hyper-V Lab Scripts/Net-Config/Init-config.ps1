#
#	Initial Configuration for Windows Core
#		0. Rename Host Name
#		1. Enable PS remoting
#		2. Disable Windows Firewall on Public profile
#
	get-NetAdapter
	set-NetFirewallProfile -Name Public -enabled false
	Enable-PSRemoting -force
	
#   Create a Tool subdirectory

	new-item -path c:\Tools -itemType directory
	
	# -forceNew-smbshare -path c:\Tools -Name Tools -FullAccess Administrator
	rename-Computername
	
	#
    #   set-Netadapter -Name 'Ethernet ' -vlanID 148
    #

	copy-item -Path \\172.16.167.36\hypervShares\HyperV-Configs\*.* c:\Tools\
    cd c:\Tools

#   Install Emulex one-install OPCE14012 driver

.\OneInstall-Setup-10.4.255.26.exe /q2  NIC=1 OCM=1
	
 sconfig.cmd
 