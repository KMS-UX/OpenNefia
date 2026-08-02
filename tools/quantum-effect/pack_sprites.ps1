<#
.SYNOPSIS
    Packs loose Quantum Effect artwork into a grid-aligned sprite sheet.

.DESCRIPTION
    Quantum Effect's art is authored as individually-cropped illustrations at
    arbitrary dimensions (26x40, 226x132, ...). OpenNefia's chip system needs a
    rigid grid: fixed-size cells laid out in a fixed number of columns, indexed
    by `x = (id % columns) * cellWidth`, `y = floor(id / columns) * cellHeight`
    (see src/mod/elona/data/chip.lua's make_chip_group).

    This script bridges the two. Per source image it: trims transparent
    margins, scales to fit the cell while preserving aspect ratio, anchors the
    result within the cell, then composites it into the sheet. It emits the
    sheet as PNG (real alpha - OpenNefia routes non-.bmp sources straight to
    love.graphics.newImage, so no key-colour transparency is needed) plus a
    manifest recording which source file landed at which index.

    Cell size is deliberately a parameter, not a constant: whether QE art
    reads better at Elona's native 48x48 or at a larger cell is an open
    question, and answering it means generating both and looking at them.

.EXAMPLE
    .\pack_sprites.ps1 -InputDir ..\..\VisualAssets\...\sprites\player `
                       -OutSheet out\player_48.png -Cell 48

.NOTES
    Uses System.Drawing via inline C# rather than PowerShell pixel loops -
    a full-image alpha scan in PowerShell is orders of magnitude too slow.
#>
[CmdletBinding()]
param(
    # Directory of source .png artwork. Searched recursively.
    [Parameter(Mandatory = $true)][string]$InputDir,

    # Destination .png sprite sheet.
    [Parameter(Mandatory = $true)][string]$OutSheet,

    # Destination manifest. Defaults to <OutSheet>.manifest.json.
    [string]$OutManifest,

    # Cell width in pixels. 48 matches Elona/OpenNefia's native chip size.
    [int]$Cell = 48,

    # Cell height. 0 means square (same as -Cell). Elona uses 96 for `is_tall` chips.
    [int]$CellHeight = 0,

    # Columns per sheet row. 33 is OpenNefia's convention.
    [int]$Columns = 33,

    # Where art sits inside its cell. Characters/props stand on the ground
    # (bottom); items and icons read better centred.
    [ValidateSet("bottom", "center")][string]$Anchor = "bottom",

    # nearest keeps hard pixel edges when enlarging; bicubic preserves detail
    # when shrinking; auto picks per-image based on scale direction.
    [ValidateSet("nearest", "bicubic", "auto")][string]$Interpolation = "auto",

    # Alpha at or below this counts as empty when trimming.
    [int]$AlphaThreshold = 8,

    # Keep the source's own transparent margins instead of trimming to content.
    [switch]$NoTrim,

    # Never draw art larger than authored; smaller art is centred in its cell.
    [switch]$NoUpscale,

    # Restricts which files are picked up.
    [string]$Filter = "*.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class QePacker
{
    // Tight bounding box of pixels with alpha > threshold.
    // Returns null when the image is fully transparent.
    static Rectangle? ContentBounds(Bitmap bmp, int threshold)
    {
        BitmapData data = bmp.LockBits(
            new Rectangle(0, 0, bmp.Width, bmp.Height),
            ImageLockMode.ReadOnly,
            PixelFormat.Format32bppArgb);

        int stride = data.Stride;
        byte[] bytes = new byte[stride * bmp.Height];
        Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
        bmp.UnlockBits(data);

        int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < bmp.Height; y++)
        {
            int row = y * stride;
            for (int x = 0; x < bmp.Width; x++)
            {
                // 32bppArgb is laid out B,G,R,A in memory.
                if (bytes[row + x * 4 + 3] > threshold)
                {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }

        if (maxX < 0) return null;
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    public static List<string> Pack(
        string[] files, string outPath,
        int cellW, int cellH, int columns,
        string anchor, string interpolation,
        int alphaThreshold, bool trim, bool allowUpscale)
    {
        List<string> manifest = new List<string>();
        int rows = (int)Math.Ceiling((double)files.Length / columns);
        if (rows < 1) rows = 1;

        using (Bitmap sheet = new Bitmap(columns * cellW, rows * cellH, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.Transparent);
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.SmoothingMode = SmoothingMode.None;

            for (int i = 0; i < files.Length; i++)
            {
                using (Bitmap src = new Bitmap(files[i]))
                {
                    Rectangle crop = new Rectangle(0, 0, src.Width, src.Height);
                    if (trim)
                    {
                        Rectangle? b = ContentBounds(src, alphaThreshold);
                        if (b == null) continue;   // fully transparent - skip, keep the slot empty
                        crop = b.Value;
                    }

                    // Fit inside the cell without distorting aspect ratio.
                    double scale = Math.Min((double)cellW / crop.Width, (double)cellH / crop.Height);
                    if (!allowUpscale && scale > 1.0) scale = 1.0;

                    int drawW = Math.Max(1, (int)Math.Round(crop.Width * scale));
                    int drawH = Math.Max(1, (int)Math.Round(crop.Height * scale));

                    string mode = interpolation;
                    if (mode == "auto") mode = (scale >= 1.0) ? "nearest" : "bicubic";
                    if (mode == "nearest")
                    {
                        g.InterpolationMode = InterpolationMode.NearestNeighbor;
                        g.PixelOffsetMode = PixelOffsetMode.Half;   // avoids a half-pixel shift
                    }
                    else
                    {
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    }

                    int cellX = (i % columns) * cellW;
                    int cellY = (i / columns) * cellH;

                    int offX = cellX + (cellW - drawW) / 2;                       // always horizontally centred
                    int offY = (anchor == "bottom") ? cellY + (cellH - drawH)     // feet on the cell floor
                                                    : cellY + (cellH - drawH) / 2;

                    g.DrawImage(src, new Rectangle(offX, offY, drawW, drawH),
                                crop.X, crop.Y, crop.Width, crop.Height,
                                GraphicsUnit.Pixel);

                    manifest.Add(string.Join("\t", new string[] {
                        i.ToString(),
                        files[i],
                        src.Width + "x" + src.Height,
                        crop.Width + "x" + crop.Height,
                        drawW + "x" + drawH,
                        scale.ToString("0.###"),
                        mode
                    }));
                }
            }

            sheet.Save(outPath, ImageFormat.Png);
        }

        return manifest;
    }
}
"@

if ($CellHeight -le 0) { $CellHeight = $Cell }
if (-not $OutManifest) { $OutManifest = "$OutSheet.manifest.json" }

$InputDir = (Resolve-Path $InputDir).Path
$files = Get-ChildItem -Path $InputDir -Recurse -Filter $Filter |
         Sort-Object FullName |
         ForEach-Object { $_.FullName }

if ($files.Count -eq 0) { throw "No files matching '$Filter' under $InputDir" }

$outDir = Split-Path -Parent $OutSheet
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }

Write-Host "Packing $($files.Count) file(s)"
Write-Host "  cell       : ${Cell}x${CellHeight}, $Columns columns, anchor=$Anchor"
Write-Host "  scaling    : $Interpolation$(if ($NoUpscale) { ', no upscale' })"

# .NET resolves relative paths against the process working directory, which is
# not PowerShell's - hand it absolute paths.
$absSheet = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine((Get-Location).Path, $OutSheet))

$manifest = [QePacker]::Pack(
    $files, $absSheet,
    $Cell, $CellHeight, $Columns,
    $Anchor, $Interpolation,
    $AlphaThreshold, (-not $NoTrim), (-not $NoUpscale))

# Manifest rows arrive tab-separated from the packer; reshape into JSON so the
# downstream chip-definition generator has something structured to read.
$entries = foreach ($row in $manifest) {
    $f = $row -split "`t"
    [PSCustomObject]@{
        index      = [int]$f[0]
        source     = $f[1].Replace($InputDir, '').TrimStart('\')
        sourceSize = $f[2]
        trimmed    = $f[3]
        drawn      = $f[4]
        scale      = [double]$f[5]
        resample   = $f[6]
    }
}

[PSCustomObject]@{
    sheet      = (Split-Path -Leaf $OutSheet)
    cellWidth  = $Cell
    cellHeight = $CellHeight
    columns    = $Columns
    rows       = [int][Math]::Ceiling($entries.Count / $Columns)
    anchor     = $Anchor
    count      = $entries.Count
    inputDir   = $InputDir
    entries    = $entries
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutManifest -Encoding utf8

$up   = ($entries | Where-Object { $_.scale -gt 1 }).Count
$down = ($entries | Where-Object { $_.scale -lt 1 }).Count
Write-Host "  scaled up  : $up"
Write-Host "  scaled down: $down"
Write-Host "Wrote $OutSheet"
Write-Host "Wrote $OutManifest"
