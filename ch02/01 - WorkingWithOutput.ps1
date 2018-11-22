# Observe the output

# These two look like a table
Get-UICulture
Get-Process

# While these are displayed as a list
Get-TimeZone
Get-Uptime

# This returns nothing at all
Get-ChildItem -Path *DoesNotExist*

# This returns output while the verb is not Get
New-Item -Name file
