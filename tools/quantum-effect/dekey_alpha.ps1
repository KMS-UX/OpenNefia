<#
.SYNOPSIS
    Restores real alpha transparency to QE art that carries a flat baked
    background instead of an alpha channel.

.DESCRIPTION
    Some QE source images (e.g. assets/icons/coin-gold.png,
    assets/bestiary/creatures/arctic.png) are fully opaque - every pixel has
    alpha=255, including what is visually "background". pack_sprites.ps1's
    trim step relies on real alpha to find content bounds, so these images
    pack as solid rectangles until this is fixed.

    This keys out the background via flood fill from the image border,
    walking outward-in: each step compares a candidate pixel only to the
    neighbour that reached it (not to a single fixed reference colour), so
    the fill follows smooth vignette/gradient backgrounds - common in this
    art - while still stopping at the sharper edges that bound real artwork.
    Pixels enclosed by the artwork (outlines, pupils, shadow details) survive
    even when they're as dark as the background, because they aren't
    connected to the edge.

    Images that already vary in alpha are skipped by default (nothing to
    restore) unless -Force is passed.

.EXAMPLE
    .\dekey_alpha.ps1 -InputDir ..\..\VisualAssets\...\icons -OutDir out\icons_keyed

.EXAMPLE
    .\dekey_alpha.ps1 -InputDir ..\..\VisualAssets\...\bestiary\creatures -OutDir out\creatures_keyed -Tolerance 40
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$InputDir,
    [Parameter(Mandatory = $true)][string]$OutDir,

    # Max per-channel-weighted colour distance from the sampled background to
    # still count as background. Raise if antialiased edge halos survive as
    # opaque fringes; lower if the flood fill eats into the subject.
    [int]$Tolerance = 32,

    # Re-key images that already contain transparent pixels.
    [switch]$Force,

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

public static class QeDekeyer
{
    // Returns true if the image already has any pixel with alpha below 250 -
    // i.e. it already carries real transparency and doesn't need keying.
    public static bool HasAlphaVariance(byte[] bytes, int stride, int w, int h)
    {
        for (int y = 0; y < h; y++)
        {
            int row = y * stride;
            for (int x = 0; x < w; x++)
            {
                if (bytes[row + x * 4 + 3] < 250) return true;
            }
        }
        return false;
    }

    public static int[] SampleCornerBackground(byte[] bytes, int stride, int w, int h)
    {
        // Average the four corner pixels - background reliably touches at
        // least one, usually all four, of them. Used only for reporting;
        // KeyOut itself walks local gradients, not this fixed colour.
        long b = 0, g = 0, r = 0;
        int[][] pts = new int[][] { new int[]{0,0}, new int[]{w-1,0}, new int[]{0,h-1}, new int[]{w-1,h-1} };
        foreach (var p in pts)
        {
            int idx = p[1] * stride + p[0] * 4;
            b += bytes[idx + 0];
            g += bytes[idx + 1];
            r += bytes[idx + 2];
        }
        return new int[] { (int)(r / 4), (int)(g / 4), (int)(b / 4) };
    }

    // Flood fill from the image border inward. Many QE backgrounds are a
    // vignette/gradient, not a flat colour, so each step compares a
    // candidate pixel to the neighbour that reached it - not to a fixed
    // reference - letting the fill walk smooth gradients while still
    // stopping at the sharper edges that bound real artwork.
    public static int KeyOut(byte[] bytes, int stride, int w, int h, int tolerance)
    {
        bool[] visited = new bool[w * h];
        Queue<int> q = new Queue<int>();

        Action<int, int> seed = (x, y) =>
        {
            int p = y * w + x;
            if (!visited[p]) { visited[p] = true; q.Enqueue(p); }
        };

        for (int x = 0; x < w; x++) { seed(x, 0); seed(x, h - 1); }
        for (int y = 0; y < h; y++) { seed(0, y); seed(w - 1, y); }

        int cleared = 0;
        int[] dx = { 1, -1, 0, 0 };
        int[] dy = { 0, 0, 1, -1 };

        while (q.Count > 0)
        {
            int p = q.Dequeue();
            int x = p % w, y = p / w;
            int idx = y * stride + x * 4;
            int cb = bytes[idx + 0], cg = bytes[idx + 1], cr = bytes[idx + 2];
            bytes[idx + 3] = 0;
            cleared++;

            for (int d = 0; d < 4; d++)
            {
                int nx = x + dx[d], ny = y + dy[d];
                if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
                int np = ny * w + nx;
                if (visited[np]) continue;

                int nidx = ny * stride + nx * 4;
                int db = bytes[nidx + 0] - cb;
                int dg = bytes[nidx + 1] - cg;
                int dr = bytes[nidx + 2] - cr;
                double dist = Math.Sqrt(dr * dr + dg * dg + db * db);
                if (dist <= tolerance)
                {
                    visited[np] = true;
                    q.Enqueue(np);
                }
            }
        }
        return cleared;
    }

    public static string ProcessOne(string inPath, string outPath, int tolerance, bool force)
    {
        using (Bitmap src = new Bitmap(inPath))
        {
            int w = src.Width, h = src.Height;
            using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(bmp))
                    g.DrawImage(src, 0, 0, w, h);

                BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h),
                    ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int stride = data.Stride;
                byte[] bytes = new byte[stride * h];
                Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);

                string result;
                if (!force && HasAlphaVariance(bytes, stride, w, h))
                {
                    result = "SKIP (already has alpha)";
                }
                else
                {
                    int[] bg = SampleCornerBackground(bytes, stride, w, h);
                    int cleared = KeyOut(bytes, stride, w, h, tolerance);
                    Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
                    result = string.Format("bg~({0},{1},{2}) cleared={3}/{4}", bg[0], bg[1], bg[2], cleared, w * h);
                }

                bmp.UnlockBits(data);
                if (!result.StartsWith("SKIP"))
                    bmp.Save(outPath, ImageFormat.Png);
                else
                    src.Save(outPath, ImageFormat.Png);

                return result;
            }
        }
    }
}
"@

$InputDir = (Resolve-Path $InputDir).Path
$files = Get-ChildItem -Path $InputDir -Recurse -Filter $Filter |
         Sort-Object FullName

if ($files.Count -eq 0) { throw "No files matching '$Filter' under $InputDir" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }

Write-Host "Keying $($files.Count) file(s), tolerance=$Tolerance$(if ($Force) { ' (force)' })"

$skipped = 0
$keyed = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($InputDir.Length).TrimStart('\')
    $outPath = Join-Path $OutDir $rel
    $outParent = Split-Path -Parent $outPath
    if ($outParent -and -not (Test-Path $outParent)) { New-Item -ItemType Directory -Force $outParent | Out-Null }

    try {
        $result = [QeDekeyer]::ProcessOne($f.FullName, $outPath, $Tolerance, $Force.IsPresent)
    } catch {
        Write-Host "  $rel : ERROR $($_.Exception.InnerException.Message)"
        continue
    }
    if ($result.StartsWith("SKIP")) { $skipped++ } else { $keyed++ }
    Write-Host "  $rel : $result"
    if ($result -match "cleared=(\d+)/(\d+)") {
        $ratio = [double]$Matches[1] / [double]$Matches[2]
        if ($ratio -gt 0.9) {
            $pct = "{0:P0}" -f $ratio
            Write-Host "    WARNING: $pct cleared - fill likely ate into low-contrast subject. Try a lower -Tolerance or review manually." -ForegroundColor Yellow
        }
    }
}

Write-Host "Keyed $keyed, skipped $skipped. Wrote to $OutDir"
