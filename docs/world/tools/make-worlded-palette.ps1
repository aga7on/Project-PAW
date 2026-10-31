param(
    [string]$RulesPath = 'W:\SteamLibrary\steamapps\common\Project Zomboid Modding Tools\WorldEd\Rules.txt',
    [string]$OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'docs')
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$text = Get-Content -LiteralPath $rulesPath -Raw

$aliases = @{}
foreach ($m in [regex]::Matches($text, '(?s)alias\s*\{(.*?)\}')) {
    $body = $m.Groups[1].Value
    $name = [regex]::Match($body, 'name\s*=\s*(\S+)').Groups[1].Value
    $tilesRaw = [regex]::Match($body, '(?s)tiles\s*=\s*\[(.*?)\]').Groups[1].Value
    if (-not $name) { continue }
    $aliases[$name] = @(($tilesRaw -split "\s+") | Where-Object { $_ -match '\S' })
}

$rules = @()
foreach ($m in [regex]::Matches($text, '(?s)rule\s*\{(.*?)\}')) {
    $body = $m.Groups[1].Value
    $label = [regex]::Match($body, 'label\s*=\s*(.+)').Groups[1].Value.Trim()
    $rgb = [regex]::Match($body, 'color\s*=\s*(\d+)\s+(\d+)\s+(\d+)')
    if (-not $rgb.Success) { continue }

    $r = [int]$rgb.Groups[1].Value; $g = [int]$rgb.Groups[2].Value; $b = [int]$rgb.Groups[3].Value
    $layer = [regex]::Match($body, 'layer\s*=\s*(\S+)').Groups[1].Value
    $bitmap = [regex]::Match($body, 'bitmap\s*=\s*(\d+)').Groups[1].Value
    $cond = [regex]::Match($body, 'condition\s*=\s*(\d+\s+\d+\s+\d+)').Groups[1].Value

    $tm = [regex]::Match($body, '(?s)tiles\s*=\s*(\[[^\]]*\]|\S+)')
    $tilesRaw = $tm.Groups[1].Value.Trim()
    $aliasName = ''
    $isAlias = $false
    if ($tilesRaw.StartsWith('[')) {
        $list = @((($tilesRaw.Trim('[', ']')) -split "\s+") | Where-Object { $_ -match '\S' })
        $unique = @($list | Select-Object -Unique)
        $tilesDisplay = ($unique | Select-Object -First 8) -join ', '
        if ($unique.Count -gt 8) { $tilesDisplay += " … (+$($unique.Count - 8))" }
        $sample = $unique[0]
    }
    else {
        $aliasName = $tilesRaw
        $isAlias = $aliases.ContainsKey($aliasName)
        $expanded = if ($isAlias) { $aliases[$aliasName] } else { @() }
        $tilesDisplay = if ($expanded.Count -gt 0) {
            '`' + $aliasName + '` → `' + (($expanded | Select-Object -First 4) -join '`, `') + '`'
        } else { '`' + $aliasName + '`' }
        $sample = if ($expanded.Count -gt 0) { $expanded[0] } else { $aliasName }
    }

    $rules += [pscustomobject]@{
        Label = if ($label) { $label } else { '(без названия)' }; R = $r; G = $g; B = $b
        Hex = ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
        Layer = $layer; Bitmap = $bitmap; Condition = $cond
        Alias = if ($isAlias) { $aliasName } else { '' }
        TilesDisplay = $tilesDisplay; Sample = $sample
        Kind = if ($bitmap -eq '1') { 'оверлей' } else { 'поверхность' }
    }
}

$rules = $rules | Sort-Object @{ Expression = { if ($_.Kind -eq 'поверхность') { 0 } else { 1 } } }, Layer, Label
"правил: $($rules.Count)  алиасов: $($aliases.Count)"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Цвета карты WorldEd (палитра Project Zomboid)')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Соответствие «цвет → тайлы» для рисования карты в WorldEd. Источник — `WorldEd\Rules.txt`')
[void]$sb.AppendLine('из Project Zomboid Modding Tools (Build 42.21). Сгенерировано автоматически.')
[void]$sb.AppendLine()
[void]$sb.AppendLine('![Палитра WorldEd](worlded-colors.png)')
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Поверхности (`bitmap = 0`)')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Базовый слой: цвет заливки клетки целиком заменяется тайлами из правила.')
[void]$sb.AppendLine()
[void]$sb.AppendLine('| Свотч | RGB | HEX | Тип поверхности | Слой | Алиас | Тайлы |')
[void]$sb.AppendLine('|---|---|---|---|---|---|---|')
foreach ($r in $rules | Where-Object Kind -eq 'поверхность') {
    [void]$sb.AppendLine(('| {0} | {1} {2} {3} | `{4}` | {5} | `{6}` | {7} | {8} |' -f `
        ('`' + $r.Hex + '`'), $r.R, $r.G, $r.B, $r.Hex, $r.Label, $r.Layer, `
        ($(if ($r.Alias) { '`' + $r.Alias + '`' } else { '—' })), $r.TilesDisplay))
}
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Растительность и деревья (`bitmap = 1`, оверлей)')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Кладутся поверх базовой поверхности. `condition` — цвет базовой поверхности, на которую')
[void]$sb.AppendLine('правило наносится (например, «деревья + тёмная трава»).')
[void]$sb.AppendLine()
[void]$sb.AppendLine('| Свотч | RGB | HEX | Тип | Слой | База (`condition`) | Тайлы |')
[void]$sb.AppendLine('|---|---|---|---|---|---|---|')
foreach ($r in $rules | Where-Object Kind -eq 'оверлей') {
    $cond = if ($r.Condition) {
        $c = $r.Condition -split ' '
        '`{0} {1} {2}`' -f $c[0], $c[1], $c[2]
    } else { '—' }
    [void]$sb.AppendLine(('| {0} | {1} {2} {3} | `{4}` | {5} | `{6}` | {7} | {8} |' -f `
        ('`' + $r.Hex + '`'), $r.R, $r.G, $r.B, $r.Hex, $r.Label, $r.Layer, $cond, $r.TilesDisplay))
}
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Как это работает')
[void]$sb.AppendLine()
[void]$sb.AppendLine('- В WorldEd клетки карты закрашиваются цветом из таблицы: цвет = правило из `Rules.txt`.')
[void]$sb.AppendLine('- `tiles` — либо алиас, который в начале `Rules.txt` раскрывается в конкретные спрайты, либо готовый список тайлов.')
[void]$sb.AppendLine('- Стыки поверхностей обрабатывает `WorldEd\Blends.txt`, дорожную разметку — `WorldEd\Roads.txt`.')
[void]$sb.AppendLine('- Свои поверхности для мода добавляются такими же блоками `rule { }` в собственном rules-файле и своим цветом палитры.')

[System.IO.File]::WriteAllText("$outDir\worlded-colors.md", $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Add-Type -AssemblyName System.Drawing

$rowH = 34
$width = 1340
$headerH = 132
$sectionH = 40
$surfaces = @($rules | Where-Object Kind -eq 'поверхность')
$overlays = @($rules | Where-Object Kind -eq 'оверлей')
$height = $headerH + $sectionH * 2 + $rowH * $rules.Count + 16

$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.Clear([System.Drawing.Color]::FromArgb(24, 24, 26))

$fontTitle = New-Object System.Drawing.Font 'Segoe UI', 20, ([System.Drawing.FontStyle]::Bold)
$fontSub = New-Object System.Drawing.Font 'Segoe UI', 11
$fontSection = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Bold)
$fontLabel = New-Object System.Drawing.Font 'Segoe UI', 11, ([System.Drawing.FontStyle]::Bold)
$fontMono = New-Object System.Drawing.Font 'Consolas', 9.5
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 235, 235))
$grey = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 150, 155))
$accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(196, 164, 96))
$border = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(80, 80, 88)), 1
$sep = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(60, 60, 66)), 1

$g.DrawString('WorldEd Color Palette', $fontTitle, $white, 16, 14)
$g.DrawString('Project Zomboid 42.21   •   WorldEd\Rules.txt', $fontSub, $grey, 18, 48)
$g.DrawString('цвет', $fontSub, $grey, 18, 84)
$g.DrawString('тип поверхности', $fontSub, $grey, 64, 84)
$g.DrawString('rgb / hex', $fontSub, $grey, 560, 84)
$g.DrawString('слой', $fontSub, $grey, 800, 84)
$g.DrawString('база', $fontSub, $grey, 920, 84)
$g.DrawString('первый тайл', $fontSub, $grey, 1050, 84)

function Draw-Section {
    param([System.Drawing.Graphics]$Gfx, [string]$Title, [int]$Y, [int]$Count)
    $Gfx.DrawString($Title, $fontSection, $accent, 16, $Y)
    $Gfx.DrawString("($Count)", $fontSub, $grey, 16 + ($Gfx.MeasureString($Title, $fontSection).Width + 8), ($Y + 3))
    $Gfx.DrawLine($sep, 16, ($Y + 30), ($width - 20), ($Y + 30))
}

$y = 108
$y = $headerH - $sectionH + 24
Draw-Section -Gfx $g -Title 'Поверхности  (bitmap = 0, базовый слой)' -Y $y -Count $surfaces.Count
$y += $sectionH
foreach ($r in $surfaces) {
    $col = [System.Drawing.Color]::FromArgb($r.R, $r.G, $r.B)
    $rect = New-Object System.Drawing.Rectangle 16, ($y + 4), 26, 26
    $brush = New-Object System.Drawing.SolidBrush $col
    $g.FillRectangle($brush, $rect)
    $g.DrawRectangle($border, $rect)
    $brush.Dispose()

    $g.DrawString($r.Label, $fontLabel, $white, 64, ($y + 5))
    $g.DrawString(('{0} {1} {2}   {3}' -f $r.R, $r.G, $r.B, $r.Hex), $fontMono, $grey, 560, ($y + 8))
    $g.DrawString($r.Layer, $fontMono, $grey, 800, ($y + 8))
    $g.DrawString($r.Sample, $fontMono, $grey, 1050, ($y + 8))
    $y += $rowH
}

$y += 16
Draw-Section -Gfx $g -Title 'Растительность и деревья  (bitmap = 1, оверлей)' -Y $y -Count $overlays.Count
$y += $sectionH
foreach ($r in $overlays) {
    $col = [System.Drawing.Color]::FromArgb($r.R, $r.G, $r.B)
    $rect = New-Object System.Drawing.Rectangle 16, ($y + 4), 26, 26
    $brush = New-Object System.Drawing.SolidBrush $col
    $g.FillRectangle($brush, $rect)
    $g.DrawRectangle($border, $rect)
    $brush.Dispose()

    $cond = if ($r.Condition) { $r.Condition } else { '—' }
    $g.DrawString($r.Label, $fontLabel, $white, 64, ($y + 5))
    $g.DrawString(('{0} {1} {2}   {3}' -f $r.R, $r.G, $r.B, $r.Hex), $fontMono, $grey, 560, ($y + 8))
    $g.DrawString($r.Layer, $fontMono, $grey, 800, ($y + 8))
    $g.DrawString($cond, $fontMono, $grey, 920, ($y + 8))
    $g.DrawString($r.Sample, $fontMono, $grey, 1050, ($y + 8))
    $y += $rowH
}

$bmp.Save("$outDir\worlded-colors.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"готово: $outDir\worlded-colors.md и $outDir\worlded-colors.png"
