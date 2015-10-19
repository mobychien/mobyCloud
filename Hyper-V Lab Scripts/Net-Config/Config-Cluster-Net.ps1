#
#	Configure Hyper-V Server Cluster by
# 		Importing the CSV-file containing the NIC configuration.
#
# 	http://blogs.technet.com/b/heyscriptingguy/archive/2012/11/21/use-powershell-to-configure-the-nic-on-windows-server-2012.aspx
#

Copy-Item -Path \\172.16.167.36\hypervShares\HyperV-Configs\* -Destination c:\Tools\ -force

$NICs = Import-Csv c:\Tools\HyperV-Config0.csv| Where-Object {$_.computername -eq $env:COMPUTERNAME}

Set-NetTeredoConfiguration -Type Disabled                                  
Set-NetIsatapConfiguration -State Disabled                                  
Set-Net6to4Configuration -State Disabled

foreach ($NIC in $NICs) {
	$NetAdapter = Get-NetAdapter | Where-Object {$_.MacAddress -eq $NIC.MAC}
	if ($NetAdapter) {
		Write-Verbose "Found NIC $($NIC.NIC)"

 # Retrieving the network adapter you want to configure.

		$NetAdapter = $NetAdapter | Rename-NetAdapter -NewName $NIC.NIC -PassThru

#	Disabled IPv6 if AddressFamily is IPv4

		If ($NIC.AddressFamily -eq "IPv4"){
			Set-NetAdapterBinding -name ($NetAdapter.Name) -DisplayName "Internet Protocol Version 6 (TCP/IPv6)" -Enabled:$false
		}


 # Configuring a static IP address for the NIC, if DHCP is set to false in the CSV-file

		if ($NIC.DHCP -eq 'false') {
		Write-Verbose "Configuring TCP/IP settings for NIC $($NIC.NIC)"
			$NetAdapter = $NetAdapter | Set-NetIPInterface -DHCP Disabled -PassThru

 # Initializing empty hash table for storing NIC configuration.

			$NICAttributes = @{}

 # Adding configuration properties to hash table.

			if ($NIC.AddressFamily) {
			$NICAttributes.Add('AddressFamily',$NIC.AddressFamily)
			}

			if ($NIC.IPAddress) {
			$NICAttributes.Add('IPAddress',$NIC.IPAddress)
			}
			if ($NIC.PrefixLength) {
			$NICAttributes.Add('PrefixLength',$NIC.PrefixLength)
			}

			if ($NIC.Type) {
			$NICAttributes.Add('Type',$NIC.Type)
			}

			if ($NIC.DefaultGateway) {
			$NICAttributes.Add('DefaultGateway',$NIC.DefaultGateway)
			}

 # Configuring IP address settings by using splatting.

		$NetAdapter | New-NetIPAddress @NICAttributes

 # Configuring DNS client server address, if defined in the CSV-file.

			if ($NIC.DnsServerAddresses) {
			Set-DnsClientServerAddress -InterfaceAlias $($NIC.NIC) -ServerAddresses $NIC.DnsServerAddresses
			}
#   if ($NIC.VLAN) {
 #               Set-NetAdapter -Name $netadaptor.Name  -VlanID $NIC.VLAN
  #          }
        }

    }

}

