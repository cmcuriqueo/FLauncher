$ErrorActionPreference = "Stop"

$configPath = $env:TV_AVD_CONFIG
$skinPath = $env:TV_SKIN

if ([string]::IsNullOrWhiteSpace($configPath) -or -not (Test-Path -LiteralPath $configPath)) {
    throw "No existe la configuracion del AVD: $configPath"
}
if ([string]::IsNullOrWhiteSpace($skinPath) -or -not (Test-Path -LiteralPath (Join-Path $skinPath "layout"))) {
    throw "No existe el skin Android TV: $skinPath"
}

$lines = [System.IO.File]::ReadAllLines($configPath)
$text = $lines -join "`n"
if ($text -notmatch '(?m)^\s*tag\.id\s*=\s*android-tv\s*$' -or $text -notmatch 'system-images[\\/]android-\d+[\\/]android-tv[\\/]') {
    throw "El AVD no es Android TV. Borrarlo y volver a correr el script."
}

$updates = [ordered]@{
    "hw.initialOrientation" = "landscape"
    "hw.dPad"               = "yes"
    "hw.keyboard"           = "yes"
    "hw.keyboard.lid"       = "yes"
    "hw.mainKeys"           = "yes"
    "hw.screen"             = "no-touch"
    "hw.gpu.enabled"        = "yes"
    "hw.gpu.mode"           = "host"
    "hw.lcd.width"          = "1920"
    "hw.lcd.height"         = "1080"
    "skin.name"             = "tv_1080p"
    "skin.path"             = $skinPath
    "skin.dynamic"          = "yes"
    "showDeviceFrame"       = "yes"
}

$set = @{}
$out = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    if ($line -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
        $key = $Matches[1].Trim()
        if ($updates.Contains($key)) {
            $set[$key] = $true
            $out.Add("$key = $($updates[$key])")
            continue
        }
    }
    $out.Add($line)
}
foreach ($key in $updates.Keys) {
    if (-not $set.ContainsKey($key)) {
        $out.Add("$key = $($updates[$key])")
    }
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($configPath, $out, $utf8)
Write-Output "AVD Android TV configurado: landscape, skin tv_1080p, D-pad y GPU host."
