
[DSCLocalConfigurationManager()]
Configuration LCMPUSH 
{	param
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
            #RebootNodeIfNeeded = $True	
		}
	}
}

$HypverVHost = 'is-hpv01'
# Create the Computer.Meta.Mof in folder
LCMPush -ComputerName $HypverVHost -OutputPath c:\Tools\DSC\ConfigurationTest\LCM
Set-DSCLocalConfigurationManager -ComputerName $HypverVHost -Path c:\Tools\DSC\ConfigurationTest\LCM –Verbose
#
#  Configuration for Hyper-V server
#
Configuration HyperVConfig {
    param
        (
            [Parameter(Mandatory=$true)]
            [string]$ComputerName
        )

    Node $ComputerName {

        WindowsFeature MPIO{ #MultitiPath
            Name = 'Multipath-IO'            
            Ensure = 'Present'
        }
        WindowsFeature FO-Cluster{  # Install Fail-over Clustering
            Name = 'Failover-Clustering'        
            Ensure = 'Present'
        }
        WindowsFeature RSAT-Cluster{  # Install Fail-over Clustering PowerShell
            Name = 'RSAT-Clustering-PowerShell'        
            Ensure = 'Present'
        }
        WindowsFeature HyperV{ # Hyper-V
            Name = 'Hyper-V'
            includeAllSubFeature = $True
            Ensure = 'Present'
        }
    }
}
HyperVConfig -ComputerName $HypverVHost -OutPutPath c:\Tools\DSC\ConfigurationTest\LCMPUSH
Start-DscConfiguration -Path c:\Tools\DSC\ConfigurationTest\LCMPUSH -ComputerName $HypverVHost -Verbose -Wait
$DSCstatus = (Get-DscConfigurationStatus -CimSession $HypverVHost) 
If(($DSCstatus.status -eq "success") -and ($DSCstatus.RebootRequested -eq $True)) {restart-computer -ComputerName $DSCstatus.PSComputerName -FORCE}