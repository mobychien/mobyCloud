[DSCLocalConfigurationManager()]
Configuration PullSrvLCM
{	
    param
        (
            [Parameter(Mandatory=$true)]
            [string]$ComputerName
        )
	Node $Computername
	{
		Settings
		{
			AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Push'	
		}
	}
}

$PullSrv = 'yp-dscPullSrv'

# Create the Computer.Meta.Mof in folder for the PullSrv

PullSrvLCM -ComputerName $PullSrv -OutputPath c:\Tools\DSC\ConfigurationTest\PullSrvPush
Set-DSCLocalConfigurationManager -ComputerName $PullSrv -Path c:\Tools\DSC\ConfigurationTest\PullSrvPush –Verbose