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
    }While($keyCode.Key -ne [ConsoleKey]::Enter -and $keycode.Key -ne [ConsoleKey]::Escape )
    If($keyCode.Key -eq [ConsoleKey]::Enter){ &$MenuOptions[$highlighted] }
}

function network(){
    Write-Host "hi mum"
}

Show-SimpleMenu @('network','domain','reg')

