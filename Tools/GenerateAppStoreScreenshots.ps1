Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$shotRoot = Join-Path $root "AppStoreScreenshots"
New-Item -ItemType Directory -Force -Path $shotRoot | Out-Null

function New-Canvas([int]$width, [int]$height) {
    $bmp = [System.Drawing.Bitmap]::new($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @{ Bitmap = $bmp; Graphics = $g }
}

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-Text($g, [string]$text, [string]$fontName, [float]$size, $style, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [string]$align = "Near") {
    $font = [System.Drawing.Font]::new($fontName, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    if ($align -eq "Center") { $format.Alignment = [System.Drawing.StringAlignment]::Center }
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $format)
    $font.Dispose()
    $format.Dispose()
}

function Fill-Rounded($g, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-RoundedPath $x $y $w $h $r
    $g.FillPath($brush, $path)
    $path.Dispose()
}

function Stroke-Rounded($g, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-RoundedPath $x $y $w $h $r
    $g.DrawPath($pen, $path)
    $path.Dispose()
}

function Draw-PhoneFrame($g, [int]$width, [int]$height, [string]$mode) {
    $green = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(31, 137, 91))
    $blue = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(28, 116, 184))
    $charcoal = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(29, 42, 43))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(93, 111, 112))
    $paper = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(252, 253, 251))
    $surface = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(241, 247, 244))
    $linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(221, 229, 226), 3)
    $greenPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(31, 137, 91), 8)
    $bluePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(28, 116, 184), 8)

    $mx = [int]($width * 0.08)
    $screenY = [int]($height * 0.27)
    $screenW = $width - ($mx * 2)
    $screenH = [int]($height * 0.62)

    Fill-Rounded $g $paper $mx $screenY $screenW $screenH 54
    Stroke-Rounded $g $linePen $mx $screenY $screenW $screenH 54

    Draw-Text $g "SiteMeasure Pro" "Arial" ([int]($width * 0.044)) ([System.Drawing.FontStyle]::Bold) $charcoal ($mx + 48) ($screenY + 48) ($screenW - 96) 80

    if ($mode -eq "dashboard") {
        Draw-Text $g "Dashboard" "Arial" ([int]($width * 0.036)) ([System.Drawing.FontStyle]::Bold) $charcoal ($mx + 48) ($screenY + 144) 400 70
        $tileW = ($screenW - 136) / 2
        $tileH = 190
        $labels = @("Recent Projects`n18", "Pending Quotes`n7", "Saved Proposals`n12", "Estimated Revenue`nGBP 48.6k")
        for ($i = 0; $i -lt 4; $i++) {
            $x = $mx + 48 + (($i % 2) * ($tileW + 40))
            $y = $screenY + 230 + ([Math]::Floor($i / 2) * ($tileH + 36))
            Fill-Rounded $g $surface $x $y $tileW $tileH 24
            Draw-Text $g $labels[$i] "Arial" ([int]($width * 0.027)) ([System.Drawing.FontStyle]::Bold) $charcoal ($x + 28) ($y + 32) ($tileW - 56) ($tileH - 56)
        }
        Fill-Rounded $g $green ($mx + 48) ($screenY + 690) ($screenW - 96) 128 26
        Draw-Text $g "New Measurement" "Arial" ([int]($width * 0.03)) ([System.Drawing.FontStyle]::Bold) ([System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)) ($mx + 88) ($screenY + 728) ($screenW - 176) 60
    } elseif ($mode -eq "measurement") {
        Draw-Text $g "Mark site photos" "Arial" ([int]($width * 0.036)) ([System.Drawing.FontStyle]::Bold) $charcoal ($mx + 48) ($screenY + 144) 520 70
        $photoX = $mx + 48
        $photoY = $screenY + 230
        $photoW = $screenW - 96
        $photoH = 560
        Fill-Rounded $g ([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(204, 223, 211))) $photoX $photoY $photoW $photoH 28
        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $path.AddPolygon(@(
            [System.Drawing.Point]::new($photoX + 90, $photoY + 380),
            [System.Drawing.Point]::new($photoX + 470, $photoY + 250),
            [System.Drawing.Point]::new($photoX + 780, $photoY + 430),
            [System.Drawing.Point]::new($photoX + 230, $photoY + 500)
        ))
        $g.FillPath([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(222, 225, 218)), $path)
        $g.DrawPath($greenPen, $path)
        foreach ($pt in $path.PathPoints) { $g.FillEllipse($blue, $pt.X - 18, $pt.Y - 18, 36, 36) }
        $path.Dispose()
        Draw-Text $g "Width 10.8m  Area 92.1 sq m`nConfidence 78%" "Arial" ([int]($width * 0.027)) ([System.Drawing.FontStyle]::Bold) $charcoal ($mx + 74) ($screenY + 830) ($screenW - 148) 140
    } else {
        Draw-Text $g "Client-ready proposals" "Arial" ([int]($width * 0.034)) ([System.Drawing.FontStyle]::Bold) $charcoal ($mx + 48) ($screenY + 144) 650 70
        $docX = $mx + 98
        $docY = $screenY + 230
        $docW = $screenW - 196
        $docH = 720
        Fill-Rounded $g $surface $docX $docY $docW $docH 26
        Draw-Text $g "Project Proposal" "Arial" ([int]($width * 0.036)) ([System.Drawing.FontStyle]::Bold) $charcoal ($docX + 54) ($docY + 54) ($docW - 108) 80
        $rows = @("Measurements: 92.1 sq m", "Materials: GBP 2,840", "Labor: GBP 1,980", "Total Estimate: GBP 4,820", "Signature: __________")
        for ($i = 0; $i -lt $rows.Length; $i++) {
            $g.DrawLine($linePen, $docX + 54, $docY + 170 + ($i * 92), $docX + $docW - 54, $docY + 170 + ($i * 92))
            Draw-Text $g $rows[$i] "Arial" ([int]($width * 0.027)) ([System.Drawing.FontStyle]::Regular) $muted ($docX + 54) ($docY + 188 + ($i * 92)) ($docW - 108) 54
        }
        Fill-Rounded $g $blue ($mx + 48) ($screenY + 1010) ($screenW - 96) 128 26
        Draw-Text $g "Export PDF" "Arial" ([int]($width * 0.03)) ([System.Drawing.FontStyle]::Bold) ([System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)) ($mx + 88) ($screenY + 1048) ($screenW - 176) 60
    }

    $green.Dispose()
    $blue.Dispose()
    $charcoal.Dispose()
    $muted.Dispose()
    $paper.Dispose()
    $surface.Dispose()
    $linePen.Dispose()
    $greenPen.Dispose()
    $bluePen.Dispose()
}

function New-Screenshot([int]$width, [int]$height, [string]$title, [string]$subtitle, [string]$mode, [string]$path) {
    $canvas = New-Canvas $width $height
    $bmp = $canvas.Bitmap
    $g = $canvas.Graphics
    $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::FromArgb(232, 248, 244), [System.Drawing.Color]::FromArgb(247, 250, 248), 90)
    $g.FillRectangle($bg, $rect)
    $charcoal = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(27, 39, 41))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(78, 95, 96))
    Draw-Text $g $title "Arial" ([int]($width * 0.068)) ([System.Drawing.FontStyle]::Bold) $charcoal ([int]($width * 0.08)) ([int]($height * 0.055)) ([int]($width * 0.84)) ([int]($height * 0.12))
    Draw-Text $g $subtitle "Arial" ([int]($width * 0.034)) ([System.Drawing.FontStyle]::Regular) $muted ([int]($width * 0.08)) ([int]($height * 0.168)) ([int]($width * 0.84)) ([int]($height * 0.09))
    Draw-PhoneFrame $g $width $height $mode
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$sets = @(
    @{ Dir = "iPhone-6.5"; Width = 1242; Height = 2688 },
    @{ Dir = "iPad-12.9"; Width = 2048; Height = 2732 }
)

$screens = @(
    @{ File = "01-dashboard.png"; Title = "Estimate jobs faster"; Subtitle = "Create projects, track quotes, and see revenue at a glance."; Mode = "dashboard" },
    @{ File = "02-measurements.png"; Title = "Measure from site photos"; Subtitle = "Mark boundaries, review AI estimates, and adjust dimensions before quoting."; Mode = "measurement" },
    @{ File = "03-proposals.png"; Title = "Send polished proposals"; Subtitle = "Turn measurements, materials, and labor into client-ready PDF estimates."; Mode = "proposal" }
)

foreach ($set in $sets) {
    $dir = Join-Path $shotRoot $set.Dir
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    foreach ($screen in $screens) {
        New-Screenshot $set.Width $set.Height $screen.Title $screen.Subtitle $screen.Mode (Join-Path $dir $screen.File)
    }
}

Write-Output "Generated App Store screenshots in $shotRoot"
