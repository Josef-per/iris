$ErrorActionPreference = 'Stop'

$irisProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$irisEnvFile = $env:IRIS_ENV_FILE

if ([string]::IsNullOrEmpty($irisEnvFile)) {
    $irisEnvFile = Join-Path $irisProjectDir '.env'
}

if (-not (Test-Path -LiteralPath $irisEnvFile -PathType Leaf)) {
    [Console]::Error.WriteLine("Arquivo de configuracao nao encontrado: $irisEnvFile")
    exit 1
}

function Get-IrisPublicValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $escapedKey = [System.Text.RegularExpressions.Regex]::Escape($Key)
    $pattern = '^\s*' + $escapedKey + '\s*=\s*(.*)$'
    $value = ''

    foreach ($line in [System.IO.File]::ReadLines($irisEnvFile)) {
        $match = [System.Text.RegularExpressions.Regex]::Match($line, $pattern)
        if ($match.Success) {
            $value = $match.Groups[1].Value
        }
    }

    if ($value.Length -ge 2) {
        $firstCharacter = $value[0]
        $lastCharacter = $value[$value.Length - 1]
        $isDoubleQuoted = $firstCharacter -eq '"' -and $lastCharacter -eq '"'
        $isSingleQuoted = $firstCharacter -eq "'" -and $lastCharacter -eq "'"

        if ($isDoubleQuoted -or $isSingleQuoted) {
            $value = $value.Substring(1, $value.Length - 2)
        }
    }

    return $value
}

$irisSupabaseUrl = Get-IrisPublicValue -Key 'SUPABASE_URL'
$irisSupabaseKey = Get-IrisPublicValue -Key 'SUPABASE_PUBLISHABLE_KEY'

if ([string]::IsNullOrEmpty($irisSupabaseKey)) {
    $irisSupabaseKey = Get-IrisPublicValue -Key 'SUPABASE_ANON_KEY'
}

if (
    [string]::IsNullOrEmpty($irisSupabaseUrl) -or
    [string]::IsNullOrEmpty($irisSupabaseKey)
) {
    [Console]::Error.WriteLine(
        'Defina SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY no arquivo .env.'
    )
    exit 1
}

$irisIsWindows = (
    [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
)
$irisFlutterBin = $env:IRIS_FLUTTER_BIN

if ([string]::IsNullOrEmpty($irisFlutterBin)) {
    if ($irisIsWindows) {
        $irisLocalFlutterBin = Join-Path $irisProjectDir '.flutter-sdk\bin\flutter.bat'
    }
    else {
        $irisLocalFlutterBin = Join-Path $irisProjectDir '.flutter-sdk/bin/flutter'
    }

    if (Test-Path -LiteralPath $irisLocalFlutterBin -PathType Leaf) {
        $irisFlutterBin = $irisLocalFlutterBin
    }
    else {
        $irisFlutterBin = 'flutter'
    }
}

$irisFlutterArguments = @($args)
$irisRunArguments = @()
$irisDeviceWasSelected = $false
$irisBuildModeWasSelected = $false

foreach ($irisArgument in $irisFlutterArguments) {
    if (
        $irisArgument -eq '-d' -or
        $irisArgument -eq '--device-id' -or
        $irisArgument -like '--device-id=*' -or
        $irisArgument -like '-d=*'
    ) {
        $irisDeviceWasSelected = $true
    }

    if (
        $irisArgument -eq '--debug' -or
        $irisArgument -eq '--profile' -or
        $irisArgument -eq '--release'
    ) {
        $irisBuildModeWasSelected = $true
    }
}

$irisIsHeadless = (
    (-not $irisIsWindows) -and
    [string]::IsNullOrEmpty($env:DISPLAY) -and
    [string]::IsNullOrEmpty($env:WAYLAND_DISPLAY)
)

if ($irisIsHeadless -and -not $irisDeviceWasSelected) {
    $irisWebPort = $env:IRIS_WEB_PORT
    if ([string]::IsNullOrEmpty($irisWebPort)) {
        $irisWebPort = '8080'
    }

    $irisRunArguments += @(
        '-d'
        'web-server'
        '--web-hostname=0.0.0.0'
        "--web-port=$irisWebPort"
    )

    if (-not $irisBuildModeWasSelected) {
        $irisRunArguments += '--release'
    }

    [Console]::Error.WriteLine(
        "Ambiente sem interface grafica; iniciando a versao web otimizada na porta $irisWebPort."
    )
}

$irisCommandArguments = @(
    'run'
    "--dart-define=SUPABASE_URL=$irisSupabaseUrl"
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$irisSupabaseKey"
) + $irisRunArguments + $irisFlutterArguments

& $irisFlutterBin @irisCommandArguments
exit $LASTEXITCODE
