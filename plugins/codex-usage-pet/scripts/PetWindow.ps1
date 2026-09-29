# Process identity plus a visible, non-minimized WPF window intersecting a display.
Add-Type -AssemblyName System.Windows.Forms
if (-not ('UsagePetWindowCheck' -as [type])) {
    Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class UsagePetWindowCheck {
    public delegate bool Callback(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(Callback c, IntPtr l);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out Rect r);
    public struct Rect { public int Left, Top, Right, Bottom; }
    public static IntPtr[] Find(int[] processIds) {
        var found = new List<IntPtr>();
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (Array.IndexOf(processIds, (int)pid) < 0 || !IsWindowVisible(h) || IsIconic(h)) return true;
            var name = new StringBuilder(256); GetClassName(h, name, name.Capacity);
            if (name.ToString().StartsWith("HwndWrapper")) found.Add(h);
            return true;
        }, IntPtr.Zero);
        return found.ToArray();
    }
}
'@
}

function Get-PetWindow {
    param([Parameter(Mandatory=$true)][string]$ScriptPath)
    # Match the exact -File argument; never accept an arbitrary PowerShell window.
    $pathPattern = '(?i)(?:^|\s)-File\s+(?:"' + [regex]::Escape($ScriptPath) + '"|' + [regex]::Escape($ScriptPath) + ')(?:\s|$)'
    $processIds = @(
        Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction Stop |
            Where-Object { $_.CommandLine -match $pathPattern } |
            ForEach-Object { [int]$_.ProcessId }
    )
    foreach ($handle in [UsagePetWindowCheck]::Find([int[]]$processIds)) {
        $rect = New-Object UsagePetWindowCheck+Rect
        if (-not [UsagePetWindowCheck]::GetWindowRect($handle, [ref]$rect)) { continue }
        if ($rect.Right -le $rect.Left -or $rect.Bottom -le $rect.Top) { continue }
        $onScreen = @([System.Windows.Forms.Screen]::AllScreens | Where-Object {
            $rect.Left -lt $_.Bounds.Right -and $rect.Right -gt $_.Bounds.Left -and
            $rect.Top -lt $_.Bounds.Bottom -and $rect.Bottom -gt $_.Bounds.Top
        }).Count -gt 0
        if ($onScreen) {
            [pscustomobject]@{
                Status = 'Verified pet window'
                Handle = $handle.ToInt64()
                Left = $rect.Left
                Top = $rect.Top
                Width = $rect.Right - $rect.Left
                Height = $rect.Bottom - $rect.Top
            }
        }
    }
}
