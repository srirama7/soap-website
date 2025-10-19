# PowerShell script to resize images for web use
Add-Type -AssemblyName System.Drawing

$imageFolder = "C:\Users\amogh\Downloads\ayushree website\images"
$maxWidth = 800
$maxHeight = 800
$quality = 85

# Get all jpg files
$images = Get-ChildItem -Path $imageFolder -Filter "*.jpg"

foreach ($img in $images) {
    Write-Host "Processing: $($img.Name)"

    # Create backup folder if it doesn't exist
    $backupFolder = Join-Path $imageFolder "originals"
    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder | Out-Null
    }

    # Backup original
    $backupPath = Join-Path $backupFolder $img.Name
    Copy-Item $img.FullName $backupPath -Force
    Write-Host "  Backed up to: originals\$($img.Name)"

    # Load image
    $image = [System.Drawing.Image]::FromFile($img.FullName)

    # Calculate new dimensions maintaining aspect ratio
    $ratioX = $maxWidth / $image.Width
    $ratioY = $maxHeight / $image.Height
    $ratio = [Math]::Min($ratioX, $ratioY)

    $newWidth = [int]($image.Width * $ratio)
    $newHeight = [int]($image.Height * $ratio)

    Write-Host "  Original: $($image.Width)x$($image.Height)"
    Write-Host "  Resized: ${newWidth}x${newHeight}"

    # Create new bitmap
    $newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($newImage)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)

    # Save with compression
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality, $quality
    )

    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' }

    # Dispose original and save new
    $image.Dispose()
    $newImage.Save($img.FullName, $jpegCodec, $encoderParams)
    $newImage.Dispose()
    $graphics.Dispose()

    $newSize = (Get-Item $img.FullName).Length
    Write-Host "  New file size: $([Math]::Round($newSize/1KB, 2)) KB"
    Write-Host ""
}

Write-Host "All images resized successfully!"
Write-Host "Original images backed up to: $backupFolder"
