<#
.SYNOPSIS
    Removes the baked-in cyan caption text (e.g. "RUN (8 FRAMES)") from QE
    character-sprite frames.

.DESCRIPTION
    A handful of character-sprite frames - typically the first frame of an
    animation row - have a debug caption burned into the pixels near the top
    of the frame, in a bright cyan that doesn't otherwise occur in most of
    the character art (see tools/quantum-effect/README.md).

    Neither a purely geometric signal nor a purely colour signal is safe
    alone here - three different failure modes were found and fixed by
    combining signals:

    - Geometric only (crop whatever's separated from the main blob by a
      transparent gap): dynamic poses legitimately have parts - a raised
      head, a trailing foot - disconnected from the rest of the silhouette
      by transparent rows. Verified: this silently deleted a head from a
      jump frame that has no caption at all.
    - Colour only (crop rows dominated by cyan-ish pixels): some frames'
      actual artwork IS a blue/cyan effect (a dash-trail, a spell crystal)
      that tapers continuously into the character with no gap. Verified:
      this shaved the tip off a dash effect that isn't a caption.
    - Gap + colour, but no size cap: an effect that fills nearly the whole
      canvas and only runs out of pixels near the bottom edge technically
      has "a gap" (the last couple of trimmed-margin rows) and can be almost
      entirely cyan. Verified: this wiped out a whole attack-effect sprite,
      keeping only a fragment, because the "gap" it found was ordinary
      bottom margin, not a caption/subject boundary.

    So a run is only dropped if ALL of: it is the topmost run of opaque
    rows, separated from what follows by >= -MinGapRows fully-transparent
    rows; it is majority caption-coloured (G and B far above R, bright
    enough - see -CyanMinDelta/-CyanMinBrightness); and it spans no more
    than -MaxRunHeightFraction of the frame's total height - real captions
    measured ~14-15% of frame height, nowhere near the 63-95% the false
    positives above reached. A disconnected head passes the gap test but
    fails the colour test; a continuous effect never reaches the gap test;
    a whole-canvas effect fails the size cap. Only rows matching every test
    survive to removal, and only the topmost run is ever a candidate -
    every observed caption sits at the very top of the frame.

    Matched rows have their alpha zeroed (canvas size unchanged) - run
    pack_sprites.ps1 afterward to trim the now-empty rows away along with
    everything else it trims.

    Frames without a caption are untouched - safe to run over a whole
    directory rather than hand-picking suspect files.

.EXAMPLE
    .\strip_caption.ps1 -InputDir ..\..\VisualAssets\...\characters\sprites\player -OutDir out\player_decaptioned
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$InputDir,
    [Parameter(Mandatory = $true)][string]$OutDir,

    [int]$AlphaThreshold = 8,

    # Minimum run of consecutive empty rows for the top run to count as
    # actually separated from the rest of the content.
    [int]$MinGapRows = 2,

    # A pixel counts as caption ink if G-R and B-R both exceed this and it's
    # bright enough (see -CyanMinBrightness). Tuned against the sampled
    # "RUN (8 FRAMES)" caption text (e.g. RGB 39,160,198).
    [int]$CyanMinDelta = 30,

    # Minimum average of G and B for a pixel to count as caption ink -
    # excludes near-black antialiasing fringe that happens to be blue-shifted.
    [int]$CyanMinBrightness = 55,

    # Fraction of the candidate run's opaque pixels that must be caption-ink
    # for the whole run to be dropped. A real caption's tight bounding box
    # still has letterform whitespace - measured ~49% ink on the reference
    # "RUN (8 FRAMES)" frame, not the near-100% a solid glyph fill implies -
    # so this sits below that, not near it. A disconnected body part (tested:
    # a jump frame's head) scores near zero, so there's a wide safety margin
    # on the other side.
    [double]$RunMatchFraction = 0.4,

    # Candidate run must span no more than this fraction of the frame's
    # total height - rules out a "gap" that's really just ordinary bottom
    # margin below art that fills almost the whole canvas.
    [double]$MaxRunHeightFraction = 0.3,

    [string]$Filter = "*.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class QeCaptionStripper
{
    // Topmost run of opaque rows, ending at the first gap of >= minGap
    // empty rows. Returns null if row 0..N is already empty (nothing at the
    // very top) or the whole image is one run (no gap found at all).
    public static int[] FindTopRun(byte[] bytes, int stride, int w, int h, int alphaThreshold, int minGap)
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

        int top = -1;
        for (int y = 0; y < h; y++)
        {
            if (rowArea[y] > 0) { top = y; break; }
            if (y >= 2) return null; // top edge itself is empty - nothing to strip
        }
        if (top < 0) return null;

        int emptyRun = 0;
        for (int y = top; y < h; y++)
        {
            if (rowArea[y] > 0) { emptyRun = 0; continue; }
            emptyRun++;
            if (emptyRun >= minGap) return new int[] { top, y - emptyRun };
        }
        return null; // no gap found - single continuous run, not a candidate
    }

    public static double InkFraction(byte[] bytes, int stride, int w, int top, int bottom, int alphaThreshold, int minDelta, int minBrightness)
    {
        int opaque = 0, ink = 0;
        for (int y = top; y <= bottom; y++)
        {
            int row = y * stride;
            for (int x = 0; x < w; x++)
            {
                int a = bytes[row + x * 4 + 3];
                if (a <= alphaThreshold) continue;
                opaque++;
                int b = bytes[row + x * 4 + 0];
                int g = bytes[row + x * 4 + 1];
                int r = bytes[row + x * 4 + 2];
                if ((g - r) >= minDelta && (b - r) >= minDelta && ((g + b) / 2) >= minBrightness)
                    ink++;
            }
        }
        return opaque == 0 ? 0.0 : (double)ink / opaque;
    }

    public static string ProcessOne(string inPath, string outPath,
        int alphaThreshold, int minGap, int minDelta, int minBrightness, double runMatchFraction, double maxRunHeightFraction)
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

                string result = "unchanged";
                int[] run = FindTopRun(bytes, stride, w, h, alphaThreshold, minGap);
                if (run != null && (run[1] - run[0] + 1) <= h * maxRunHeightFraction)
                {
                    double frac = InkFraction(bytes, stride, w, run[0], run[1], alphaThreshold, minDelta, minBrightness);
                    if (frac >= runMatchFraction)
                    {
                        for (int y = run[0]; y <= run[1]; y++)
                        {
                            int row = y * stride;
                            for (int x = 0; x < w; x++) bytes[row + x * 4 + 3] = 0;
                        }
                        Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
                        result = string.Format("caption removed (rows {0}-{1}, {2:P0} ink)", run[0], run[1], frac);
                    }
                }

                bmp.UnlockBits(data);
                bmp.Save(outPath, ImageFormat.Png);
                return result;
            }
        }
    }
}
"@

$InputDir = (Resolve-Path $InputDir).Path
$files = Get-ChildItem -Path $InputDir -Recurse -Filter $Filter | Sort-Object FullName
if ($files.Count -eq 0) { throw "No files matching '$Filter' under $InputDir" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }

Write-Host "Scanning $($files.Count) file(s) for baked-in captions"

$changed = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($InputDir.Length).TrimStart('\')
    $outPath = Join-Path $OutDir $rel
    $outParent = Split-Path -Parent $outPath
    if ($outParent -and -not (Test-Path $outParent)) { New-Item -ItemType Directory -Force $outParent | Out-Null }

    try {
        $result = [QeCaptionStripper]::ProcessOne($f.FullName, $outPath, $AlphaThreshold, $MinGapRows, $CyanMinDelta, $CyanMinBrightness, $RunMatchFraction, $MaxRunHeightFraction)
    } catch {
        Write-Host "  $rel : ERROR $($_.Exception.InnerException.Message)"
        continue
    }
    if ($result -ne "unchanged") {
        Write-Host "  $rel : $result"
        $changed++
    }
}

Write-Host "Removed captions from $changed of $($files.Count) file(s). Wrote to $OutDir"
