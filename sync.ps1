# sync.ps1 — короткие команды для работы с репозиторием Project PAW.
#
#   .\sync.ps1 status                 что изменено, где ветка, последние коммиты
#   .\sync.ps1 pull                   забрать свежий main / свою ветку
#   .\sync.ps1 branch artem/my-task   создать рабочую ветку от свежего main
#   .\sync.ps1 check                  прогнать валидатор и проверку синтаксиса
#   .\sync.ps1 push "что сделал"      проверить, закоммитить и отправить ветку
#
# Прямой push в main запрещён: скрипт откажется работать на main и предложит
# создать ветку. Дальше — Pull Request, ревью и squash-merge (см. CONTRIBUTING.md).

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('status', 'pull', 'branch', 'push', 'check')]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Message = "Обновление мода"
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 по умолчанию пишет в консоль в кодировке системы и ломает
# русский текст в выводе. Переключаем вывод на UTF-8.
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { $git = 'C:\Program Files\Git\cmd\git.exe' }

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = (Get-Command py -ErrorAction SilentlyContinue).Source }

Set-Location -LiteralPath $PSScriptRoot

function Invoke-Git {
    param([string[]]$Arguments)
    $output = & $git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') завершился с ошибкой:`n$($output -join "`n")"
    }
    return $output
}

function Show-Git {
    param([string[]]$Arguments)
    & $git @Arguments 2>&1 | ForEach-Object { Write-Host $_ }
}

function Get-CurrentBranch {
    return (Invoke-Git @('rev-parse', '--abbrev-ref', 'HEAD') | Out-String).Trim()
}

function Assert-NotMain {
    param([string]$Branch)
    if ($Branch -in @('main', 'master')) {
        throw @'
Текущая ветка — main. Прямой push в main запрещён (branch protection).

Создайте рабочую ветку и повторите:
    .\sync.ps1 branch artem/short-name

Имя ветки: <зона>/<краткое-имя>, где зона — artem, vlad, andrey или infra.
'@
    }
}

function Invoke-Checks {
    if (-not $python) {
        throw 'Python не найден в PATH. Установите Python 3.10+ или проверьте PATH.'
    }
    Write-Host '--- python tools/validate_mod.py ---'
    & $python 'tools/validate_mod.py'
    if ($LASTEXITCODE -ne 0) {
        throw 'Валидатор нашёл ошибки. Исправьте их перед коммитом (подробности выше).'
    }
    Write-Host '--- python -m compileall -q tools ---'
    & $python '-m' 'compileall' '-q' 'tools'
    if ($LASTEXITCODE -ne 0) {
        throw 'Скрипты в tools/ не компилируются.'
    }
}

function Assert-CleanTree {
    $dirty = Invoke-Git @('status', '--porcelain')
    if ($dirty) {
        throw @'
В рабочей копии есть незакоммиченные изменения.

Закоммитьте их в текущую ветку (.\sync.ps1 push "...") или спрячьте (git stash),
затем создавайте новую ветку.
'@
    }
}

switch ($Action) {
    'status' {
        Show-Git @('status', '-sb')
        Write-Host ''
        Write-Host '--- последние коммиты ---'
        Show-Git @('log', '--oneline', '-5')
    }

    'pull' {
        $branch = Get-CurrentBranch
        Show-Git @('fetch', '--prune', 'origin')
        if ($branch -in @('main', 'master')) {
            Invoke-Git @('merge', '--ff-only', 'origin/main') | Out-Null
        }
        else {
            # Своя ветка: подтягиваем её, если она есть на origin, иначе просто main.
            $remoteBranch = (& $git 'ls-remote', '--heads', 'origin', $branch) 2>$null
            if ($remoteBranch) {
                Invoke-Git @('merge', '--ff-only', "origin/$branch") | Out-Null
            }
            else {
                Write-Host "Ветка '$branch' ещё не на origin — пропускаю merge."
            }
        }
        Write-Host "Готово. Ветка: $branch"
    }

    'branch' {
        $name = $Message
        if ($name -notmatch '^(artem|vlad|andrey|infra|hotfix)/[a-z0-9][a-z0-9._-]*$') {
            throw @'
Неверное имя ветки.

Формат: <зона>/<краткое-имя>, только строчные латинские буквы, цифры, точка, дефис.
    artem/remove-ammo
    vlad/map-strategy
    andrey/sandbox-preset
    infra/ci-and-docs
'@
        }
        Assert-CleanTree
        Invoke-Git @('switch', 'main') | Out-Null
        Invoke-Git @('pull', '--ff-only') | Out-Null
        Invoke-Git @('switch', '-c', $name) | Out-Null
        Write-Host "Создана ветка '$name' от свежего main."
    }

    'check' {
        Invoke-Checks
        Write-Host 'Проверки пройдены.'
    }

    'push' {
        $branch = Get-CurrentBranch
        Assert-NotMain $branch

        Invoke-Checks

        Invoke-Git @('add', '-A') | Out-Null
        & $git 'diff', '--cached', '--quiet' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Invoke-Git @('commit', '-m', $Message) | Out-Null
            Write-Host "Коммит: $Message"
        }
        else {
            Write-Host 'Изменений для коммита нет.'
        }

        $hasUpstream = (& $git 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}') 2>$null
        if ($LASTEXITCODE -eq 0 -and $hasUpstream) {
            Invoke-Git @('push') | Out-Null
        }
        else {
            Invoke-Git @('push', '-u', 'origin', $branch) | Out-Null
        }

        Write-Host ''
        Write-Host "Ветка '$branch' отправлена на GitHub."
        Write-Host "Дальше: gh pr create --fill   (или ссылка, которую вывел git push)"
    }
}
