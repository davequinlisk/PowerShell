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
#Forward
Get-DnsServerZone -ZoneName "domain.com" | Get-DnsServerResourceRecord
Add-DnsServerResourceRecordA -Name "server101" -ZoneName "domain.com" -AllowUpdateAny -IPv4Address "172.16.0.101" -TimeToLive 01:00:00
Remove-DnsServerResourceRecord -ZoneName "domain.com" -RRType "A" -Name "server101" -RecordData "172.16.0.101"
#Reverse
Add-DnsServerPrimaryZone -NetworkId "172.16.0/24" -ReplicationScope "Forest"
Add-DnsServerResourceRecordPtr -Name "101" "0.16.172.in-addr.arpa" -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName "server101.domain.com"


#Create Users
New-ADUser -Name "Dave Q" -GivenName "Dave" -Surname "Q" -SamAccountName "dave" -UserPrincipalName "dave@domain.com" -Path "OU=Users,DC=domain,DC=com" -AccountPassword(Read-Host -AsSecureString "Type User Password") -Enabled $true

#CLI/PS File Transfer
Invoke-WebRequest -Uri "https://site.com/file.msi" -OutFile "c:\File.msi"
Start-BitsTransfer -Source "https://site.com/file.msi" -Destination "c:\File.msi"
