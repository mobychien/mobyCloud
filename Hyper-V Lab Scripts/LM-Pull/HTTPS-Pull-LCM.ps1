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
            [string[]]$ComputerName,
            [Parameter(Mandatory=$true)]
            [string]$guid,
            [Parameter(Mandatory=$true)]
            [string]$ThumbPrint
        )

    Node $ComputerName
	{
		Settings
		{
            AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
		    RefreshMode = 'Pull'			
			ConfigurationID = $GUID
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
$HostName ='is-hpv01'

#
#  Get the ObjectGUID of the AD OU where the Host belongs to
#

$HostADAcc =Get-ADComputer -Filter {name -like $HostName};
$GUID = (Get-ADOrganizationalUnit -Identity ($HostADAcc.DistinguishedName).Substring($HostName.length+4)).ObjectGUID.Guid;

# hyBrid Cloud Management System to be Managed by DSC

$HTTPSPullServer = 'is-DSCPull'

 $CertificatePrint = Invoke-Command -Computername $HTTPSPullServer {Get-Childitem Cert:\LocalMachine\My `
    | Where-Object {$_.FriendlyName -like "*DSCPull*"} | Select-Object -ExpandProperty ThumbPrint}


# Create the Computer.Meta.Mof in folder
LCM_HTTPSPULL -ComputerName $HostName -guid $GUID -ThumbPrint $CertificatePrint -OutputPath  .\LCM-HTTPSPULL


# Send to computers LCM to start DSC
Set-DSCLocalConfigurationManager -ComputerName $HostName -Path  .\LCM-HTTPSPULL –Verbose
Get-DscLocalConfigurationManager -CimSession $HostName

#
Update-DscConfiguration -ComputerName $HostName -Wait -Verbose
Test-DscConfiguration -CimSession $HostName
Get-DscConfigurationStatus -CimSession $HostName
