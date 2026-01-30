# Parameters
$SqlInstance = "localhost"
$Database    = "DBADB"
$Table       = "CPUUtilisationdata"

# 1. Create table if not exists
$createTableQuery = "IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '$Table')
BEGIN
    CREATE TABLE [$Table] (
        CaptureTime DATETIME NOT NULL,
        UsedCPU INT NOT NULL,
        FreeCPU INT NOT NULL

    )
END"

Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $Database -Query $createTableQuery

# 2. Get total CPU usage
$totalCpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$totalCpu = [math]::Round($totalCpu, 0)
$freeCpu = [math]::Round((100-$totalCpu), 0)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 3. Insert into SQL Server
$insertQuery = "INSERT INTO [dbo].[$Table] (CaptureTime, UsedCPU,FreeCPU) VALUES ('$timestamp', $totalCpu,$freeCpu)"
Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $Database -Query $insertQuery

Write-Host "[$timestamp] Inserted Used CPU %: $totalCpu %"
Write-Host "[$timestamp] Inserted Free CPU %: $freeCpu %"