# Make the WoW Forever PlayTheGameTools folder load a checkout.
# The verified setup is a junction. This script keeps that junction when it
# already points at the checkout. When it points at a different clean checkout,
# that checkout is switched onto this branch. Retarget is only the fallback
# when a switch would disturb local work or the branch is already open.
# rmdir removes a junction entry and does not delete the previous target.
# Never use Remove-Item -Recurse on the live addon path.
param(
    [Parameter(Mandatory = $true)][string]$SourceAddon,
    [string]$LiveAddon,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GIT_MERGE_AUTOEDIT = 'no'

function Fail([string]$Message, [int]$Code) {
    [Console]::Error.WriteLine($Message)
    exit $Code
}

function Normalize-Path([string]$Path) {
    return ([System.IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function Test-ForbiddenClient([string]$Path) {
    return $Path -match '\\_(retail|classic|classic_era|classic_beta)_\\'
}

function Get-DefaultLiveAddon {
    $parents = @(
        ${env:ProgramFiles(x86)},
        $env:ProgramFiles,
        'C:\Program Files (x86)',
        'C:\Program Files'
    ) | Where-Object { $_ } | Select-Object -Unique
    foreach ($parent in $parents) {
        $candidate = Join-Path $parent 'World of Warcraft\_forever_\Interface\AddOns\PlayTheGameTools'
        $addons = Split-Path $candidate -Parent
        if (Test-Path -LiteralPath $addons) {
            return $candidate
        }
    }
    return $null
}

function Get-Git([string]$Repo, [string[]]$GitArgs) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $all = & git -C $Repo @GitArgs 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous
    $text = @($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }) -join "`n"
    return @{ Code = $code; Text = $text.Trim() }
}

function Get-LinkTarget([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType -ne 'Junction' -and $item.LinkType -ne 'SymbolicLink') {
        return $null
    }
    $target = $item.Target
    if ($target -is [array]) { $target = $target[0] }
    if (-not $target) { return $null }
    return (Normalize-Path $target)
}

function Remove-Link([string]$Path) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/d /c rmdir "' + $Path + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.WaitForExit()
    return $proc.ExitCode
}

function Get-RepoRoot([string]$AddonDir) {
    $result = Get-Git $AddonDir @('rev-parse', '--show-toplevel')
    if ($result.Code -ne 0) { return $null }
    return (Normalize-Path $result.Text)
}

function Test-CleanRepo([string]$Repo) {
    $result = Get-Git $Repo @('status', '--porcelain', '--untracked-files=all')
    return ($result.Code -eq 0 -and [string]::IsNullOrWhiteSpace($result.Text))
}

function Restore-Branch([string]$Repo, [string]$Branch, [string]$Sha) {
    if ($Branch -eq 'HEAD') {
        $restored = Get-Git $Repo @('switch', '--detach', $Sha)
    } else {
        $restored = Get-Git $Repo @('switch', $Branch)
    }
    return ($restored.Code -eq 0)
}

# Returns the branch name when this commit is checked out in another worktree.
function Get-BranchWorktree([string]$Repo, [string]$Branch) {
    $result = Get-Git $Repo @('worktree', 'list', '--porcelain')
    if ($result.Code -ne 0) { return $null }
    $found = $null
    $current = $null
    foreach ($line in ($result.Text -split "`n")) {
        $line = $line.Trim()
        if ($line.StartsWith('worktree ')) { $current = $line.Substring(9).Trim() }
        if ($line -eq "branch refs/heads/$Branch") { $found = $current }
    }
    return $found
}

if ($env:PTG_FOREVER_ADDON -and -not $LiveAddon) {
    $LiveAddon = $env:PTG_FOREVER_ADDON
}
if (-not $LiveAddon) {
    $LiveAddon = Get-DefaultLiveAddon
}
if (-not $LiveAddon) {
    Fail 'No Forever AddOns directory found. Set PTG_FOREVER_ADDON to Interface\AddOns\PlayTheGameTools.' 3
}

$source = Normalize-Path $SourceAddon
$live = Normalize-Path $LiveAddon

if ((Split-Path $source -Leaf) -ne 'PlayTheGameTools' -or -not (Test-Path -LiteralPath (Join-Path $source 'PlayTheGameTools.toc'))) {
    Fail "Source is not the PlayTheGameTools addon directory: $source" 2
}
$edition = Select-String -LiteralPath (Join-Path $source 'PlayTheGameTools.toc') -Pattern 'X-PlayTheGameTools-Edition:\s*Forever' -Quiet
if (-not $edition) {
    Fail "Source TOC is not the Forever edition: $source" 2
}
if ($source -match '\\Interface\\AddOns\\') {
    Fail "Source must be a checkout, not a folder already inside Interface\AddOns: $source" 2
}
foreach ($path in @($source, $live)) {
    if (Test-ForbiddenClient $path) {
        Fail "Refusing a non-Forever client path: $path" 2
    }
}
if ($live -notmatch '\\_forever_\\Interface\\AddOns\\PlayTheGameTools$') {
    Fail "Refusing live path outside Forever AddOns\PlayTheGameTools: $live" 2
}

$addonsDir = Split-Path $live -Parent
if (-not (Test-Path -LiteralPath $addonsDir)) {
    Fail "Forever AddOns directory does not exist: $addonsDir" 3
}

$sourceRepo = Get-RepoRoot $source
$sourceHead = $null
$sourceBranch = $null
if ($sourceRepo) {
    $sourceHead = (Get-Git $sourceRepo @('rev-parse', 'HEAD')).Text
    $sourceBranch = (Get-Git $sourceRepo @('rev-parse', '--abbrev-ref', 'HEAD')).Text
}

if (-not (Test-Path -LiteralPath $live)) {
    if ($WhatIf) {
        Write-Output 'STATUS CREATE'
        Write-Output "LIVE $live"
        Write-Output "TARGET $source"
        exit 0
    }
    New-Item -ItemType Junction -Path $live -Target $source | Out-Null
    Write-Output 'STATUS CREATED'
    Write-Output "LIVE $live"
    Write-Output "TARGET $source"
    exit 0
}

$existing = Get-LinkTarget $live
if ($existing) {
    if ($existing -eq $source) {
        Write-Output 'STATUS ALREADY'
        Write-Output "LIVE $live"
        Write-Output "TARGET $source"
        exit 0
    }

    $liveRepo = Get-RepoRoot $existing
    $switched = $false
    if ($liveRepo -and $sourceRepo -and $sourceBranch -and $sourceBranch -ne 'HEAD' -and $sourceHead) {
        $liveHead = (Get-Git $liveRepo @('rev-parse', 'HEAD')).Text
        if ($liveHead -eq $sourceHead) {
            Write-Output 'STATUS ALREADY'
            Write-Output "LIVE $live"
            Write-Output "TARGET $existing"
            Write-Output "HEAD $sourceHead"
            exit 0
        }
        $holder = Get-BranchWorktree $liveRepo $sourceBranch
        $holderIsLive = $holder -and ((Normalize-Path $holder) -eq (Normalize-Path $liveRepo))
        $clean = Test-CleanRepo $liveRepo
        if ($clean -and (-not $holder -or $holderIsLive)) {
            $previous = (Get-Git $liveRepo @('rev-parse', '--abbrev-ref', 'HEAD')).Text
            $previousSha = (Get-Git $liveRepo @('rev-parse', 'HEAD')).Text
            if ($WhatIf) {
                Write-Output 'STATUS SWITCH'
                Write-Output "PREVIOUS $previous"
                Write-Output "BRANCH $sourceBranch"
                Write-Output "LIVE $live"
                Write-Output "TARGET $existing"
                exit 0
            }
            $hasCommit = (Get-Git $liveRepo @('cat-file', '-e', "${sourceHead}^{commit}")).Code -eq 0
            if (-not $hasCommit) {
                $fetched = Get-Git $liveRepo @('fetch', 'origin', $sourceBranch)
                $hasCommit = $fetched.Code -eq 0 -and (Get-Git $liveRepo @('cat-file', '-e', "${sourceHead}^{commit}")).Code -eq 0
            }
            if ($hasCommit) {
                $local = Get-Git $liveRepo @('show-ref', '--verify', '--quiet', "refs/heads/$sourceBranch")
                if ($local.Code -eq 0) {
                    $sw = Get-Git $liveRepo @('switch', $sourceBranch)
                } else {
                    $sw = Get-Git $liveRepo @('switch', '-c', $sourceBranch, '--track', "origin/$sourceBranch")
                }
                if ($sw.Code -eq 0) {
                    $now = (Get-Git $liveRepo @('rev-parse', 'HEAD')).Text
                    if ($now -ne $sourceHead) {
                        $ff = Get-Git $liveRepo @('merge', '--ff-only', $sourceHead)
                        $now = (Get-Git $liveRepo @('rev-parse', 'HEAD')).Text
                        if ($ff.Code -ne 0 -or $now -ne $sourceHead) {
                            $back = Restore-Branch $liveRepo $previous $previousSha
                            if (-not $back) {
                                Fail "Live checkout is on $sourceBranch and could not return to $previous. It was not retargeted." 4
                            }
                            $sw = @{ Code = 1 }
                        }
                    }
                }
                if ($sw.Code -eq 0 -and (Get-Git $liveRepo @('rev-parse', 'HEAD')).Text -eq $sourceHead) {
                    Write-Output 'STATUS SWITCHED'
                    Write-Output "PREVIOUS $previous"
                    Write-Output "BRANCH $sourceBranch"
                    Write-Output "LIVE $live"
                    Write-Output "TARGET $existing"
                    Write-Output "HEAD $sourceHead"
                    $switched = $true
                }
            }
        }
    }
    if ($switched) { exit 0 }

    if (-not (Test-Path -LiteralPath $existing)) {
        Fail "Current junction target is missing, so it was left unchanged: $existing" 4
    }
    if ($WhatIf) {
        Write-Output 'STATUS RETARGET'
        Write-Output "PREVIOUS $existing"
        Write-Output "LIVE $live"
        Write-Output "TARGET $source"
        exit 0
    }
    $removed = Remove-Link $live
    if ($removed -ne 0 -or (Test-Path -LiteralPath $live)) {
        Fail "Could not retarget the junction. The previous target is still in place: $existing" 4
    }
    if (-not (Test-Path -LiteralPath $existing)) {
        Fail "Stopped because the previous target disappeared: $existing" 4
    }
    New-Item -ItemType Junction -Path $live -Target $source | Out-Null
    $nowTarget = Get-LinkTarget $live
    if ($nowTarget -ne $source -or -not (Test-Path -LiteralPath $existing)) {
        Fail "Junction retarget did not stick. Previous target: $existing" 4
    }
    Write-Output 'STATUS RETARGETED'
    Write-Output "PREVIOUS $existing"
    Write-Output "LIVE $live"
    Write-Output "TARGET $source"
    exit 0
}

if ($WhatIf) {
    Write-Output 'STATUS COPY'
    Write-Output "LIVE $live"
    Write-Output "SOURCE $source"
    exit 0
}

& robocopy $source $live /MIR /R:1 /W:1 /NFL /NDL /NP /XD .git
if ($LASTEXITCODE -ge 8) {
    Fail "Copy into the live addon failed (robocopy $LASTEXITCODE). The game was not closed. SavedVariables were not touched." 4
}
Write-Output 'STATUS COPIED'
Write-Output "LIVE $live"
Write-Output "SOURCE $source"
exit 0
