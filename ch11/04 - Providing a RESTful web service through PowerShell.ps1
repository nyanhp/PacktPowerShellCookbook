# Polaris is a powerful module you can use to host REST APIs
# the only requirement is .NET Core (.NET Standard)

# Begin by installing the module
Install-Module -Name Polaris -Scope CurrentUser

# Examine the module
Get-Command -Module Polaris

# A Get Route maps to Get-Requests
# Let's create a little event log tool
New-PolarisGetRoute -Path "/events" -Scriptblock {

    # Your routes can get parameters both in the body as well as the URL
    $logName = $request.Query["LogName"]
    if ($request.Body -and $request.Body["LogName"]) { $logName = $request.Body["LogName"]}

    $parameters = @{
        LogName = $logName
    }

    if ($null -ne $request.BodyString)
    {
        $request.Body = $request.BodyString | ConvertFrom-Json -AsHashtable
    }

    $maxEvents = $request.Query["MaxEvents"]
    if ($request.Body -and $request.Body["MaxEvents"]) { $logName = $request.Body["MaxEvents"]}

    if ($maxEvents -gt 0)
    {
        $parameters.MaxEvents = $maxEvents
    }

    if ($request.Body -and $request.Body["FilterHashtable"])
    {
        $parameters["FilterHashtable"] = [hashtable]$request.Body["FilterHashtable"]
        $parameters.Remove('LogName')
    }
    elseif ($request.Body -and $request.Body['FilterXPath'])
    {
        $parameters['FilterXPath'] = $request.Body['FilterXPath']
    }
    elseif ($request.Body -and $request.Body['FilterXml'])
    {
        $parameters['FilterXml'] = $request.Body['FilterXml']
    }
    $parameters.FilterHashtable | Out-Host
    $parameters.FilterHashtable.GetType().Fullname | Out-Host
    # JSON serialization works better with some simple properties
    $eventEntries = Get-WinEvent @parameters | Select-Object -Property LogName, ProviderName, Id, Message, @{Name = 'XmlMessage'; Expression = {$_.ToXml()}}
    $Response.Send(($eventEntries | ConvertTo-Json));
} -Force

# With Start-Polaris, your web server will be started (default: 8080)
Start-Polaris

# To get one event is now pretty simple
$restParameters = @{
    Method = 'Get'
    Uri    = 'http://localhost:8080/events?LogName=System&MaxEvents=1'
}

$eventEntry = Invoke-Restmethod @restParameters
([xml]$eventEntry.XmlMessage).Event.EventData.Data # Now also present

# Adding an XPATH filter to the request is now part of the body
$restParameters.Body = @{
    LogName     = 'System'
    FilterXPath = '*[System[EventID=6005 or EventID=6006]]'
    MaxEvents   = 10
} | ConvertTo-Json

$restParameters.ContentType = 'Application/Json'
$eventEntry = Invoke-Restmethod @restParameters

# The event entries that have been retrieved of course only possess the properties you selected.
# With the EventXml portion though, we can reconstruct the event pretty well.
$eventEntry.Event.EventData.Data

# There are countless possibilites with Polaris. You could for example provide
# a simple, read-only API to get the current deployment status during system rollout
