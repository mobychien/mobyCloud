#
#  Set-up Credentials
#

$StartPS = get-date

import-module ActiveDirectory
$hpvhosts = 'usyp-hpv04','usyp-hpv05' 

#

$myCred = C:\Tools\dsc\ConfigurationTest\get-MyCredential.ps1 ".\Administrator" C:\Tools\dsc\ConfigurationTest\bcredit 


$myjobs = Invoke-Command -ComputerName $hpvhosts -Credential $myCred -FilePath 'C:\Tools\Hyper-V Lab Scripts\Net-Config\Config-Cluster-Net.ps1' -AsJob

Wait-Job $myjobs

#  Configure 10G Emulex nic cards


$myjobs = Invoke-Command -ComputerName $hpvhosts -Credential $myCred -ScriptBlock{
  cd 'C:\Program Files\Emulex\AutoPilot Installer\NIC\Drivers\NDIS\x64\Win2012R2\' 
  .\occfg.exe -a "SMB_vlan430" -s vlanID=430
  .\occfg.exe -a "SMB_vlan431" -s vlanID=431
 } -asjob

wait-job $myjobs

#  Join the host to the domain

$myjobs = Invoke-Command -ComputerName $hpvhosts -Credential $myCred  -ScriptBlock {
    $secString = ConvertTo-SecureString 'P@ss-w0rd' -AsPlainText -Force; 
    $myCred = New-Object -TypeName PSCredential -ArgumentList "kingstonlab\bgates", $secString ;
    Add-Computer -DomainName "kingstonlab.corp" -Credential $myCred -force ;
     } -AsJob

wait-job $myjobs

Receive-Job $myjobs

Restart-Computer -ComputerName $hpvhosts -Credential $myCred  -force -Protocol WSMAN -Wait -For Powershell 


#   Set the Local Desired State Configuration Manager to Pull Configuration Data

Set-DSCLocalConfigurationManager -ComputerName $hpvhosts -Path  C:\Tools\dsc\ConfigurationTest\LCM-HTTPSPULL –Verbose
Get-DscLocalConfigurationManager -CimSession $hpvhosts

#
$myjobs = Update-DscConfiguration -ComputerName $hpvhosts -Verbose -JobName 'UpdateDSC'

wait-job $myjobs

receive-job $myjobs

#  Reboot Hosts if 'RebootRequested' status is true


$RebootHosts = @()

$DSCStatuses = Get-DscConfigurationStatus -CimSession $hpvhosts

foreach( $DSCStatus in $DSCStatuses){

    if ($DSCStatus.RebootRequested -eq $True){
        $RebootHosts += $DSCStatus.PSComputerName
    }
}

#  We need to re-start the hosts before all the Windows Features will be applicable

Start-Sleep -Seconds 30

if($RebootHosts){
    Restart-Computer -ComputerName $RebootHosts -force -Wait -For Powershell -Protocol WSMan
}
Start-Sleep -Seconds 30

# Test-DscConfiguration -CimSession $hpvhosts

#  Check the Status of the Desired States

$ConfigStates = (Get-DscConfigurationStatus -CimSession $hpvhosts).ResourcesInDesiredState
 $ConfigStates|ft PSComputerName, ResourceID, InDesiredState -AutoSize

$endPS = get-date

($endPS - $StartPS).TotalMinutes
