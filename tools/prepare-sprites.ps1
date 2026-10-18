param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\assets\source\starfall'),
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\assets\sprites')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Export-Cutout {
    param(
        [string]$Source,
        [string]$Target,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [System.Drawing.Color[]]$BackgroundColors = @([System.Drawing.Color]::White),
        [int]$Tolerance = 30
    )

    $inputBitmap = [System.Drawing.Bitmap]::FromFile($Source)
    try {
        $crop = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($crop)
        try {
            $graphics.DrawImage($inputBitmap, [System.Drawing.Rectangle]::new(0, 0, $Width, $Height), [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height), [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally {
            $graphics.Dispose()
        }

        $minX = $Width
        $minY = $Height
        $maxX = -1
        $maxY = -1
        $threshold = $Tolerance * $Tolerance

        for ($py = 0; $py -lt $Height; $py++) {
            for ($px = 0; $px -lt $Width; $px++) {
                $pixel = $crop.GetPixel($px, $py)
                $isBackground = $false
                foreach ($background in $BackgroundColors) {
                    $dr = [int]$pixel.R - [int]$background.R
                    $dg = [int]$pixel.G - [int]$background.G
                    $db = [int]$pixel.B - [int]$background.B
                    if (($dr * $dr + $dg * $dg + $db * $db) -le $threshold) {
                        $isBackground = $true
                        break
                    }
                }
                if ($pixel.R -ge 247 -and $pixel.G -ge 247 -and $pixel.B -ge 247) {
                    $isBackground = $true
                }

                if ($isBackground) {
                    $crop.SetPixel($px, $py, [System.Drawing.Color]::Transparent)
                }
                else {
                    $minX = [Math]::Min($minX, $px)
                    $minY = [Math]::Min($minY, $py)
                    $maxX = [Math]::Max($maxX, $px)
                    $maxY = [Math]::Max($maxY, $py)
                }
            }
        }

        if ($maxX -lt $minX -or $maxY -lt $minY) {
            throw "No foreground pixels found in $Source"
        }

        $padding = 4
        $left = [Math]::Max(0, $minX - $padding)
        $top = [Math]::Max(0, $minY - $padding)
        $right = [Math]::Min($Width - 1, $maxX + $padding)
        $bottom = [Math]::Min($Height - 1, $maxY + $padding)
        $trimWidth = $right - $left + 1
        $trimHeight = $bottom - $top + 1

        $result = New-Object System.Drawing.Bitmap $trimWidth, $trimHeight, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $resultGraphics = [System.Drawing.Graphics]::FromImage($result)
        try {
            $resultGraphics.DrawImage($crop, [System.Drawing.Rectangle]::new(0, 0, $trimWidth, $trimHeight), [System.Drawing.Rectangle]::new($left, $top, $trimWidth, $trimHeight), [System.Drawing.GraphicsUnit]::Pixel)
            $result.Save($Target, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $resultGraphics.Dispose()
            $result.Dispose()
        }
        $crop.Dispose()
    }
    finally {
        $inputBitmap.Dispose()
    }
}

$gray = [System.Drawing.Color]::FromArgb(100, 90, 89)
$blue = [System.Drawing.Color]::FromArgb(50, 113, 234)

Export-Cutout -Source (Join-Path $SourceRoot 'epathy.png') -Target (Join-Path $OutputRoot 'epathy.png') -X 0 -Y 0 -Width 253 -Height 348
Export-Cutout -Source (Join-Path $SourceRoot 'anubarak.png') -Target (Join-Path $OutputRoot 'anubarak.png') -X 0 -Y 0 -Width 277 -Height 222
Export-Cutout -Source (Join-Path $SourceRoot 'wolves-fire-ice.png') -Target (Join-Path $OutputRoot 'wolf_fire.png') -X 0 -Y 0 -Width 278 -Height 205 -BackgroundColors @($gray) -Tolerance 24
Export-Cutout -Source (Join-Path $SourceRoot 'wolves-fire-ice.png') -Target (Join-Path $OutputRoot 'wolf_ice.png') -X 0 -Y 235 -Width 278 -Height 240 -BackgroundColors @($gray) -Tolerance 24
Export-Cutout -Source (Join-Path $SourceRoot 'wolf-spectral.png') -Target (Join-Path $OutputRoot 'wolf_spectral.png') -X 2 -Y 2 -Width 282 -Height 253 -BackgroundColors @([System.Drawing.Color]::White, $blue) -Tolerance 26
Export-Cutout -Source (Join-Path $SourceRoot 'beetles-fire-ice.png') -Target (Join-Path $OutputRoot 'beetle_fire.png') -X 0 -Y 0 -Width 277 -Height 242
Export-Cutout -Source (Join-Path $SourceRoot 'beetles-fire-ice.png') -Target (Join-Path $OutputRoot 'beetle_ice.png') -X 0 -Y 244 -Width 277 -Height 292
Export-Cutout -Source (Join-Path $SourceRoot 'beetle-green.png') -Target (Join-Path $OutputRoot 'beetle_green.png') -X 0 -Y 0 -Width 278 -Height 253
Export-Cutout -Source (Join-Path $SourceRoot 'robots-red-blue.png') -Target (Join-Path $OutputRoot 'robot_red.png') -X 0 -Y 0 -Width 277 -Height 210
Export-Cutout -Source (Join-Path $SourceRoot 'robots-red-blue.png') -Target (Join-Path $OutputRoot 'robot_blue.png') -X 0 -Y 212 -Width 277 -Height 210
Export-Cutout -Source (Join-Path $SourceRoot 'robot-green.png') -Target (Join-Path $OutputRoot 'robot_green.png') -X 0 -Y 0 -Width 276 -Height 252

Write-Host "Prepared sprites in $OutputRoot"
