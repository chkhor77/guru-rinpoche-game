<#
.SYNOPSIS
    Extracts and processes game sprites, isometric models, and UI portraits from the
    Samye Monastery, Stupa, Padmasambhava, and Monastery Builder Monk reference sheets.
.DESCRIPTION
    Part of the `samye-visual-models` workspace skill.
    Crops turnaround views, isometric game models, top-down layouts, and character portraits,
    clears sheet typography/callouts, protects interior white architectural/clothing zones,
    and applies flood-fill + largest-component filtering + soft edge feathering to produce
    transparent PNG sprites in `assets/sprites/`.
#>

param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$ResourcesDir = Join-Path $ProjectRoot ".agents\skills\samye-visual-models\resources"
$SpritesDir   = Join-Path $ProjectRoot "assets\sprites"
$SheetsDir    = Join-Path $ProjectRoot "assets\sheets"

New-Item -ItemType Directory -Force -Path $SpritesDir, $SheetsDir | Out-Null

# Ensure full sheets exist in assets/sheets for the in-game Lore Modal
Copy-Item (Join-Path $ResourcesDir "*.jpg") $SheetsDir -Force

$CsCode = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;

public static class SpriteCleaner {
    public static Bitmap CropAndKeyBackground(
        Bitmap src,
        Rectangle rect,
        int tolerance,
        Rectangle[] clearZones,
        Rectangle[] keepZones = null
    ) {
        rect.Intersect(new Rectangle(0, 0, src.Width, src.Height));
        Bitmap dst = new Bitmap(rect.Width, rect.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.DrawImage(src, new Rectangle(0, 0, rect.Width, rect.Height), rect, GraphicsUnit.Pixel);
        }

        int w = dst.Width;
        int h = dst.Height;

        if (tolerance > 0) {
            bool[,] visited = new bool[w, h];
            Queue<Point> q = new Queue<Point>();

            if (keepZones != null) {
                foreach (Rectangle kz in keepZones) {
                    int x0 = Math.Max(0, kz.X);
                    int y0 = Math.Max(0, kz.Y);
                    int x1 = Math.Min(w, kz.Right);
                    int y1 = Math.Min(h, kz.Bottom);
                    for (int y = y0; y < y1; y++) {
                        for (int x = x0; x < x1; x++) {
                            visited[x, y] = true;
                        }
                    }
                }
            }

            Color bgTopLeft  = dst.GetPixel(Math.Min(w - 1, 4), Math.Min(h - 1, 4));
            Color bgTopRight = dst.GetPixel(Math.Max(0, w - 5), Math.Min(h - 1, 4));
            Color bgBotLeft  = dst.GetPixel(Math.Min(w - 1, 4), Math.Max(0, h - 5));
            Color bgBotRight = dst.GetPixel(Math.Max(0, w - 5), Math.Max(0, h - 5));

            for (int x = 0; x < w; x++) {
                if (!visited[x, 0])     { q.Enqueue(new Point(x, 0));     visited[x, 0] = true; }
                if (!visited[x, h - 1]) { q.Enqueue(new Point(x, h - 1)); visited[x, h - 1] = true; }
            }
            for (int y = 0; y < h; y++) {
                if (!visited[0, y])     { q.Enqueue(new Point(0, y));     visited[0, y] = true; }
                if (!visited[w - 1, y]) { q.Enqueue(new Point(w - 1, y)); visited[w - 1, y] = true; }
            }

            int[] dx = { -1, 1, 0, 0, -1, 1, -1, 1 };
            int[] dy = { 0, 0, -1, 1, -1, -1, 1, 1 };

            while (q.Count > 0) {
                Point p = q.Dequeue();
                Color c = dst.GetPixel(p.X, p.Y);

                if (IsBackgroundLike(c, bgTopLeft, bgTopRight, bgBotLeft, bgBotRight, tolerance)) {
                    dst.SetPixel(p.X, p.Y, Color.FromArgb(0, c.R, c.G, c.B));
                    for (int i = 0; i < 8; i++) {
                        int nx = p.X + dx[i];
                        int ny = p.Y + dy[i];
                        if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                            visited[nx, ny] = true;
                            q.Enqueue(new Point(nx, ny));
                        }
                    }
                }
            }
        }

        if (clearZones != null) {
            foreach (Rectangle cz in clearZones) {
                int x0 = Math.Max(0, cz.X);
                int y0 = Math.Max(0, cz.Y);
                int x1 = Math.Min(w, cz.Right);
                int y1 = Math.Min(h, cz.Bottom);
                for (int y = y0; y < y1; y++) {
                    for (int x = x0; x < x1; x++) {
                        dst.SetPixel(x, y, Color.FromArgb(0, 255, 255, 255));
                    }
                }
            }
        }

        if (tolerance <= 0) {
            return dst;
        }

        return FeatherBorder(dst, w, h);
    }

    public static Bitmap ExtractOutlinedMonk(Bitmap src, Rectangle rect, Rectangle[] keepZones) {
        rect.Intersect(new Rectangle(0, 0, src.Width, src.Height));
        Bitmap dst = new Bitmap(rect.Width, rect.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.DrawImage(src, new Rectangle(0, 0, rect.Width, rect.Height), rect, GraphicsUnit.Pixel);
        }

        int w = dst.Width;
        int h = dst.Height;
        bool[,] visited = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        if (keepZones != null) {
            foreach (Rectangle kz in keepZones) {
                for (int y = Math.Max(0, kz.Y); y < Math.Min(h, kz.Bottom); y++) {
                    for (int x = Math.Max(0, kz.X); x < Math.Min(w, kz.Right); x++) {
                        visited[x, y] = true;
                    }
                }
            }
        }

        for (int x = 0; x < w; x++) {
            if (!visited[x, 0])     { q.Enqueue(new Point(x, 0));     visited[x, 0] = true; }
            if (!visited[x, h - 1]) { q.Enqueue(new Point(x, h - 1)); visited[x, h - 1] = true; }
        }
        for (int y = 0; y < h; y++) {
            if (!visited[0, y])     { q.Enqueue(new Point(0, y));     visited[0, y] = true; }
            if (!visited[w - 1, y]) { q.Enqueue(new Point(w - 1, y)); visited[w - 1, y] = true; }
        }

        int midX = w / 2;
        if (h > 265 && !visited[midX, 262]) {
            q.Enqueue(new Point(midX, 262));
            visited[midX, 262] = true;
        }

        int[] dx = { -1, 1, 0, 0 };
        int[] dy = { 0, 0, -1, 1 };

        while (q.Count > 0) {
            Point p = q.Dequeue();
            Color c = dst.GetPixel(p.X, p.Y);

            if (IsMonkBackground(c, p.Y)) {
                dst.SetPixel(p.X, p.Y, Color.FromArgb(0, c.R, c.G, c.B));
                for (int i = 0; i < 4; i++) {
                    int nx = p.X + dx[i];
                    int ny = p.Y + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                        visited[nx, ny] = true;
                        q.Enqueue(new Point(nx, ny));
                    }
                }
            }
        }

        KeepLargestComponent(dst, w, h);
        return FeatherBorder(dst, w, h);
    }

    public static Bitmap ExtractMistSpirit(
        Bitmap src,
        Rectangle rect,
        bool isCorrupted,
        bool flipX,
        Rectangle[] clearZones,
        Rectangle[] keepZones
    ) {
        rect.Intersect(new Rectangle(0, 0, src.Width, src.Height));
        Bitmap dst = new Bitmap(rect.Width, rect.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.DrawImage(src, new Rectangle(0, 0, rect.Width, rect.Height), rect, GraphicsUnit.Pixel);
        }

        int w = dst.Width;
        int h = dst.Height;

        if (clearZones != null) {
            foreach (Rectangle cz in clearZones) {
                for (int y = Math.Max(0, cz.Y); y < Math.Min(h, cz.Bottom); y++) {
                    for (int x = Math.Max(0, cz.X); x < Math.Min(w, cz.Right); x++) {
                        dst.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                    }
                }
            }
        }

        bool[,] visited = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        if (keepZones != null) {
            foreach (Rectangle kz in keepZones) {
                for (int y = Math.Max(0, kz.Y); y < Math.Min(h, kz.Bottom); y++) {
                    for (int x = Math.Max(0, kz.X); x < Math.Min(w, kz.Right); x++) {
                        visited[x, y] = true;
                    }
                }
            }
        }

        for (int x = 0; x < w; x++) {
            if (!visited[x, 0])     { q.Enqueue(new Point(x, 0));     visited[x, 0] = true; }
            if (!visited[x, h - 1]) { q.Enqueue(new Point(x, h - 1)); visited[x, h - 1] = true; }
        }
        for (int y = 0; y < h; y++) {
            if (!visited[0, y])     { q.Enqueue(new Point(0, y));     visited[0, y] = true; }
            if (!visited[w - 1, y]) { q.Enqueue(new Point(w - 1, y)); visited[w - 1, y] = true; }
        }

        int[] dx = { -1, 1, 0, 0, -1, 1, -1, 1 };
        int[] dy = { 0, 0, -1, 1, -1, -1, 1, 1 };

        while (q.Count > 0) {
            Point p = q.Dequeue();
            Color c = dst.GetPixel(p.X, p.Y);
            if (c.A == 0 || IsSpiritBackground(c, isCorrupted)) {
                dst.SetPixel(p.X, p.Y, Color.FromArgb(0, c.R, c.G, c.B));
                for (int i = 0; i < 8; i++) {
                    int nx = p.X + dx[i];
                    int ny = p.Y + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                        visited[nx, ny] = true;
                        q.Enqueue(new Point(nx, ny));
                    }
                }
            }
        }

        KeepLargestComponent(dst, w, h);

        Bitmap soft = (Bitmap)dst.Clone();
        for (int y = 1; y < h - 1; y++) {
            for (int x = 1; x < w - 1; x++) {
                Color c = dst.GetPixel(x, y);
                if (c.A > 0) {
                    int trans = 0;
                    for (int i = 0; i < 8; i++) {
                        if (dst.GetPixel(x + dx[i], y + dy[i]).A == 0) trans++;
                    }
                    if (trans >= 6) soft.SetPixel(x, y, Color.FromArgb(0, c.R, c.G, c.B));
                    else if (trans >= 4) soft.SetPixel(x, y, Color.FromArgb(110, c.R, c.G, c.B));
                    else if (trans >= 2) soft.SetPixel(x, y, Color.FromArgb(175, c.R, c.G, c.B));
                    else if (trans == 1) soft.SetPixel(x, y, Color.FromArgb(225, c.R, c.G, c.B));
                }
            }
        }
        dst.Dispose();

        if (flipX) {
            soft.RotateFlip(RotateFlipType.RotateNoneFlipX);
        }
        return soft;
    }

    public static Bitmap ExtractCardSpirit(
        Bitmap src,
        Rectangle rect,
        int bgTol,
        bool clearEnclosedBg,
        Rectangle[] keepZones = null
    ) {
        rect.Intersect(new Rectangle(0, 0, src.Width, src.Height));
        Bitmap dst = new Bitmap(rect.Width, rect.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.DrawImage(src, new Rectangle(0, 0, rect.Width, rect.Height), rect, GraphicsUnit.Pixel);
        }

        int w = dst.Width;
        int h = dst.Height;

        Color b1 = dst.GetPixel(Math.Min(w - 1, 6), Math.Min(h - 1, 6));
        Color b2 = dst.GetPixel(Math.Max(0, w - 7), Math.Min(h - 1, 6));
        Color b3 = dst.GetPixel(Math.Min(w - 1, 6), Math.Max(0, h - 7));
        Color b4 = dst.GetPixel(Math.Max(0, w - 7), Math.Max(0, h - 7));

        bool[,] visited = new bool[w, h];
        if (keepZones != null) {
            foreach (Rectangle kz in keepZones) {
                for (int y = Math.Max(0, kz.Y); y < Math.Min(h, kz.Bottom); y++) {
                    for (int x = Math.Max(0, kz.X); x < Math.Min(w, kz.Right); x++) {
                        visited[x, y] = true;
                    }
                }
            }
        }
        Queue<Point> q = new Queue<Point>();

        for (int x = 0; x < w; x++) {
            q.Enqueue(new Point(x, 0));     visited[x, 0] = true;
            q.Enqueue(new Point(x, h - 1)); visited[x, h - 1] = true;
        }
        for (int y = 0; y < h; y++) {
            if (!visited[0, y])     { q.Enqueue(new Point(0, y));     visited[0, y] = true; }
            if (!visited[w - 1, y]) { q.Enqueue(new Point(w - 1, y)); visited[w - 1, y] = true; }
        }

        int[] dx = { -1, 1, 0, 0, -1, 1, -1, 1 };
        int[] dy = { 0, 0, -1, 1, -1, -1, 1, 1 };

        while (q.Count > 0) {
            Point p = q.Dequeue();
            Color c = dst.GetPixel(p.X, p.Y);
            if (IsCardBg(c, b1, b2, b3, b4, bgTol)) {
                dst.SetPixel(p.X, p.Y, Color.FromArgb(0, c.R, c.G, c.B));
                for (int i = 0; i < 8; i++) {
                    int nx = p.X + dx[i];
                    int ny = p.Y + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                        visited[nx, ny] = true;
                        q.Enqueue(new Point(nx, ny));
                    }
                }
            }
        }

        if (clearEnclosedBg) {
            for (int y = 2; y < h - 2; y++) {
                for (int x = 2; x < w - 2; x++) {
                    if (!visited[x, y]) {
                        Color c = dst.GetPixel(x, y);
                        if (c.A > 0 && IsCardBg(c, b1, b2, b3, b4, bgTol - 8)) {
                            dst.SetPixel(x, y, Color.FromArgb(0, c.R, c.G, c.B));
                        }
                    }
                }
            }
        }

        KeepLargestComponent(dst, w, h);
        return FeatherBorder(dst, w, h);
    }

    private static bool IsCardBg(Color c, Color b1, Color b2, Color b3, Color b4, int tol) {
        int d = Math.Min(
            Math.Min(ColorDist(c, b1), ColorDist(c, b2)),
            Math.Min(ColorDist(c, b3), ColorDist(c, b4))
        );
        return d <= tol;
    }

    private static bool IsSpiritBackground(Color c, bool isCorrupted) {
        int maxC = Math.Max(c.R, Math.Max(c.G, c.B));
        int minC = Math.Min(c.R, Math.Min(c.G, c.B));
        int sat = maxC - minC;
        int blueBias = c.B - c.R;

        if (isCorrupted) {
            if (maxC <= 126 && sat <= 20) return true;
            if (maxC <= 102 && sat <= 26) return true;
            return false;
        } else {
            if (maxC >= 85 && maxC <= 160 && sat <= 17 && blueBias <= 15) return true;
            if (maxC >= 95 && maxC <= 148 && sat <= 21 && blueBias <= 17) return true;
            return false;
        }
    }

    private static Bitmap FeatherBorder(Bitmap dst, int w, int h) {
        int[] ndx = { -1, 1, 0, 0 };
        int[] ndy = { 0, 0, -1, 1 };
        Bitmap softened = (Bitmap)dst.Clone();
        for (int y = 1; y < h - 1; y++) {
            for (int x = 1; x < w - 1; x++) {
                Color c = dst.GetPixel(x, y);
                if (c.A > 0) {
                    int transNeighbors = 0;
                    for (int i = 0; i < 4; i++) {
                        if (dst.GetPixel(x + ndx[i], y + ndy[i]).A == 0) transNeighbors++;
                    }
                    if (transNeighbors == 4) {
                        softened.SetPixel(x, y, Color.FromArgb(0, c.R, c.G, c.B));
                    } else if (transNeighbors >= 2) {
                        softened.SetPixel(x, y, Color.FromArgb(150, c.R, c.G, c.B));
                    } else if (transNeighbors == 1) {
                        softened.SetPixel(x, y, Color.FromArgb(220, c.R, c.G, c.B));
                    }
                }
            }
        }
        dst.Dispose();
        return softened;
    }

    private static bool IsMonkBackground(Color c, int y) {
        int sat = c.R - c.B;
        if (y < 70) {
            if (c.G >= 188 && c.B >= 165) return true;
            if (c.G >= 165 && c.B >= 145 && sat <= 34) return true;
            return false;
        }

        int sum = c.R + c.G + c.B;
        if (sum <= 340 && c.G <= 118 && c.B <= 98) return false;
        if (sat >= 78 && c.G < 165) return false;

        return true;
    }

    private static void KeepLargestComponent(Bitmap bmp, int w, int h) {
        bool[,] seen = new bool[w, h];
        int[] dx = { -1, 1, 0, 0, -1, 1, -1, 1 };
        int[] dy = { 0, 0, -1, 1, -1, -1, 1, 1 };

        List<List<Point>> allComps = new List<List<Point>>();
        int maxIdx = -1;
        int maxCount = -1;

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                if (!seen[x, y] && bmp.GetPixel(x, y).A > 0) {
                    List<Point> comp = new List<Point>();
                    Queue<Point> cq = new Queue<Point>();
                    cq.Enqueue(new Point(x, y));
                    seen[x, y] = true;
                    while (cq.Count > 0) {
                        Point p = cq.Dequeue();
                        comp.Add(p);
                        for (int i = 0; i < 8; i++) {
                            int nx = p.X + dx[i];
                            int ny = p.Y + dy[i];
                            if (nx >= 0 && nx < w && ny >= 0 && ny < h && !seen[nx, ny] && bmp.GetPixel(nx, ny).A > 0) {
                                seen[nx, ny] = true;
                                cq.Enqueue(new Point(nx, ny));
                            }
                        }
                    }
                    if (comp.Count > maxCount) {
                        maxCount = comp.Count;
                        maxIdx = allComps.Count;
                    }
                    allComps.Add(comp);
                }
            }
        }

        for (int i = 0; i < allComps.Count; i++) {
            if (i != maxIdx) {
                foreach (Point pt in allComps[i]) {
                    Color c = bmp.GetPixel(pt.X, pt.Y);
                    bmp.SetPixel(pt.X, pt.Y, Color.FromArgb(0, c.R, c.G, c.B));
                }
            }
        }
    }

    private static bool IsBackgroundLike(Color c, Color b1, Color b2, Color b3, Color b4, int tol) {
        int d1 = ColorDist(c, b1);
        int d2 = ColorDist(c, b2);
        int d3 = ColorDist(c, b3);
        int d4 = ColorDist(c, b4);
        int minD = Math.Min(Math.Min(d1, d2), Math.Min(d3, d4));
        if (minD <= tol) return true;

        int maxC = Math.Max(c.R, Math.Max(c.G, c.B));
        int minC = Math.Min(c.R, Math.Min(c.G, c.B));
        int sat = maxC - minC;

        if (c.B >= c.R && c.B >= 205 && c.R >= 188 && sat <= 36) return true;

        return false;
    }

    private static int ColorDist(Color a, Color b) {
        int dr = a.R - b.R;
        int dg = a.G - b.G;
        int db = a.B - b.B;
        return (int)Math.Sqrt(dr * dr + dg * dg + db * db);
    }
}
"@

Add-Type -TypeDefinition $CsCode -ReferencedAssemblies System.Drawing

function Save-Crop {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$X, [int]$Y, [int]$W, [int]$H,
        [string]$OutFile,
        [int]$Tolerance = 0,
        [System.Drawing.Rectangle[]]$ClearZones = $null,
        [System.Drawing.Rectangle[]]$KeepZones = $null
    )
    $rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
    $bmp = [SpriteCleaner]::CropAndKeyBackground($Source, $rect, $Tolerance, $ClearZones, $KeepZones)
    $outPath = Join-Path $SpritesDir $OutFile
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved: $OutFile ($($W)x$($H))"
}

function Save-MonkCrop {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$X, [int]$Y, [int]$W, [int]$H,
        [string]$OutFile,
        [System.Drawing.Rectangle[]]$KeepZones = $null
    )
    $rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
    $bmp = [SpriteCleaner]::ExtractOutlinedMonk($Source, $rect, $KeepZones)
    $outPath = Join-Path $SpritesDir $OutFile
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved: $OutFile ($($W)x$($H))"
}

function Save-SpiritCrop {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$X, [int]$Y, [int]$W, [int]$H,
        [string]$OutFile,
        [bool]$IsCorrupted,
        [bool]$FlipX = $false,
        [System.Drawing.Rectangle[]]$ClearZones = $null,
        [System.Drawing.Rectangle[]]$KeepZones = $null
    )
    $rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
    $bmp = [SpriteCleaner]::ExtractMistSpirit($Source, $rect, $IsCorrupted, $FlipX, $ClearZones, $KeepZones)
    $outPath = Join-Path $SpritesDir $OutFile
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved: $OutFile ($($W)x$($H))"
}

function Save-CardSpiritCrop {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$X, [int]$Y, [int]$W, [int]$H,
        [string]$OutFile,
        [int]$BgTol = 24,
        [bool]$ClearEnclosed = $true,
        [System.Drawing.Rectangle[]]$KeepZones = $null
    )
    $rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
    $bmp = [SpriteCleaner]::ExtractCardSpirit($Source, $rect, $BgTol, $ClearEnclosed, $KeepZones)
    $outPath = Join-Path $SpritesDir $OutFile
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved: $OutFile ($($W)x$($H))"
}

# 1. Padmasambhava (Guru Rinpoche)
$guruBmp = [System.Drawing.Bitmap]::FromFile((Join-Path $ResourcesDir "padmasambhava_sheet.jpg"))
Save-Crop $guruBmp 11  111 177 264 "guru_portrait.png" 0
Save-Crop $guruBmp 198 6   220 470 "guru_front.png"    28 @(
    (New-Object System.Drawing.Rectangle(0, 0, 24, 55))
)
Save-Crop $guruBmp 430 6   156 470 "guru_left.png"     28
Save-Crop $guruBmp 594 6   212 470 "guru_back.png"     28
Save-Crop $guruBmp 812 6   168 470 "guru_right.png"    28 @(
    (New-Object System.Drawing.Rectangle(114, 0, 54, 72)),
    (New-Object System.Drawing.Rectangle(0, 45, 8, 60))
) @(
    (New-Object System.Drawing.Rectangle(58, 175, 72, 115))
)
$guruBmp.Dispose()

# 2. Stupa
$stupaBmp = [System.Drawing.Bitmap]::FromFile((Join-Path $ResourcesDir "stupa_sheet.jpg"))
Save-Crop $stupaBmp 652 414 236 194 "stupa_isometric.png" 18 @(
    (New-Object System.Drawing.Rectangle(0, 0, 98, 52)),
    (New-Object System.Drawing.Rectangle(172, 174, 64, 20))
) @(
    (New-Object System.Drawing.Rectangle(96, 56, 64, 92))
)
Save-Crop $stupaBmp 512 32  164 166 "stupa_front.png"      0
Save-Crop $stupaBmp 822 64  168 176 "stupa_top_layout.png" 0
Save-Crop $stupaBmp 0   0   508 442 "stupa_hero.png"       0
$stupaBmp.Dispose()

# 3. Samye Monastery
$samyeBmp = [System.Drawing.Bitmap]::FromFile((Join-Path $ResourcesDir "samye_monastery_sheet.jpg"))
Save-Crop $samyeBmp 632 440 232 154 "samye_isometric.png"  20 @(
    (New-Object System.Drawing.Rectangle(0, 0, 14, 154))
) @(
    (New-Object System.Drawing.Rectangle(34, 48, 174, 90))
)
Save-Crop $samyeBmp 552 14  312 120 "samye_front.png"      18 $null @(
    (New-Object System.Drawing.Rectangle(18, 58, 276, 56))
)
Save-Crop $samyeBmp 552 302 184 104 "samye_side_left.png"  18 $null @(
    (New-Object System.Drawing.Rectangle(16, 48, 152, 50))
)
Save-Crop $samyeBmp 740 302 234 104 "samye_side_right.png" 18 $null @(
    (New-Object System.Drawing.Rectangle(16, 48, 202, 50))
)
Save-Crop $samyeBmp 876 42  114 156 "samye_top_layout.png" 0
Save-Crop $samyeBmp 0   0   546 446 "samye_hero.png"       0
$samyeBmp.Dispose()

# 4. Monastery Builder Monk (SamyeWorker)
$monkPath = Join-Path $ResourcesDir "monk_sheet.jpg"
if (Test-Path $monkPath) {
    $monkBmp = [System.Drawing.Bitmap]::FromFile($monkPath)
    Save-Crop     $monkBmp 24  112 218 228 "monk_portrait.png" 0
    Save-MonkCrop $monkBmp 262 112 116 294 "monk_front.png" @(
        (New-Object System.Drawing.Rectangle(76, 152, 18, 24))
    )
    Save-MonkCrop $monkBmp 400 112 124 294 "monk_back.png" @(
        (New-Object System.Drawing.Rectangle(18, 154, 16, 22))
    )
    Save-MonkCrop $monkBmp 576 112 92  294 "monk_right.png" $null
    Save-MonkCrop $monkBmp 696 112 92  294 "monk_left.png"  $null
    $monkBmp.Dispose()
}

# 5. Mountain Mist Demon — Before Cleansing (CorruptedSpirit: Hostile Form)
$corSpiritPath = Join-Path $ResourcesDir "mist_demon_corrupted_sheet.jpg"
if (Test-Path $corSpiritPath) {
    $corBmp = [System.Drawing.Bitmap]::FromFile($corSpiritPath)
    Save-Crop       $corBmp 8   112 244 280 "spirit_corrupted_portrait.png" 0
    Save-SpiritCrop $corBmp 266 150 160 236 "spirit_corrupted_front.png" $true $false @(
        (New-Object System.Drawing.Rectangle(0, 0, 22, 118)),
        (New-Object System.Drawing.Rectangle(0, 182, 34, 54))
    ) @(
        (New-Object System.Drawing.Rectangle(48, 48, 70, 110))
    )
    Save-SpiritCrop $corBmp 426 150 156 236 "spirit_corrupted_back.png"  $true $false $null @(
        (New-Object System.Drawing.Rectangle(42, 48, 72, 110))
    )
    Save-SpiritCrop $corBmp 584 150 110 236 "spirit_corrupted_right.png" $true $false $null @(
        (New-Object System.Drawing.Rectangle(32, 48, 46, 110))
    )
    Save-SpiritCrop $corBmp 696 150 120 236 "spirit_corrupted_left.png"  $true $true  $null @(
        (New-Object System.Drawing.Rectangle(38, 48, 44, 110))
    )
    $corBmp.Dispose()
}

# 6. Clear Sky Guardian — After Cleansing (CorruptedSpirit: Cleansed Dharmapala Form)
$clnSpiritPath = Join-Path $ResourcesDir "mist_demon_cleansed_sheet.jpg"
if (Test-Path $clnSpiritPath) {
    $clnBmp = [System.Drawing.Bitmap]::FromFile($clnSpiritPath)
    Save-Crop       $clnBmp 8   112 244 280 "spirit_cleansed_portrait.png" 0
    Save-SpiritCrop $clnBmp 268 148 152 240 "spirit_cleansed_front.png" $false $false @(
        (New-Object System.Drawing.Rectangle(0, 190, 26, 50))
    ) @(
        (New-Object System.Drawing.Rectangle(42, 62, 68, 48))
    )
    Save-SpiritCrop $clnBmp 428 148 144 240 "spirit_cleansed_back.png"  $false $false $null @(
        (New-Object System.Drawing.Rectangle(42, 62, 60, 80))
    )
    Save-SpiritCrop $clnBmp 576 148 122 240 "spirit_cleansed_left.png"  $false $false $null @(
        (New-Object System.Drawing.Rectangle(28, 66, 56, 44))
    )
    Save-SpiritCrop $clnBmp 700 148 120 240 "spirit_cleansed_right.png" $false $false $null @(
        (New-Object System.Drawing.Rectangle(36, 66, 56, 44))
    )
    $clnBmp.Dispose()
}

# 7. Fire Imp Demon — Before Cleansing (Wrathful Fire Imp) & After Cleansing (Courage Flame Guardian)
$fiCorPath = Join-Path $ResourcesDir "fire_imp_corrupted_sheet.jpg"
if (Test-Path $fiCorPath) {
    $fiCor = [System.Drawing.Bitmap]::FromFile($fiCorPath)
    Save-Crop           $fiCor 10  102 236 282 "fire_imp_corrupted_portrait.png" 0
    Save-CardSpiritCrop $fiCor 256 146 136 216 "fire_imp_corrupted_front.png" 28 $true
    Save-CardSpiritCrop $fiCor 406 146 134 216 "fire_imp_corrupted_back.png"  28 $true
    Save-CardSpiritCrop $fiCor 560 146 120 216 "fire_imp_corrupted_left.png"  28 $true
    Save-CardSpiritCrop $fiCor 694 146 128 216 "fire_imp_corrupted_right.png" 28 $true
    $fiCor.Dispose()
}
$fiClnPath = Join-Path $ResourcesDir "fire_imp_cleansed_sheet.jpg"
if (Test-Path $fiClnPath) {
    $fiCln = [System.Drawing.Bitmap]::FromFile($fiClnPath)
    Save-Crop           $fiCln 10  102 236 282 "fire_imp_cleansed_portrait.png" 0
    Save-CardSpiritCrop $fiCln 256 146 136 216 "fire_imp_cleansed_front.png" 22 $true @(
        (New-Object System.Drawing.Rectangle(36, 45, 64, 130))
    )
    Save-CardSpiritCrop $fiCln 408 146 130 216 "fire_imp_cleansed_back.png"  22 $true @(
        (New-Object System.Drawing.Rectangle(34, 45, 62, 130))
    )
    Save-CardSpiritCrop $fiCln 560 146 120 216 "fire_imp_cleansed_left.png"  22 $true @(
        (New-Object System.Drawing.Rectangle(38, 45, 52, 130))
    )
    Save-CardSpiritCrop $fiCln 694 146 130 216 "fire_imp_cleansed_right.png" 22 $true @(
        (New-Object System.Drawing.Rectangle(36, 45, 54, 130))
    )
    $fiCln.Dispose()
}

# 8. Shadow Cave Demon — Before Cleansing (Wrathful Form) & After Cleansing (Cave Light Guardian)
$scCorPath = Join-Path $ResourcesDir "shadow_cave_corrupted_sheet.jpg"
if (Test-Path $scCorPath) {
    $scCor = [System.Drawing.Bitmap]::FromFile($scCorPath)
    Save-Crop           $scCor 6   94  286 336 "shadow_cave_corrupted_portrait.png" 0
    Save-CardSpiritCrop $scCor 324 134 162 162 "shadow_cave_corrupted_front.png" 24 $true
    Save-CardSpiritCrop $scCor 490 134 158 162 "shadow_cave_corrupted_back.png"  24 $true
    Save-CardSpiritCrop $scCor 650 134 162 162 "shadow_cave_corrupted_left.png"  24 $true
    Save-CardSpiritCrop $scCor 814 134 174 162 "shadow_cave_corrupted_right.png" 24 $true
    $scCor.Dispose()
}
$scClnPath = Join-Path $ResourcesDir "shadow_cave_cleansed_sheet.jpg"
if (Test-Path $scClnPath) {
    $scCln = [System.Drawing.Bitmap]::FromFile($scClnPath)
    Save-Crop           $scCln 6   82  286 336 "shadow_cave_cleansed_portrait.png" 0
    Save-CardSpiritCrop $scCln 326 116 146 158 "shadow_cave_cleansed_front.png" 22 $true
    Save-CardSpiritCrop $scCln 476 116 154 158 "shadow_cave_cleansed_back.png"  22 $true
    Save-CardSpiritCrop $scCln 640 116 146 158 "shadow_cave_cleansed_left.png"  22 $true
    Save-CardSpiritCrop $scCln 800 116 174 158 "shadow_cave_cleansed_right.png" 22 $true
    $scCln.Dispose()
}

# 9. Stone Giant Demon — Before Cleansing (Wrathful Form) & After Cleansing (Temple Guardian Giant)
$sgCorPath = Join-Path $ResourcesDir "stone_giant_corrupted_sheet.jpg"
if (Test-Path $sgCorPath) {
    $sgCor = [System.Drawing.Bitmap]::FromFile($sgCorPath)
    Save-Crop           $sgCor 12  96 224 202 "stone_giant_corrupted_portrait.png" 0
    Save-CardSpiritCrop $sgCor 242 92 222 206 "stone_giant_corrupted_front.png" 24 $false
    Save-CardSpiritCrop $sgCor 472 92 218 206 "stone_giant_corrupted_back.png"  24 $false
    Save-CardSpiritCrop $sgCor 704 92 120 206 "stone_giant_corrupted_right.png" 24 $false
    Save-CardSpiritCrop $sgCor 854 92 130 206 "stone_giant_corrupted_left.png"  24 $false
    $sgCor.Dispose()
}
$sgClnPath = Join-Path $ResourcesDir "stone_giant_cleansed_sheet.jpg"
if (Test-Path $sgClnPath) {
    $sgCln = [System.Drawing.Bitmap]::FromFile($sgClnPath)
    Save-Crop           $sgCln 10  94 230 204 "stone_giant_cleansed_portrait.png" 0
    Save-CardSpiritCrop $sgCln 246 90 232 208 "stone_giant_cleansed_front.png" 18 $false @(
        (New-Object System.Drawing.Rectangle(64, 42, 104, 140))
    )
    Save-CardSpiritCrop $sgCln 488 90 214 208 "stone_giant_cleansed_back.png"  18 $false @(
        (New-Object System.Drawing.Rectangle(56, 42, 102, 140))
    )
    Save-CardSpiritCrop $sgCln 720 90 108 208 "stone_giant_cleansed_right.png" 18 $false @(
        (New-Object System.Drawing.Rectangle(18, 48, 72, 136))
    )
    Save-CardSpiritCrop $sgCln 846 90 108 208 "stone_giant_cleansed_left.png"  18 $false @(
        (New-Object System.Drawing.Rectangle(14, 52, 78, 132))
    )
    $sgCln.Dispose()
}

Write-Output "All game assets extracted successfully to $SpritesDir"
