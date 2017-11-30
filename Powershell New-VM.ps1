#Hyper-V VM Creation
New-VM -Name "CLU2" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\CLU2.vhdx" -NewVHDSizeBytes 40000000000 -SwitchName "vSwitch-Dock-Wired"
Remove-VM -Name "NewVM"

Get-VMHardDiskDrive -VMName CLU2 | Remove-VMHardDiskDrive

Get-VMHardDiskDrive -VMName TestVM -ControllerType IDE -ControllerNumber 1 | Remove-VMHardDiskDrive

Function REMOVE-LABVM
{
param(
[string]$VMname
)
 
stop-vm -VMName $Vmname -TurnOff:$true -Confirm $False
get-vm -VMName $VMname | Get-VMHardDiskDrive | Foreach { Remove-item -path $_.Path -Recurse -Force -Confirm:$False}
Remove-VM -VMName $VMName -force
}
REMOVE-LABVM -VMname CLU2