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

switch ($Action) {
    'pull' {
        & $git pull --ff-only
    }
    'push' {
        & $git add -A
        & $git diff --cached --quiet
        if ($LASTEXITCODE -ne 0) {
            & $git commit -m $Message
        }
        else {
            Write-Host 'No changes to commit.'
        }
        & $git push
    }
    'status' {
        & $git status -sb
        & $git log --oneline -5
    }
}
