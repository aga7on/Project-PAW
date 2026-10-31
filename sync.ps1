param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('pull', 'push', 'status')]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Message = "Обновление мода"
)

$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { $git = 'C:\Program Files\Git\cmd\git.exe' }

Set-Location -LiteralPath $PSScriptRoot

function Invoke-Git {
    param([string[]]$Arguments)
    & $git @Arguments 2>&1 | ForEach-Object { Write-Host $_ }
}

switch ($Action) {
    'pull' {
        Invoke-Git @('pull', '--ff-only')
    }
    'push' {
        Invoke-Git @('add', '-A')
        & $git diff --cached --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Invoke-Git @('commit', '-m', $Message)
        }
        else {
            Write-Host 'No changes to commit.'
        }
        Invoke-Git @('push')
    }
    'status' {
        Invoke-Git @('status', '-sb')
        Invoke-Git @('log', '--oneline', '-5')
    }
}
