<#
.SYNOPSIS
    Splits a QE contact sheet (several subjects side by side in one file)
    into one PNG per subject.

.DESCRIPTION
    Several QE source images hold multiple subjects in a single file - e.g.
    assets/bestiary/creatures/arctic.png (520x100) holds seven creatures.
    OpenNefia's chip system and pack_sprites.ps1 both expect one subject per
    source file, so those sheets need splitting before they're usable.

    This slices by content, not by a fixed subject count: it scans the image
    for columns that are entirely transparent (alpha <= -AlphaThreshold) and
    treats each run of non-empty columns, padded by -Gap columns of margin,
    as one subject. That means it only works on sheets with real alpha
    separating subjects - run dekey_alpha.ps1 first if the source is still
    fully opaque (as arctic.png originally is).

    Output filenames are `<basename>_NN.png`, numbered left to right. This is
    column-only slicing: baked-in captions or badge icons above/below each
    subject are NOT removed here - see strip_bands.ps1 for that.

.EXAMPLE
    .\dekey_alpha.ps1 -InputDir ..\..\VisualAssets\...\creatures -OutDir out\creatures_keyed
    .\slice_contact_sheet.ps1 -InputFile out\creatures_keyed\arctic.png -OutDir out\creatures_sliced
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$InputFile,
    [Parameter(Mandatory = $true)][string]$OutDir,

    # Alpha at or below this counts as an empty (divider) column/row.
    [int]$AlphaThreshold = 8,

    # Minimum run of consecutive empty columns to count as a real divider
    # rather than a 1px antialiasing gap inside a subject.
    [int]$MinGapColumns = 2,

    # Transparent margin kept around each sliced subject.
    [int]$Padding = 1,

    # Discard segments narrower than this - stray antialiasing fringe at a
    # sheet's edge, not a real subject.
    [int]$MinWidth = 8
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class QeSlicer
{
    public class Segment { public int Start; public int End; } // inclusive column range

    public static List<Segment> FindSegments(byte[] bytes, int stride, int w, int h, int alphaThreshold, int minGap)
    {
        bool[] colHasContent = new bool[w];
        for (int x = 0; x < w; x++)
        {
            for (int y = 0; y < h; y++)
            {
                if (bytes[y * stride + x * 4 + 3] > alphaThreshold) { colHasContent[x] = true; break; }
            }
        }

        List<Segment> segs = new List<Segment>();
        int x0 = -1;
        int emptyRun = 0;
        for (int x = 0; x < w; x++)
        {
            if (colHasContent[x])
            {
                if (x0 < 0) x0 = x;
                emptyRun = 0;
            }
            else
            {
                emptyRun++;
                if (x0 >= 0 && emptyRun >= minGap)
                {
                    segs.Add(new Segment { Start = x0, End = x - emptyRun });
                    x0 = -1;
                }
            }
        }
        if (x0 >= 0) segs.Add(new Segment { Start = x0, End = w - 1 });
        return segs;
    }

    public static void SaveSegment(Bitmap src, Segment seg, int h, int padding, string outPath)
    {
        int x = Math.Max(0, seg.Start - padding);
        int width = Math.Min(src.Width, seg.End + padding + 1) - x;
        using (Bitmap crop = new Bitmap(width, h, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(crop))
        {
            g.DrawImage(src, new Rectangle(0, 0, width, h), x, 0, width, h, GraphicsUnit.Pixel);
            crop.Save(outPath, ImageFormat.Png);
        }
    }
}
"@

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
$InputFile = (Resolve-Path $InputFile).Path
$basename = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)

$src = New-Object System.Drawing.Bitmap $InputFile
$w = $src.Width
$h = $src.Height

$data = $src.LockBits(
    (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
    [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$src.UnlockBits($data)

$allSegments = [QeSlicer]::FindSegments($bytes, $stride, $w, $h, $AlphaThreshold, $MinGapColumns)
$segments = $allSegments | Where-Object { ($_.End - $_.Start + 1) -ge $MinWidth }
$dropped = $allSegments.Count - $segments.Count
if ($dropped -gt 0) { Write-Host "Dropped $dropped segment(s) narrower than $MinWidth px (edge noise)" }

if ($segments.Count -eq 0) {
    Write-Host "No content found in $InputFile (fully transparent, or not yet alpha-keyed - try dekey_alpha.ps1 first)"
    $src.Dispose()
    return
}

Write-Host "Found $($segments.Count) segment(s) in $basename ($($w)x$($h))"

$i = 1
foreach ($seg in $segments) {
    $outPath = Join-Path $OutDir ("{0}_{1:D2}.png" -f $basename, $i)
    [QeSlicer]::SaveSegment($src, $seg, $h, $Padding, $outPath)
    Write-Host ("  {0}_{1:D2}.png : columns {2}-{3} ({4}px)" -f $basename, $i, $seg.Start, $seg.End, ($seg.End - $seg.Start + 1))
    $i++
}

$src.Dispose()
Write-Host "Wrote $($segments.Count) file(s) to $OutDir"
