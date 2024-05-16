# Ensure the console uses UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$topLeft = [char]::ConvertFromUtf32(0x250C)
$topRight = [char]::ConvertFromUtf32(0x2510)
$botLeft = [char]::ConvertFromUtf32(0x2514)
$botRight = [char]::ConvertFromUtf32(0x2518)
$horiz = [char]::ConvertFromUtf32(0x2500)
$vert = [char]::ConvertFromUtf32(0x2502)
function Show-SimpleMenu {
    param (
        [array]$MenuOptions,
        [string]$Title = 'Choose an option'
    )
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum # Get longest string length
    if ($maxLength -lt $Title.Length) { $maxLength = $Title.Length }
    $highlighted = 0
    $MenuTop = [Console]::CursorTop
    Do {
        [Console]::CursorTop = $MenuTop
        Write-Host "$topLeft$($Title.PadRight($maxLength,$horiz))$topRight"
        for ($i = 0; $i -lt $MenuOptions.Length; $i++) {
            Write-Host "$vert" -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -ForegroundColor Black -BackgroundColor White -NoNewLine
            } else {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -NoNewLine
            }
            Write-Host "$vert"
        }
        Write-Host "$botLeft$($horiz * ($maxLength))$botRight"
        $keycode = [Console]::ReadKey($true)
        if ($keyCode.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0) { $highlighted-- }
        if ($keycode.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length - 1) { $highlighted++ }
    } while ($keyCode.Key -ne [ConsoleKey]::Enter -and $keycode.Key -ne [ConsoleKey]::Escape)

    if ($keyCode.Key -eq [ConsoleKey]::Enter) { return $MenuOptions[$highlighted] }
}

function network {
    $ret = Show-SimpleMenu @('ip', 'temp')
    Invoke-Expression $ret
}

function ip {
    $ret = Show-SimpleMenu @('set-address', 'set-dns') -Title 'sugma'
    Invoke-Expression $ret
}

function set-address {
    $interfaces = Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty InterfaceAlias
    $interface = Show-SimpleMenu @($interfaces)

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $interface }
    $currIP = ($adapter | Get-NetIPAddress -AddressFamily IPv4).IPAddress
    $currMask = ($adapter | Get-NetIPAddress -AddressFamily IPv4).PrefixLength
    Write-Host "Current IP is $currIP/$currMask"

    $newMask = Read-Host -Prompt "Enter new subnet mask (24/16/8)"
    $newMask = [int]$newMask  # Cast to int because PowerShell is strict with types
    if ($newMask -gt 32 -or $newMask -lt 0) {
        Write-Host "Invalid network mask (0-32)" -ForegroundColor Red
        set-address
        return
    }

    $ipv4Regex = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    $newIP = Read-Host -Prompt "Enter new IPv4 address"
    if ($newIP -notmatch $ipv4Regex) {
        Write-Host "Invalid IPv4 address" -ForegroundColor Red
        set-address
        return
    }

    $oldGate = ($adapter | Get-NetIPConfiguration).IPv4DefaultGateway.NextHop
    Write-Host "To use old gateway ($oldGate) press enter"
    $newGate = Read-Host -Prompt "Enter new IPv4 gateway"
    if ([string]::IsNullOrWhiteSpace($newGate)) {
        $newGate = $oldGate
    } else {
        if ($newGate -notmatch $ipv4Regex) {
            Write-Host "Invalid IPv4 address" -ForegroundColor Red
            set-address
            return
        }
    }

    $oldDns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
    Write-Host "To use old DNS ($oldDns) press enter"
    $newDns = Read-Host -Prompt "Enter new DNS IP"
    if ([string]::IsNullOrWhiteSpace($newDns)) {
        $newDns = $oldDns
    } else {
        if ($newDns -notmatch $ipv4Regex) {
            Write-Host "Invalid IPv4 address" -ForegroundColor Red
            set-address
            return
        }
    }
    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $newDns -Validate 

    # Confirm before applying IP
    $yon = Read-Host "New IP is $newIP/$newMask confirm (y / n)"
    $yon = $yon.ToLower()
    if ($yon -eq "yes" -or $yon -eq "y") {
        if (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
            $adapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
        }
        if (($adapter | Get-NetIPConfiguration).IPv4DefaultGateway) {
            $adapter | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
        }
        New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $newIP -PrefixLength $newMask -DefaultGateway $newGate -AddressFamily IPv4
    } else {
        set-address
    }
}

function search {
    # Add the functionality for the search here
}

$initial = Show-SimpleMenu @('network', 'domain', 'reg', 'search')
Invoke-Expression $initial
