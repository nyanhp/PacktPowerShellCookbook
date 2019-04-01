# The set up of Azure Stack is time consuming. Plan a couple of hours wait

# Set up the VM on Azure, unless you have a bare-metal Hypervisor lying around
New-AzResourceGroup -Name BlauerStapel -Location 'West Europe'

1..10 | ForEach-Object {
    Write-Warning -Message "THIS VM IS VERY EXPENSIVE! DEALLOCATE IT WHEN NOT USING IT!!!"
}

$param = @{
    TemplateParameterFile = '.\ch09\Template\parameters.json'
    TemplateFile          = '.\ch09\Template\template.json'
    ResourceGroupName     = 'BlauerStapel'
    adminUserName         = 'PACKT'
    adminPassword         = 'M3g4Secure!' | ConvertTo-SecureString -AsPlainText -Force
}
New-AzResourceGroupDeployment @param

Get-AzRemoteDesktopFile -ResourceGroupName BlauerStapel -Name AZSTACK -LocalPath "$env:TEMP\AZStack.rdp" -Launch

# After the deployment, connect via Remote Desktop and start PowerShell. Execute:
Get-Disk | Where-Object PartitionStyle -eq raw | Initialize-Disk -PartitionStyle GPT
Get-Partition -DriveLetter C | Resize-Partition -Size 255GB
Invoke-WebRequest -Uri https://azurestack.azureedge.net/masdownloader-preview/1.0.3.1090/AzureStackDownloader.exe -OutFile D:\az.exe
Start-Process d:\az.exe
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}','HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name IsInstalled -Value 0

# Follow on-screen instructions. In the meantime
Add-WindowsFeature Hyper-V, Failover-Clustering, Web-Server, NetworkController, RemoteAccess -IncludeManagementTools
Add-WindowsFeature RSAT-AD-PowerShell, RSAT-ADDS -IncludeAllSubFeature
Install-PackageProvider nuget –Verbose
Rename-LocalUser -Name $env:USERNAME -NewName Administrator # yuuuup...
Stop-Service -Name RemoteAccess -Force -ErrorAction SilentlyContinue
Set-Item wsman:localhost\client\trustedhosts -Value * -Force
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
Enable-WSManCredSSP -Role Server -Force

# Do not forget to reboot before the next bit!

# When the VHD file is extracted:
$azureStackCloudBuilder = 'D:\AzureStackDevelopmentKit\CloudBuilder.vhdx'
$vhDisk = Mount-VHD -Path $azureStackCloudBuilder -Passthru
$pw = 'M3g4Secure!' | ConvertTo-SecureString -AsPlainText -Force
Robocopy.exe G:\CloudDeployment C:\CloudDeployment /MIR
Robocopy.exe G:\fwupdate C:\fwupdate /MIR
Robocopy.exe G:\tools C:\tools /MIR
$vhDisk | Dismount-VHD

# Download the scripts first
C:\CloudDeployment\Setup\BootstrapAzureStackDeployment.ps1

# Once it has finished, all the additional bits are downloaded. Execute the following to make it work
# This essentially irons out the build in errors that will cost you time.
$replaceCpu = '\(\$physicalMachine.Processors.NumberOfEnabledCores \| Measure-Object -Sum\)\.Sum'
$replaceVirt = "\(\`$Parameters.OEMModel -eq 'Hyper-V'\)"
$content = (Get-Content -Path "C:\CloudDeployment\Roles\PhysicalMachines\Tests\BareMetal.Tests.ps1") -replace $replaceCpu, 1000 -replace $replaceVirt, '$true'
$content | Set-Content -path "C:\CloudDeployment\Roles\PhysicalMachines\Tests\BareMetal.Tests.ps1" -encoding utf8
$content = Get-Content -Path 'C:\CloudDeployment\Common\Helpers.psm1'
$content = $content | ForEach-Object {if ($_ -like '*packagesavemode "nuspec"*'){$_ + " -ExcludeVersion"}else{$_}}
$content | Set-Content -Path 'C:\CloudDeployment\Common\Helpers.psm1' -encoding utf8

# When done, run
$param = @{
    AdminPassword                 = $pw
    #DNSForwarder                  = '8.8.8.8'
    TimeServer                    = '0.de.pool.ntp.org'
    InfraAzureDirectoryTenantName = 'M365x027443.onmicrosoft.com' # Generated by demos.microsoft.com
}
C:\CloudDeployment\Setup\InstallAzureStackPOC.ps1 @param

# Then wait. Get a coffee, read a good book, for example Learn PowerShell Core (David das Neves, Jan-Hendrik Peters)
# If the deployment fails, it can sadly have many reasons. If one of them is CredSSP
# Please run the following
Invoke-Command -VMName AzS-DC01 -Credential ([pscredential]::new('Administrator',$pw)) -ScriptBlock {
    Enable-WSManCredSSP -Role Server -Force
}

# If EVERYTHING is finished, your portal is accessible
start https://adminportal.local.azurestack.external/

# Now to prepare for the rest
# Download the tools archive.
cd /
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest `
  https://github.com/Azure/AzureStack-Tools/archive/master.zip `
  -OutFile master.zip

# Expand the downloaded files.
expand-archive master.zip `
  -DestinationPath . `
  -Force

# Change to the tools directory.
cd AzureStack-Tools-master

# Install AzureStack module
Install-Module AzureStack -Force

# Connect your OWN Azure account
Add-AzureRmAccount

# Register the AzureStack resource provider
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack

# Register (more details: https://docs.microsoft.com/en-us/azure/azure-stack/asdk/asdk-register)
$CloudAdminCred = [pscredential]::New('AzureStack\CloudAdmin',$pw)
$RegistrationName = "<unique-registration-name>" # Fill this in yourself!
Set-AzsRegistration -PrivilegedEndpointCredential $CloudAdminCred -PrivilegedEndpoint AzS-ERCS01 -BillingModel Development -RegistrationName $RegistrationName