<#
.SYNOPSIS
    Removes baked-in caption/badge bands from QE art, keeping only the main
    subject.

.DESCRIPTION
    Several QE sprite frames and sliced contact-sheet tiles have decorative
    content baked in above and/or below the actual subject - a caption like
    "RUN (8 FRAMES)" burned into the first frame of an animation row, or a
    level-badge icon under each bestiary creature. Both sit in their own
    horizontal band, separated from the subject by a run of fully-transparent
    rows, because the source montage laid captions/badges outside the
    subject's own bounding box.

    This scans row by row for content (alpha > -AlphaThreshold) and groups
    rows into runs separated by gaps of >= -MinGapRows empty rows. Only the
    TOPMOST and BOTTOMMOST runs are ever candidates for removal - each is
    dropped if its row-count height is under -MinHeightRatio of the tallest
    of the *other* runs. Any run in between is always kept, no matter its
    size. That restriction matters: sprawling creatures (spread wings, many
    legs) can fragment their own silhouette into several runs, and a version
    of this that judged every run purely by "is it tall enough" left the
    bottom badge behind on several such creatures - or worse, dropped a real
    interior part - because a mid-body run and a badge run can land in the
    same height range. Edge-only candidacy plus "always keep the middle"
    fixes both: a label/badge is structurally always outermost, so it's
    never one of the runs that gets a free pass just for being sandwiched.

    Height, not pixel area, is the signal for the size test: a caption is a
    thin band of dense text that can rival the subject in opaque-pixel count
    despite being only a few rows tall, so area alone under-drops it.

    The output is cropped to the bounding box of what's kept, on both axes.
    Requires real alpha - run dekey_alpha.ps1 first if the source is opaque.

    A single-run image (no caption/badge baked in) passes through with just a
    tight crop - safe to run over an entire already-clean directory.

.EXAMPLE
    .\strip_bands.ps1 -InputDir out\creatures_sliced -OutDir out\creatures_clean

.EXAMPLE
    .\strip_bands.ps1 -InputDir ..\..\VisualAssets\...\characters\sprites\player -OutDir out\player_clean
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$InputDir,
    [Parameter(Mandatory = $true)][string]$OutDir,

    [int]$AlphaThreshold = 8,

    # Minimum run of consecutive empty rows to count as a real separator
    # rather than a 1px antialiasing gap inside the subject.
    [int]$MinGapRows = 2,

    # Runs whose row-count height is smaller than this fraction of the
    # tallest run's height are treated as decorative (caption/badge) and
    # dropped.
    [double]$MinHeightRatio = 0.4,

    [string]$Filter = "*.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class QeBandStripper
{
    public class Run { public int Top; public int Bottom; public long Area; }

    public static List<Run> FindRuns(byte[] bytes, int stride, int w, int h, int alphaThreshold, int minGap)
    {
        int[] rowArea = new int[h];
        for (int y = 0; y < h; y++)
        {
            int row = y * stride;
            int area = 0;
            for (int x = 0; x < w; x++)
                if (bytes[row + x * 4 + 3] > alphaThreshold) area++;
            rowArea[y] = area;
        }

        List<Run> runs = new List<Run>();
        int top = -1;
        long area2 = 0;
        int emptyRun = 0;
        for (int y = 0; y < h; y++)
        {
            if (rowArea[y] > 0)
            {
                if (top < 0) top = y;
                area2 += rowArea[y];
                emptyRun = 0;
            }
            else
            {
                emptyRun++;
                if (top >= 0 && emptyRun >= minGap)
                {
                    runs.Add(new Run { Top = top, Bottom = y - emptyRun, Area = area2 });
                    top = -1; area2 = 0;
                }
            }
        }
        if (top >= 0) runs.Add(new Run { Top = top, Bottom = h - 1, Area = area2 });
        return runs;
    }

    // Tight horizontal bounds within [top, bottom] rows.
    public static Rectangle? ColumnBounds(byte[] bytes, int stride, int w, int top, int bottom, int alphaThreshold)
    {
        int minX = w, maxX = -1;
        for (int y = top; y <= bottom; y++)
        {
            int row = y * stride;
            for (int x = 0; x < w; x++)
            {
                if (bytes[row + x * 4 + 3] > alphaThreshold)
                {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                }
            }
        }
        if (maxX < 0) return null;
        return new Rectangle(minX, top, maxX - minX + 1, bottom - top + 1);
    }
}
"@

$InputDir = (Resolve-Path $InputDir).Path
$files = Get-ChildItem -Path $InputDir -Recurse -Filter $Filter | Sort-Object FullName
if ($files.Count -eq 0) { throw "No files matching '$Filter' under $InputDir" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }

Write-Host "Stripping bands from $($files.Count) file(s), minHeightRatio=$MinHeightRatio"

$strippedCount = 0
$passedCount = 0
$emptyCount = 0

foreach ($f in $files) {
    $rel = $f.FullName.Substring($InputDir.Length).TrimStart('\')
    $outPath = Join-Path $OutDir $rel
    $outParent = Split-Path -Parent $outPath
    if ($outParent -and -not (Test-Path $outParent)) { New-Item -ItemType Directory -Force $outParent | Out-Null }

    $src = New-Object System.Drawing.Bitmap $f.FullName
    $w = $src.Width; $h = $src.Height
    $data = $src.LockBits((New-Object System.Drawing.Rectangle 0, 0, $w, $h),
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $src.UnlockBits($data)

    $runs = [QeBandStripper]::FindRuns($bytes, $stride, $w, $h, $AlphaThreshold, $MinGapRows)

    if ($runs.Count -eq 0) {
        Write-Host "  $rel : EMPTY (fully transparent - skipped)"
        $emptyCount++
        $src.Dispose()
        continue
    }

    $n = $runs.Count
    $heights = @($runs | ForEach-Object { $_.Bottom - $_.Top + 1 })
    $keepFlags = @($true) * $n

    if ($n -gt 1) {
        # Topmost run: judged against the tallest of everything else.
        $othersMaxForFirst = ($heights[1..($n - 1)] | Measure-Object -Maximum).Maximum
        if ($heights[0] -lt ($othersMaxForFirst * $MinHeightRatio)) { $keepFlags[0] = $false }

        # Bottommost run: judged against the tallest of everything else.
        $othersMaxForLast = ($heights[0..($n - 2)] | Measure-Object -Maximum).Maximum
        if ($heights[$n - 1] -lt ($othersMaxForLast * $MinHeightRatio)) { $keepFlags[$n - 1] = $false }
    }

    $kept = @()
    for ($i = 0; $i -lt $n; $i++) { if ($keepFlags[$i]) { $kept += $runs[$i] } }
    if ($kept.Count -eq 0) { $kept = $runs } # never drop everything
    $dropped = $n - $kept.Count

    $top = ($kept | Measure-Object -Property Top -Minimum).Minimum
    $bottom = ($kept | Measure-Object -Property Bottom -Maximum).Maximum

    # A .NET Rectangle? that HasValue boxes to a plain Rectangle across the
    # PowerShell interop boundary (no .Value wrapper) - only a real null
    # stays null. So check for $null directly rather than calling .Value.
    $boundsRect = [QeBandStripper]::ColumnBounds($bytes, $stride, $w, $top, $bottom, $AlphaThreshold)
    $cropW = $boundsRect.Width
    $cropH = $boundsRect.Height

    $crop = New-Object System.Drawing.Bitmap -ArgumentList @($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($crop)
    $destRect = New-Object System.Drawing.Rectangle -ArgumentList @(0, 0, $cropW, $cropH)
    $g.DrawImage($src, $destRect, $boundsRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $crop.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    $src.Dispose()

    if ($dropped -gt 0) {
        Write-Host "  $rel : dropped $dropped band(s), kept ${cropW}x${cropH}"
        $strippedCount++
    } else {
        Write-Host "  $rel : no bands (single run), cropped to ${cropW}x${cropH}"
        $passedCount++
    }
}

Write-Host "Stripped $strippedCount, passed-through $passedCount, empty $emptyCount. Wrote to $OutDir"
