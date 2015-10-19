#
#  Local DSC Configuration ManagerSettings FOR
#    Hyper-V Hosts using Pull Server based on Host AD Organization Unit Guid
#

[DSCLocalConfigurationManager()]
Configuration LCM_HTTPSPULL 
{     	
   param
        (
            [Parameter(Mandatory=$true)]
            [string]$ThumbPrint
        )

    Node $Allnodes.NodeName
	{
        
		Settings
		{
            AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
		    RefreshMode = 'Pull'			
			ConfigurationID = "$($Node.NodeGUID)"
            }
        ConfigurationRepositoryWeb DSCHTTPS {
           # ConfigurationNames = 'DSCHTTPS'
            ServerURL = 'https://'+$HTTPSPullServer+':8080/PSDSCPullServer.svc'
            CertificateID = $ThumbPrint
            AllowUnsecureConnection = $False
            }
	}
}

# Using ConfigurationData to Create Guid for the computers from their AD GUID
$ComputerName = 'usyp-hpv05', 'usyp-hpv04', 'usyp-hpv03', 'usyp-hpv02', 'usyp-hpv01'
$Computers = @()
 foreach ($hostnode in $computerName) {
    
    $Computers += (Get-ADComputer -Filter {name -like $hostNode})
}

# Using ConfigurationData to Create Guid for the computers from their AD GUID

$ConfigData = @{
    AllNodes = @(
        foreach ($node in $Computers) {
            @{NodeName = $node.Name;

#     Determine node GUID from its Organization Unit object Guid

            NodeGuid  = (Get-ADOrganizationalUnit -Identity ($node.DistinguishedName).Substring(($node.Name).length+4)).ObjectGUID.Guid;
             }
         }   
    )
 }


# hyBrid Cloud Management System to be Managed by DSC

$HTTPSPullServer = 'yp-dscPullSrv.kingstonlab.corp'

 $CertificatePrint = Invoke-Command -Computername $HTTPSPullServer {Get-Childitem Cert:\LocalMachine\My `
    | Where-Object {$_.FriendlyName -like "*DSCPull*"} | Select-Object -ExpandProperty ThumbPrint}


# Create the Computer.Meta.Mof in folder
LCM_HTTPSPULL -ThumbPrint $CertificatePrint -ConfigurationData $ConfigData  -OutputPath  .\LCM-HTTPSPULL

# Send to computers LCM to start DSC

$Hosts = 'usyp-hpv05'
Set-DSCLocalConfigurationManager -ComputerName $Hosts -Path  C:\Tools\dsc\ConfigurationTest\LCM-HTTPSPULL –Verbose
Get-DscLocalConfigurationManager -CimSession $Hosts

#
Update-DscConfiguration -ComputerName $Hosts -Wait -Verbose

#  We need to re-start the hosts before all the Windows Features will be applicable

Start-Sleep -Seconds 10
Restart-Computer -ComputerName $Hosts -force -Wait -For WinRM -Protocol WSMan

Test-DscConfiguration -CimSession $Hosts
Get-DscConfigurationStatus -CimSession $Hosts
