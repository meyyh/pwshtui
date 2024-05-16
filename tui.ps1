function Show-SimpleMenu ([array]$MenuOptions, [string]$Title ='Choose an option'){
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum #get longest string length
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length}
    $highlighted = 0 
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        Write-Host "┌$($Title.PadRight($maxLength,'─'))┐" 
        for ($i = 0; $i -lt $MenuOptions.Length;$i++) {
            Write-Host "│" -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.BackgroundColor -back $host.UI.RawUI.ForegroundColor -NoNewline
            } else {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.ForegroundColor -back $host.UI.RawUI.BackgroundColor -NoNewline
            }
            Write-Host "│"
        }
        Write-Host "└$('─' * ($maxLength))┘"
        $keycode = [Console]::ReadKey($true)
        If ($keyCode.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($keycode.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length - 1) {$highlighted++}
    }While($keyCode.Key -ne [ConsoleKey]::Enter -and $keycode.Key -ne [ConsoleKey]::Escape)
    
    If($keyCode.Key -eq [ConsoleKey]::Enter){ $MenuOptions[$highlighted] }
}

function network(){
    $ret = Show-SimpleMenu @('📁ip','temp')
    Invoke-Expression $ret
}

function 📁ip(){
    $ret = Show-SimpleMenu @('set-address','set-dns') -Title sugma
    Invoke-Expression $ret
}

function set-address(){
    $interfaces = Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty InterfaceAlias
    $interface = Show-SimpleMenu @($interfaces)

    $adapter = Get-NetAdapter | Where-Object {$_.Name -eq $interface}
    $currIP = $($adapter | Get-NetIPAddress -AddressFamily IPv4).IPAddress
    $currMask = $($adapter | Get-NetIPAddress -AddressFamily IPv4).PrefixLength
    write-host "current ip is $currIP\$currMask"

    
    $newMask = Read-Host -Prompt "Enter new subnet mask 24/16/8"
    $newMask = [int]$newMask  # Cast to int because powershell is dumb
    if ($newMask -gt 32 -or $newMask -lt 0) {
        Write-Host "Ivalid network mask (0-32)" -ForegroundColor Red
        set-address
    }

    $ipv4Regex = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    $newIP = Read-Host -Prompt "Enter new ipv4 address"
    if ($newIP -notmatch $ipv4Regex) {
        Write-Host "Invalid IPv4 address" -ForegroundColor Red
        set-address
    }

    $oldGate =  $($adapter | Get-NetIPConfiguration).IPv4DefaultGateway.NextHop
    write-host "to use old gateway ($oldGate) press enter"
    $newGate = Read-Host -Prompt "Enter new ipv4 gateway"
    write-host " here is new gate $newGate"
    if ([string]::IsNullOrWhiteSpace($newGate)) {
        $newGate = $oldGate
    } else {
        if ($newGate -notmatch $ipv4Regex) {
            Write-Host "Invalid IPv4 address" -ForegroundColor Red
            set-address
        }
    }

    $oldDns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily ipv4
    write-host "to use old dns ($oldDns) press enter"
    $newDns = Read-Host -Prompt "Enter new dns ip"
    if ([string]::IsNullOrWhiteSpace($newDns)) {
        $newDns = $oldDns
    } else {
        if ($newDns -notmatch $ipv4Regex) {
            Write-Host "Invalid IPv4 address" -ForegroundColor Red
            set-address
        }
    }
    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $newDns -Validate 

    #confirm before applying ip
    $yon = $(Write-Host "new ip is $newIP\$newMask confirm (y / n)" -ForegroundColor Yellow; Read-Host)
    $yon = $yon.ToLower()
    if ($yon -eq "yes" -or $yon -eq "y"){
        If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
            $adapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
        }
        If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
            $adapter | Remove-NetRoute -AddressFamily ipv4 -Confirm:$false
        }
        New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $newIP -PrefixLength $newMask -DefaultGateway $newGate -AddressFamily ipv4
    } else {
        set-address
    }
}

function search(){

}


$inital = Show-SimpleMenu @('network','domain','reg','search')
Invoke-Expression $inital
