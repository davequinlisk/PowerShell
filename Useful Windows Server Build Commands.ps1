# Configure IP Addressing
Rename-Computer VMname
shutdown /r
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "172.16.0.1" -PrefixLength 24 -DefaultGateway 172.16.0.254
Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses 172.16.0.1

#Enable Remote Desktop
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fdenyTSXonnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#Apply Windows Updates
$AvailableUpdates = Start-WUScan -SearchCriteria "IsInstalled=0 AND IsHidden=0 AND IsAssigned=1"
Write-Host "Updates found: " $AvailableUpdates.Count
Install-WUUpdates -Updates $AvailableUpdates

#Join Domain
Add-Computer -DomainName Domain.com -Credential DOMAIN\Administrator -Reboot 

#Correct IP Addressing
Remove-NetIPAddress -IPAddress 172.16.0.1

#PSRemoting Config on source machine
Set-Item wsman:\localhost\client\trustedhosts *

#Install Windows Features
Install-WindowsFeature AD-Domain-Services
Install-WindowsFeature DNS

#Configure AD DS
Install-ADDSForest
-DatabasePath “C:\Windows\NTDS”
-DomainMode “Win2012R2”
-DomainName “domain.com”
-DomainNetbiosName “DOMAIN”
-ForestMode “Win2012R2”
-InstallDns:$true
-LogPath “C:\Windows\NTDS”
-NoRebootOnCompletion:$false
-SysvolPath “C:\Windows\SYSVOL”
-Force:$true

#Configure DNS Resource Records
Get-DnsServerZone -ZoneName "domain.com" | Get-DnsServerResourceRecord
Add-DnsServerResourceRecordA -Name "vcsa01" -ZoneName "domain.com" -AllowUpdateAny -IPv4Address "172.16.0.10" -TimeToLive 01:00:00
Remove-DnsServerResourceRecord -ZoneName "domain.com" -RRType "A" -Name "vcsa01" -RecordData "172.16.0.10"
