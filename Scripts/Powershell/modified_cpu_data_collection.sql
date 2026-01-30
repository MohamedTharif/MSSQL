# Parameters
$SqlInstance = "localhost"
$Database    = "DBADB"
$Table       = "CPUUtilisationdata"

# Ensure errors stop execution
$ErrorActionPreference = "Stop"

# 1. Create table if not exists
$createTableQuery = @"
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '$Table')
BEGIN
    CREATE TABLE dbo.$Table (
        CaptureTime DATETIME NOT NULL,
        UsedCPU INT NOT NULL,
        FreeCPU INT NOT NULL
    )
END
"@

Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $Database -Query $createTableQuery

# 2. Get CPU usage (PerfCounter → WMI fallback)
try {
    $totalCpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).
                CounterSamples[0].CookedValue
}
catch {
    # Fallback to WMI (more stable in SQL Agent)
    $totalCpu = Get-WmiObject Win32_Processor |
                Measure-Object -Property LoadPercentage -Average |
                Select-Object -ExpandProperty Average
}

$totalCpu = [math]::Round($totalCpu, 0)
$freeCpu  = [math]::Round((100 - $totalCpu), 0)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 3. Insert into SQL Server (safe datetime handling)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$insertQuery = "
INSERT INTO dbo.$Table (CaptureTime, UsedCPU, FreeCPU)
VALUES ('$timestamp', $totalCpu, $freeCpu)
"

Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $Database -Query $insertQuery


Write-Host "[$timestamp] Inserted Used CPU %: $totalCpu"
Write-Host "[$timestamp] Inserted Free CPU %: $freeCpu"
