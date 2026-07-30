using System;
using System.Diagnostics;
using System.Text;
using System.Threading;

namespace CodexUsagePet
{
    public sealed class CodexAppServerClient : IDisposable
    {
        private readonly object sync = new object();
        private readonly string codexPath;
        private Process process;
        private int nextRequestId = 1;
        private string latestJson;
        private string latestError;
        private int revision;

        public CodexAppServerClient(string codexPath)
        {
            if (String.IsNullOrWhiteSpace(codexPath))
                throw new ArgumentException("codex.exe path is required", "codexPath");
            this.codexPath = codexPath;
        }

        public string LatestJson
        {
            get { lock (sync) { return latestJson; } }
        }

        public string LatestError
        {
            get { lock (sync) { return latestError; } }
        }

        public int Revision
        {
            get { return Interlocked.CompareExchange(ref revision, 0, 0); }
        }

        public bool IsRunning
        {
            get { return process != null && !process.HasExited; }
        }

        public void Start()
        {
            if (IsRunning) return;

            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = codexPath;
            info.Arguments = "app-server --stdio";
            info.UseShellExecute = false;
            info.CreateNoWindow = true;
            info.RedirectStandardInput = true;
            info.RedirectStandardOutput = true;
            info.RedirectStandardError = true;
            info.StandardOutputEncoding = Encoding.UTF8;
            info.StandardErrorEncoding = Encoding.UTF8;

            process = new Process();
            process.StartInfo = info;
            process.EnableRaisingEvents = true;
            process.OutputDataReceived += OnOutputDataReceived;
            process.ErrorDataReceived += OnErrorDataReceived;
            process.Exited += OnExited;

            if (!process.Start())
                throw new InvalidOperationException("Unable to start codex app-server");

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            Send("{\"method\":\"initialize\",\"id\":1,\"params\":{\"clientInfo\":{\"name\":\"codex-usage-pet\",\"version\":\"0.1.0\"},\"capabilities\":{\"experimentalApi\":true}}}");
            Send("{\"method\":\"initialized\"}");
            Refresh();
        }

        public void Refresh()
        {
            if (!IsRunning)
            {
                Start();
                return;
            }

            int id = Interlocked.Increment(ref nextRequestId);
            Send("{\"method\":\"account/rateLimits/read\",\"id\":" + id.ToString() + "}");
        }

        private void Send(string line)
        {
            try
            {
                process.StandardInput.WriteLine(line);
                process.StandardInput.Flush();
            }
            catch (Exception ex)
            {
                SetError("无法与 Codex 通信：" + ex.Message);
            }
        }

        private void OnOutputDataReceived(object sender, DataReceivedEventArgs args)
        {
            string line = args.Data;
            if (String.IsNullOrWhiteSpace(line)) return;

            if (line.IndexOf("\"result\":{\"rateLimits\"", StringComparison.Ordinal) >= 0)
            {
                lock (sync)
                {
                    latestJson = line;
                    latestError = null;
                }
                Interlocked.Increment(ref revision);
            }
        }

        private void OnErrorDataReceived(object sender, DataReceivedEventArgs args)
        {
            if (!String.IsNullOrWhiteSpace(args.Data))
                SetError(args.Data);
        }

        private void OnExited(object sender, EventArgs args)
        {
            if (process != null && process.ExitCode != 0)
                SetError("Codex app-server 已退出（代码 " + process.ExitCode.ToString() + "）");
        }

        private void SetError(string message)
        {
            lock (sync) { latestError = message; }
            Interlocked.Increment(ref revision);
        }

        public void Dispose()
        {
            Process current = process;
            process = null;
            if (current == null) return;

            try
            {
                if (!current.HasExited)
                {
                    current.StandardInput.Close();
                    if (!current.WaitForExit(500)) current.Kill();
                }
            }
            catch { }
            finally { current.Dispose(); }
        }
    }

    public static class DpiAwareness
    {
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool SetProcessDpiAwarenessContext(IntPtr value);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool SetWindowPos(
            IntPtr window,
            IntPtr insertAfter,
            int x,
            int y,
            int width,
            int height,
            uint flags);

        public static void EnablePerMonitorV2()
        {
            try { SetProcessDpiAwarenessContext(new IntPtr(-4)); }
            catch { }
        }

        public static void EnsureWindowVisible(IntPtr window)
        {
            const uint NoSize = 0x0001;
            const uint NoMove = 0x0002;
            const uint NoZOrder = 0x0004;
            const uint ShowWindow = 0x0040;
            if (window != IntPtr.Zero)
                SetWindowPos(window, IntPtr.Zero, 0, 0, 0, 0, NoSize | NoMove | NoZOrder | ShowWindow);
        }
    }
}
