# To work with Azure, you need to install the Azure PowerShell cmdlets
Install-Module -Name Az -Scope CurrentUser

# Starting with any cmdlet will result in an error
Get-AzVm

# To work with Azure, you need to log in once
Connect-AzAccount

# If you have access to more than one subscription, you can set a default one
Set-AzContext -Subscription 'JHPaaS'

# Your subscription is now persistent by default. In a new session, try this
Get-AzComputeResourceSku | Select-Object -First 1