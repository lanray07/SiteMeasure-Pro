Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $root "SiteMeasurePro\Resources\Assets.xcassets"
$marketingRoot = Join-Path $root "MarketingAssets"

New-Item -ItemType Directory -Force -Path $assetRoot, $marketingRoot | Out-Null

function New-Directory($path) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function New-Canvas([int]$width, [int]$height) {
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @{ Bitmap = $bmp; Graphics = $g }
}

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-Png($bitmap, [string]$path) {
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Write-Json([string]$path, [object]$data) {
    $json = $data | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Draw-BrandIcon([int]$size, [string]$path) {
    $canvas = New-Canvas $size $size
    $bmp = $canvas.Bitmap
    $g = $canvas.Graphics
    $rect = [System.Drawing.Rectangle]::new(0, 0, $size, $size)
    $bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::FromArgb(15, 57, 60), [System.Drawing.Color]::FromArgb(34, 134, 104), 45)
    $g.FillRectangle($bg, $rect)

    $scale = $size / 1024.0
    $cardPath = New-RoundedPath (160 * $scale) (170 * $scale) (704 * $scale) (704 * $scale) (162 * $scale)
    $cardBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.RectangleF]::new(160 * $scale, 170 * $scale, 704 * $scale, 704 * $scale), [System.Drawing.Color]::FromArgb(238, 255, 248), [System.Drawing.Color]::FromArgb(184, 233, 226), 25)
    $g.FillPath($cardBrush, $cardPath)

    $blue = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(26, 126, 191), [float][Math]::Max(10, 52 * $scale))
    $green = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(19, 128, 83), [float][Math]::Max(8, 42 * $scale))
    $charcoal = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 42, 43))
    $pinBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 149, 96))

    $g.DrawLine($green, 282 * $scale, 704 * $scale, 735 * $scale, 251 * $scale)
    $g.DrawLine($blue, 296 * $scale, 310 * $scale, 724 * $scale, 738 * $scale)

    for ($i = 0; $i -lt 7; $i++) {
        $x = (350 + $i * 52) * $scale
        $y = (644 - $i * 52) * $scale
        $g.DrawLine($green, $x, $y, $x + (34 * $scale), $y + (34 * $scale))
    }

    $g.FillEllipse($pinBrush, 245 * $scale, 642 * $scale, 92 * $scale, 92 * $scale)
    $g.FillEllipse($pinBrush, 692 * $scale, 197 * $scale, 92 * $scale, 92 * $scale)

    $font = [System.Drawing.Font]::new("Arial", [float](142 * $scale), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString("SM", $font, $charcoal, ([System.Drawing.RectangleF]::new(0, 426 * $scale, $size, 180 * $scale)), $format)

    Save-Png $bmp $path
    $g.Dispose()
    $bmp.Dispose()
}

function Draw-HeroImage([int]$width, [int]$height, [string]$path) {
    $canvas = New-Canvas $width $height
    $bmp = $canvas.Bitmap
    $g = $canvas.Graphics
    $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $sky = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::FromArgb(232, 249, 247), [System.Drawing.Color]::FromArgb(246, 250, 247), 90)
    $g.FillRectangle($sky, $rect)

    $grass = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(107, 165, 112))
    $patio = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(208, 214, 204))
    $drive = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(96, 113, 117))
    $roof = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(49, 68, 70))
    $house = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 236, 226))
    $fencePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(144, 115, 80), 16)

    $g.FillRectangle($grass, 0, [int]($height * 0.52), $width, [int]($height * 0.48))
    for ($x = 60; $x -lt $width; $x += 86) {
        $g.DrawLine($fencePen, $x, [int]($height * 0.47), $x, [int]($height * 0.62))
    }
    $g.DrawLine($fencePen, 0, [int]($height * 0.51), $width, [int]($height * 0.51))

    $housePath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $housePath.AddPolygon(@(
        [System.Drawing.Point]::new([int]($width * 0.58), [int]($height * 0.2)),
        [System.Drawing.Point]::new([int]($width * 0.84), [int]($height * 0.2)),
        [System.Drawing.Point]::new([int]($width * 0.91), [int]($height * 0.42)),
        [System.Drawing.Point]::new([int]($width * 0.52), [int]($height * 0.42))
    ))
    $g.FillPath($roof, $housePath)
    $g.FillRectangle($house, [int]($width * 0.58), [int]($height * 0.36), [int]($width * 0.27), [int]($height * 0.18))

    $patioPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $patioPath.AddPolygon(@(
        [System.Drawing.Point]::new([int]($width * 0.08), [int]($height * 0.70)),
        [System.Drawing.Point]::new([int]($width * 0.47), [int]($height * 0.57)),
        [System.Drawing.Point]::new([int]($width * 0.69), [int]($height * 0.92)),
        [System.Drawing.Point]::new([int]($width * 0.18), [int]($height * 0.96))
    ))
    $g.FillPath($patio, $patioPath)

    $drivePath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $drivePath.AddPolygon(@(
        [System.Drawing.Point]::new([int]($width * 0.70), [int]($height * 0.58)),
        [System.Drawing.Point]::new([int]($width * 0.94), [int]($height * 0.61)),
        [System.Drawing.Point]::new($width, $height),
        [System.Drawing.Point]::new([int]($width * 0.61), $height)
    ))
    $g.FillPath($drive, $drivePath)

    $measurePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(30, 148, 96), 10)
    $measurePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $points = @(
        [System.Drawing.Point]::new([int]($width * 0.11), [int]($height * 0.68)),
        [System.Drawing.Point]::new([int]($width * 0.47), [int]($height * 0.56)),
        [System.Drawing.Point]::new([int]($width * 0.68), [int]($height * 0.91)),
        [System.Drawing.Point]::new([int]($width * 0.18), [int]($height * 0.95))
    )
    $g.DrawPolygon($measurePen, $points)

    $pinBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(27, 118, 186))
    foreach ($p in $points) {
        $g.FillEllipse($pinBrush, $p.X - 18, $p.Y - 18, 36, 36)
    }

    $panelPath = New-RoundedPath 64 64 480 256 32
    $panelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 255, 255, 255))
    $g.FillPath($panelBrush, $panelPath)
    $titleFont = [System.Drawing.Font]::new("Arial", 46, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $bodyFont = [System.Drawing.Font]::new("Arial", 26, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(29, 43, 45))
    $mutedBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(78, 95, 96))
    $g.DrawString("SiteMeasure Pro", $titleFont, $textBrush, 104, 106)
    $g.DrawString("AI-assisted field estimates", $bodyFont, $mutedBrush, 108, 168)
    $g.DrawString("Area 48.7 sq m  |  Confidence 78%", $bodyFont, $mutedBrush, 108, 214)

    Save-Png $bmp $path
    $g.Dispose()
    $bmp.Dispose()
}

function Draw-EmptyState([int]$width, [int]$height, [string]$path, [string]$label, [string]$glyph) {
    $canvas = New-Canvas $width $height
    $bmp = $canvas.Bitmap
    $g = $canvas.Graphics
    $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::FromArgb(245, 250, 248), [System.Drawing.Color]::FromArgb(225, 242, 240), 90)
    $g.FillRectangle($bg, $rect)

    $cardPath = New-RoundedPath 90 86 ($width - 180) ($height - 172) 34
    $cardBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
    $g.FillPath($cardBrush, $cardPath)

    $accent = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(35, 145, 98), 10)
    $blue = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(33, 126, 188), 8)
    $g.DrawRectangle($accent, 176, 160, $width - 352, $height - 320)
    $g.DrawLine($blue, 220, $height - 210, $width - 220, 210)
    $g.DrawEllipse($accent, [int]($width / 2 - 70), [int]($height / 2 - 70), 140, 140)

    $glyphFont = [System.Drawing.Font]::new("Arial", 74, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $labelFont = [System.Drawing.Font]::new("Arial", 30, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(31, 45, 46))
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($glyph, $glyphFont, $textBrush, ([System.Drawing.RectangleF]::new(0, [int]($height / 2 - 54), $width, 90)), $format)
    $g.DrawString($label, $labelFont, $textBrush, ([System.Drawing.RectangleF]::new(0, $height - 128, $width, 60)), $format)

    Save-Png $bmp $path
    $g.Dispose()
    $bmp.Dispose()
}

function New-ImageSet([string]$name, [string]$filename) {
    $dir = Join-Path $assetRoot "$name.imageset"
    New-Directory $dir
    Write-Json (Join-Path $dir "Contents.json") @{
        images = @(
            @{
                idiom = "universal"
                filename = $filename
                scale = "1x"
            }
        )
        info = @{
            author = "xcode"
            version = 1
        }
    }
    return $dir
}

function New-ColorSet([string]$name, [string]$red, [string]$green, [string]$blue, [string]$alpha = "1.000") {
    $dir = Join-Path $assetRoot "$name.colorset"
    New-Directory $dir
    Write-Json (Join-Path $dir "Contents.json") @{
        colors = @(
            @{
                idiom = "universal"
                color = @{
                    "color-space" = "srgb"
                    components = @{
                        alpha = $alpha
                        red = $red
                        green = $green
                        blue = $blue
                    }
                }
            }
        )
        info = @{
            author = "xcode"
            version = 1
        }
    }
}

Write-Json (Join-Path $assetRoot "Contents.json") @{
    info = @{
        author = "xcode"
        version = 1
    }
}

New-ColorSet "AccentColor" "0.120" "0.620" "0.420"
New-ColorSet "BrandGreen" "0.080" "0.500" "0.325"
New-ColorSet "BrandBlue" "0.100" "0.450" "0.780"
New-ColorSet "BrandCharcoal" "0.090" "0.125" "0.130"
New-ColorSet "LaunchBackground" "0.945" "0.984" "0.965"

$appIconDir = Join-Path $assetRoot "AppIcon.appiconset"
New-Directory $appIconDir
$iconSpecs = @(
    @{ size = "20x20"; idiom = "iphone"; scale = "2x"; pixels = 40 },
    @{ size = "20x20"; idiom = "iphone"; scale = "3x"; pixels = 60 },
    @{ size = "29x29"; idiom = "iphone"; scale = "2x"; pixels = 58 },
    @{ size = "29x29"; idiom = "iphone"; scale = "3x"; pixels = 87 },
    @{ size = "40x40"; idiom = "iphone"; scale = "2x"; pixels = 80 },
    @{ size = "40x40"; idiom = "iphone"; scale = "3x"; pixels = 120 },
    @{ size = "60x60"; idiom = "iphone"; scale = "2x"; pixels = 120 },
    @{ size = "60x60"; idiom = "iphone"; scale = "3x"; pixels = 180 },
    @{ size = "20x20"; idiom = "ipad"; scale = "1x"; pixels = 20 },
    @{ size = "20x20"; idiom = "ipad"; scale = "2x"; pixels = 40 },
    @{ size = "29x29"; idiom = "ipad"; scale = "1x"; pixels = 29 },
    @{ size = "29x29"; idiom = "ipad"; scale = "2x"; pixels = 58 },
    @{ size = "40x40"; idiom = "ipad"; scale = "1x"; pixels = 40 },
    @{ size = "40x40"; idiom = "ipad"; scale = "2x"; pixels = 80 },
    @{ size = "76x76"; idiom = "ipad"; scale = "1x"; pixels = 76 },
    @{ size = "76x76"; idiom = "ipad"; scale = "2x"; pixels = 152 },
    @{ size = "83.5x83.5"; idiom = "ipad"; scale = "2x"; pixels = 167 },
    @{ size = "1024x1024"; idiom = "ios-marketing"; scale = "1x"; pixels = 1024 }
)

$iconImages = @()
foreach ($spec in $iconSpecs) {
    $filename = "Icon-$($spec.pixels).png"
    Draw-BrandIcon $spec.pixels (Join-Path $appIconDir $filename)
    $entry = @{
        size = $spec.size
        idiom = $spec.idiom
        filename = $filename
        scale = $spec.scale
    }
    $iconImages += $entry
}
Write-Json (Join-Path $appIconDir "Contents.json") @{
    images = $iconImages
    info = @{
        author = "xcode"
        version = 1
    }
}

$brandDir = New-ImageSet "BrandMark" "BrandMark.png"
Draw-BrandIcon 1024 (Join-Path $brandDir "BrandMark.png")

$launchDir = New-ImageSet "LaunchLogo" "LaunchLogo.png"
Draw-BrandIcon 512 (Join-Path $launchDir "LaunchLogo.png")

$heroDir = New-ImageSet "OnboardingHero" "OnboardingHero.png"
Draw-HeroImage 1600 1000 (Join-Path $heroDir "OnboardingHero.png")

$projectsDir = New-ImageSet "EmptyProjects" "EmptyProjects.png"
Draw-EmptyState 900 620 (Join-Path $projectsDir "EmptyProjects.png") "Projects" "P"

$measurementsDir = New-ImageSet "EmptyMeasurements" "EmptyMeasurements.png"
Draw-EmptyState 900 620 (Join-Path $measurementsDir "EmptyMeasurements.png") "Measure" "M"

$proposalDir = New-ImageSet "ProposalPreview" "ProposalPreview.png"
Draw-EmptyState 900 620 (Join-Path $proposalDir "ProposalPreview.png") "Proposal" "PDF"

Copy-Item -LiteralPath (Join-Path $appIconDir "Icon-1024.png") -Destination (Join-Path $marketingRoot "AppStoreIcon-1024.png") -Force
Copy-Item -LiteralPath (Join-Path $heroDir "OnboardingHero.png") -Destination (Join-Path $marketingRoot "SiteMeasurePro-Hero-1600x1000.png") -Force
Copy-Item -LiteralPath (Join-Path $proposalDir "ProposalPreview.png") -Destination (Join-Path $marketingRoot "ProposalPreview-900x620.png") -Force

Write-Output "Generated SiteMeasure Pro app assets in $assetRoot and marketing assets in $marketingRoot"
