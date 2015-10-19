#
#  Set-up the Pull Server Configuration using HTTPS
#

configuration HTTPSPullServer
{
     param
        (
            [Parameter(Mandatory=$true)]
            [string]$ComputerName
        )
    
    # Modules must exist on target pull server

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

     
    Node $ComputerName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
        }

        WindowsFeature IISConsole {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   =  $CertificateID
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCComplianceServer"
            Port                    = 9080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint   = $CertificateID
            State                   = "Started"
            IsComplianceServer      = $true
            DependsOn               = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }
    }
}

$PullSrv = 'yp-dscPullSrv'

$CertificateID = Invoke-Command -Computername $PullSrv {Get-Childitem Cert:\LocalMachine\My `
    | Where-Object {$_.FriendlyName -like "*DSCPull*"} | Select-Object -ExpandProperty ThumbPrint}

# Generate MOF
HTTPSPullServer -ComputerName $PullSrv -OutputPath c:\Tools\dsc\ConfigurationTest\HTTPS
Start-DscConfiguration -Path c:\Tools\dsc\ConfigurationTest\HTTPS -ComputerName $PullSrv -Verbose -Wait
Start-Process -FilePath iexplore.exe https://yp-dscPullSrv.kingstonlab.corp:8080/PSDSCPullServer.svc
