# Use New-Item to create a variable and view the contents
New-Item -Path variable: -Name myVariable -Value "Isn't it great?"
$myVariable

# Use Get-ChildItem with different parameters used
Get-ChildItem $home *.*
Get-ChildItem *.txt $home
Get-ChildItem -Filter *.txt -Path $home

# Use variables as arguments
$processName  = 'powershell'
Get-Process $processName
Get-Process $pid

# Using the correct parameter, the cmdlet will work
Get-Process -Id $pid

# Examine the syntax
Get-Command -Syntax -Name Get-Process
