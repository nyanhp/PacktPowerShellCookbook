# Linux can create software RAID devices with mdadm.
# First of all, let's see if there is an existing configuration
mdadm --detail --scan

# Listing all available disks
lsblk -io KNAME, TYPE, SIZE, MODEL

# We can improve the output with a custom class
class BlockDevice
{
    [string] $Name
    [string] $Type
    [int64]  $Size
}

function Get-Disk
{
    lsblk -ibo KNAME, TYPE, SIZE, MODEL | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -match '(?<Name>\w+)\s+(?<Type>\w+)\s+(?<Size>[\w\d.]+)\s')
        {
            $tmp = $Matches.Clone()
            $tmp.Remove(0)
            [BlockDevice]$tmp
        }
    }
}

# If you lack partitions that can be used in the MD device, create one or two
