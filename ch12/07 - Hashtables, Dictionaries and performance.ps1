#Working with cmdlets like Group-Object as well as hashtables and dictionaries
#the reader will learn when to use those structures to their advantage

# Hashtables are an important concept in PowerShell
# one reason for this is SPEED

# The index of a hashtable is the Key
$hashtable = @{ }
Get-ADUser -Filter * | ForEach-Object {$hashtable.Add($_.SamAccountName, $_)}

# Accessing an element via the index is very fast
$foundYou = $hashtable.elbarto # Total milliseconds: 0.4 !

# While looking for a value is mega-slow
$hashtable.ContainsValue($foundYou) # Total milliseconds: 21.6 !

# You already saw Group-Object with the AsHashtable parameter.
$allTheEvents = Get-WinEvent -LogName System | Group-Object -Property LevelDisplayName -AsHashTable -AsString

# Again, access is easier and more predictable
# Filtering is not necessary
$allTheEvents.Warning

# You could also group by ID, which might also be pretty useful
$allTheEvents = Get-WinEvent -LogName Security | Group-Object -Property EventID

# Despite appearances, the key is of course still not like a 0-based array index
$allTheEvents.4624