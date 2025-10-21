[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Version = '1.0.0'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

function Show-Version {
    Write-Output "watch (Windows) $script:Version"
}

function Show-Help {
    Write-Output @'
Usage: watch [options] command

Execute a program periodically, showing output fullscreen.

Options:
  -n x, --interval x          Repeat command every x seconds (default: 2)
                              The short form can also be used as -nx
  -d, --differences           Highlight changes between updates
      --differences=cumulative  Keep highlighting all differences
  -t, --no-title              Turn off the header information
  -h, --help                  Display this help and exit
  -v, --version               Output version information and exit

Pass "--" to stop option parsing so subsequent values are treated
as part of the command.
'@
}

function Fail([string]$message) {
    [Console]::Error.WriteLine("watch: $message")
    exit 1
}

if (-not $RemainingArgs -or $RemainingArgs.Count -eq 0) {
    Show-Help
    Fail 'requires a command to run'
}

$intervalSeconds = 2.0
$diffMode = 'none'      # none | diff | cumulative
$showTitle = $true

$commandArgs = @()
$optionParsing = $true
$i = 0

function Set-Interval([string]$value) {
    if (-not $value) {
        Fail 'interval value is missing'
    }

    $parsed = 0.0
    if (-not [double]::TryParse($value, [System.Globalization.NumberStyles]::Float, $culture, [ref]$parsed)) {
        Fail "invalid interval '$value'"
    }

    if ($parsed -le 0) {
        Fail 'interval must be greater than zero'
    }

    $script:intervalSeconds = $parsed
}

function Set-Differences([string]$value) {
    if ([string]::IsNullOrEmpty($value)) {
        $script:diffMode = 'diff'
        return
    }

    switch ($value.ToLowerInvariant()) {
        'cumulative' {
            $script:diffMode = 'cumulative'
        }
        default {
            Fail "unsupported differences mode '$value'"
        }
    }
}

while ($i -lt $RemainingArgs.Count) {
    $arg = $RemainingArgs[$i]

    if (-not $optionParsing) {
        $commandArgs = $RemainingArgs[$i..($RemainingArgs.Count - 1)]
        break
    }

    $lower = $arg.ToLowerInvariant()

    switch ($lower) {
        '--' {
            $optionParsing = $false
            $i++
            continue
        }
        '-h' { Show-Help; exit 0 }
        '--help' { Show-Help; exit 0 }
        '-v' { Show-Version; exit 0 }
        '--version' { Show-Version; exit 0 }
        '-t' { $showTitle = $false; $i++; continue }
        '--no-title' { $showTitle = $false; $i++; continue }
        '-d' { Set-Differences(''); $i++; continue }
        '--differences' { Set-Differences(''); $i++; continue }
    }

    if ($lower -like '-d=*') {
        Set-Differences($arg.Substring($arg.IndexOf('=') + 1))
        $i++
        continue
    }

    if ($lower -like '--differences=*') {
        Set-Differences($arg.Substring($arg.IndexOf('=') + 1))
        $i++
        continue
    }

    if ($lower -eq '-n' -or $lower -eq '--interval') {
        $i++
        if ($i -ge $RemainingArgs.Count) {
            Fail 'interval value is missing'
        }
        Set-Interval($RemainingArgs[$i])
        $i++
        continue
    }

    if ($lower.StartsWith('-n') -and $lower.Length -gt 2) {
        Set-Interval($arg.Substring(2))
        $i++
        continue
    }

    if ($lower.StartsWith('--interval=')) {
        Set-Interval($arg.Substring($arg.IndexOf('=') + 1))
        $i++
        continue
    }

    if ($arg.StartsWith('-')) {
        Fail "unrecognized option '$arg'"
    }

    $commandArgs = $RemainingArgs[$i..($RemainingArgs.Count - 1)]
    break
}

if (-not $commandArgs -or $commandArgs.Count -eq 0) {
    Fail 'requires a command to run'
}

$quotedArgs = $commandArgs | ForEach-Object { [System.Management.Automation.Language.CodeGeneration]::QuoteArgument($_) }
$commandText = [string]::Join(' ', $quotedArgs)

$previousOutput = @()
$cumulativeIndices = [System.Collections.Generic.HashSet[int]]::new()

function Write-Line([string]$text, [bool]$highlight) {
    if ($highlight) {
        Write-Host $text -ForegroundColor Black -BackgroundColor Yellow
    }
    else {
        Write-Host $text
    }
}

function Format-Interval([double]$seconds) {
    return $seconds.ToString('0.###', $culture)
}

try {
    while ($true) {
        $startTime = Get-Date
        $outputLines = @()
        try {
            $result = & cmd.exe /c $commandText 2>&1
            if ($null -eq $result) {
                $outputLines = @()
            }
            elseif ($result -is [System.Array]) {
                $outputLines = @($result | ForEach-Object { $_.ToString() })
            }
            else {
                $outputLines = @($result.ToString())
            }
        }
        catch {
            $outputLines = @($_.Exception.Message)
        }

        Clear-Host
        if ($showTitle) {
            $intervalFormatted = Format-Interval($intervalSeconds)
            Write-Host ("Every {0}s: {1}" -f $intervalFormatted, $commandText)
            Write-Host ((Get-Date).ToString('ddd MMM dd HH:mm:ss yyyy'))
            Write-Host ''
        }

        $lineCount = [Math]::Max($outputLines.Count, $previousOutput.Count)
        for ($lineIndex = 0; $lineIndex -lt $lineCount; $lineIndex++) {
            $current = if ($lineIndex -lt $outputLines.Count) { $outputLines[$lineIndex] } else { '' }
            $previous = if ($lineIndex -lt $previousOutput.Count) { $previousOutput[$lineIndex] } else { '' }
            $changed = $current -ne $previous

            if ($diffMode -eq 'cumulative' -and $changed) {
                $null = $cumulativeIndices.Add($lineIndex)
            }

            $highlight = switch ($diffMode) {
                'diff' { $changed }
                'cumulative' { $cumulativeIndices.Contains($lineIndex) -or $changed }
                default { $false }
            }

            Write-Line $current $highlight
        }

        $previousOutput = @($outputLines)
        $elapsed = (Get-Date) - $startTime
        $remaining = $intervalSeconds - $elapsed.TotalSeconds
        if ($remaining -gt 0) {
            $milliseconds = [int][Math]::Round($remaining * 1000)
            if ($milliseconds -gt 0) {
                Start-Sleep -Milliseconds $milliseconds
            }
        }
    }
}
finally {

}
