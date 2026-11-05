$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop', 'DoNotVerify')
if ([string]::IsNullOrEmpty($desktop)) { exit 0 }
$oldPath = Join-Path $desktop 'Nocturne.lnk'
$newPath = Join-Path $desktop 'Fly Spy With My Little Eye.lnk'
if (!(Test-Path -LiteralPath $oldPath)) { exit 0 }
$target = Join-Path $env:LOCALAPPDATA 'Nocturne\Nocturne-Launcher.exe'
$shell = New-Object -ComObject WScript.Shell
$old = $shell.CreateShortcut($oldPath)
if ($old.TargetPath -ine $target) { exit 0 }
if (Test-Path -LiteralPath $newPath) {
    $current = $shell.CreateShortcut($newPath)
    if ($current.TargetPath -ieq $target) { Remove-Item -LiteralPath $oldPath }
} else {
    Move-Item -LiteralPath $oldPath -Destination $newPath
}
