# In order to connect to Google, you need to install the GoogleCloud module and the SDK
Install-ChocolateyPackage -Name gcloudsdk # Or download the installer from https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
Install-Module -Name GoogleCloud -Scope CurrentUser

# Like with Azure, you need to authenticate before trying anything
Get-GcpProject

# You can authenticate with the Google Cloud SDK
gcloud init

# Now it is possible to retrieve data, for example your project's buckets
Get-GcsBucket