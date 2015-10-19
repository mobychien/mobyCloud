#
#  Hyper-V server HTTPS Pull Configuration
#
Configuration HyperVPullConfig {
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
        WindowsFeature SMB-Bandwidth{ #SMB Bandwidth to support RDMA
            Name = 'FS-SMBBW'            
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
import-module ActiveDirectory

#Hyper-V Cloud Management System to be Managed by DSC

$HTTPSPullServer = 'yp-dscPullsrv.kingstonlab.corp'

#
#  Organize DSC Configurations based on the OU they are in
#
$HyperVNodes = (Get-ADOrganizationalUnit -Filter "*"|?{$_.DistinguishedName -like "*OU=Servers,OU=Hyper-V POC*"}).objectGUID.Guid

HyperVPullConfig -ComputerName $HyperVNodes -OutPutPath c:\Tools\DSC\ConfigurationTest\HyperV-PullConfigs
#
#  Publish the resulting MOF to the Pull Server
#

$dest = "\\$HTTPSPullServer\c$\Program Files\WindowsPowerShell\DscService\Configuration\"
$sourceMOF = "c:\Tools\DSC\ConfigurationTest\HyperV-PullConfigs\$HyperVNodes.mof"
Copy-Item -Path $sourceMOF -Destination $dest
New-DscChecksum $dest
