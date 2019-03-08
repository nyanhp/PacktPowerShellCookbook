$labName = 'DFSBootcamp'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.56.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'         = $labName
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1'      = '192.168.56.9'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'          = 512mb
}

Add-LabDiskDefinition -Name PACKT-FS-A-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-D -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-A-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-E -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-A-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-B-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-FS-C-F -DiskSizeInGb 5 -SkipInitialize
Add-LabDiskDefinition -Name PACKT-HV1-D -DiskSizeInGb 50

#Domain Controller
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008'; ForestFunctionalLevel = 'Win2008' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name PACKT-DC1 -Roles $roles -IpAddress 192.168.56.9 -PostInstallationActivity $postInstallActivity
Add-LabMachineDefinition -Name PACKT-DC2 -IpAddress 192.168.56.77

#File servers, S2D
Add-LabMachineDefinition -Name PACKT-FS-A -Roles FileServer -IpAddress 192.168.56.11 -DiskName PACKT-FS-A-D, PACKT-FS-A-E, PACKT-FS-A-F
Add-LabMachineDefinition -Name PACKT-FS-B -Roles FileServer -IpAddress 192.168.56.18 -DiskName PACKT-FS-B-D, PACKT-FS-B-E, PACKT-FS-B-F
Add-LabMachineDefinition -Name PACKT-FS-C -Roles FileServer -IpAddress 192.168.56.25 -DiskName PACKT-FS-C-D, PACKT-FS-C-E, PACKT-FS-C-F

# Web Server to be, RDS Host
Add-LabMachineDefinition -Name PACKT-WB1 -Memory 4GB

# Hypervisor
Add-LabMachineDefinition -Name PACKT-HV1 -Memory 4GB -DiskName PACKT-HV1-D


Install-Lab