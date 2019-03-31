# Compute in Hyper-V can be boiled down to a few cmdlets

# Create your first VM with the disks from recipe 5
# The Generation cannot be changed afterwards.
$vm = New-VM -Name VM1 -MemoryStartupBytes 1GB -VHDPath D:\Other-VMs\OSDisks\VM1_OS.vhdx -Generation 2 -SwitchName Management

# While the VM is stopped, we can modify the resource
# This sample enables nested virtualization
$vm | Set-VMProcessor -ExposeVirtualizationExtensions $true

# If you create more than one VM, VM Groups might be interesting
New-VMGroup -Name PACKT -GroupType VMCollectionType
Add-VMGroupMember -Name PACKT -VM $vm

# You can also create nested groups
New-VMGroup -Name PACKT_MGMT -GroupType ManagementCollectionType
Add-VMGroupMember -Name PACKT_MGMT -VMGroupMember (Get-VMGroup Packt)

# Management is now easier
$group = Get-VMGroup -Name Packt
Start-VM -VM $group.VMMembers

# e.g. spawning multiple VMConnect dialogs
vmconnect.exe localhost $group.VMMembers.Name

# Clean up again
$vm | Remove-Vm -Force
Get-VMGroup -Name PACKT | Remove-VMGroup -Force
Get-VMGroup -Name PACKT_MGMT | Remove-VMGroup -Force
