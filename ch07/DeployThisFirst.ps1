$labName = 'chapter7'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.56.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'         = $labName
    'Add-LabMachineDefinition:DnsServer1'      = '192.168.56.9'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'          = 1gb
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
$roles = @(
    Get-LabMachineRoleDefinition -Role RootDC
    Get-LabMachineRoleDefinition -Role CaRoot @{ InstallWebEnrollment = 'Yes'; InstallWebRole = 'Yes'}
    Get-LabMachineRoleDefinition -Role Routing
)
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.56.9
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name PACKT-DC1 -Roles $roles -NetworkAdapter $netAdapter -PostInstallationActivity $postInstallActivity -DomainName contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)' -Memory 4gb
Add-LabMachineDefinition -Name PACKT-DC2 -IpAddress 192.168.56.77 -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'

#File servers, S2D
Add-LabMachineDefinition -Name PACKT-FS-A -Roles FileServer -IpAddress 192.168.56.11 -DiskName PACKT-FS-A-D, PACKT-FS-A-E, PACKT-FS-A-F -DomainName contoso.com
Add-LabMachineDefinition -Name PACKT-FS-B -Roles FileServer -IpAddress 192.168.56.18 -DiskName PACKT-FS-B-D, PACKT-FS-B-E, PACKT-FS-B-F -DomainName contoso.com
Add-LabMachineDefinition -Name PACKT-FS-C -Roles FileServer -IpAddress 192.168.56.25 -DiskName PACKT-FS-C-D, PACKT-FS-C-E, PACKT-FS-C-F -DomainName contoso.com

# Web Server to be, RDS Host
Add-LabMachineDefinition -Name PACKT-WB1 -Memory 4GB -DomainName contoso.com

# Hypervisor
Add-LabMachineDefinition -Name PACKT-HV1 -Memory 4GB -DiskName PACKT-HV1-D -DomainName contoso.com

Install-Lab

Enable-LabCertificateAutoEnrollment -Computer

New-LabCATemplate -TemplateName ContosoWebServer -DisplayName 'Web Server cert' -SourceTemplateName WebServer -ApplicationPolicy 'Server Authentication' -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName (Get-LabIssuingCa) -ErrorAction Stop

Stop-LabVm -ComputerName PACKT-HV1 -Wait
Get-Vm -VMName PACKT-HV1 | Set-VMProcessor -ExposeVirtualizationExtensions $true
Start-LabVm -ComputerName PACKT-HV1 -Wait

$pscore = Get-LabInternetFile -Uri https://github.com/PowerShell/PowerShell/releases/download/v6.1.3/PowerShell-6.1.3-win-x64.msi -PassThru -path $labsources\Tools -FileName pscore.msi -Force

Install-LabSoftwarePackage -Path $pscore.FullName -ComputerName (Get-LabVm)
Copy-LabFileItem -Path (Get-LabVm PACKT-HV1).OperatingSystem.BaseDiskPath -Destination D: -ComputerName PACKT-HV1
Save-Module -Path $labsources\Tools -Name ComputerManagementDsc,NetworkingDsc
Copy-LabFileItem -Path $labsources\Tools\ComputerManagementDsc,$labsources\Tools\NetworkingDsc -ComputerName packt-hv1 -Destination 'C:\Program Files\PowerShell\6\Modules'
Copy-LabFileItem -Path $labsources\Tools\ComputerManagementDsc,$labsources\Tools\NetworkingDsc -ComputerName packt-hv1 -Destination 'C:\Program Files\WindowsPowerShell\Modules'
Install-LabWindowsFeature -ComputerName packt-hv1 -FeatureName Hyper-V -IncludeAllSubFeature -IncludeManagementTools
Restart-LabVm -ComputerName packt-hv1

Show-LabDeploymentSummary -Detailed
