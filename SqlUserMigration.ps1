
# param (
#     [string]$SourceSQLHost,
#     [string]$TargetSQLHost1,
#     [string]$SqlUsername,
#     [string]$SqlPassword,
#     [string]$InstanceName1,
#     [string]$InstanceName2
# )

# # Compose full instance names (IP\Instance or just IP)
# $sourceInstance = if ($InstanceName1 -ne '') { "$SourceSQLHost\\$InstanceName1" } else { $SourceSQLHost }
# $targetInstance = if ($InstanceName2 -ne '') { "$TargetSQLHost1\\$InstanceName2" } else { $TargetSQLHost1 }

# # Query to extract logins with hashed passwords (correct method)
# $loginsQuery = @"
# SELECT 
#   'CREATE LOGIN [' + sp.name + '] WITH PASSWORD = 0x' + 
#   CONVERT(VARCHAR(MAX), sl.password_hash, 2) + 
#   ' HASHED, CHECK_POLICY = OFF;' AS CreateScript
# FROM sys.sql_logins sl
# JOIN sys.server_principals sp 
#   ON sl.principal_id = sp.principal_id
# WHERE sp.name NOT LIKE '##%' 
#   AND sp.name NOT LIKE 'NT AUTHORITY%' 
#   AND sp.name NOT LIKE 'NT SERVICE%'
# "@

# # Get the login creation scripts from the source instance
# $createLoginScripts = & "/opt/mssql-tools/bin/sqlcmd" `
#     -S $sourceInstance `
#     -U $SqlUsername `
#     -P $SqlPassword `
#     -Q $loginsQuery `
#     -h -1 -W | Where-Object { $_ -and $_ -notmatch 'rows affected' }

# # Apply each script to the target instance
# foreach ($script in $createLoginScripts) {
#     & "/opt/mssql-tools/bin/sqlcmd" `
#         -S $targetInstance `
#         -U $SqlUsername `
#         -P $SqlPassword `
#         -Q $script
# }

# Define backup file path and DB name
$dbName = "demo"
$backupFileName = "$dbName.bak"
$backupFilePath = "/var/opt/mssql/backups/$backupFileName"

# Step 1: Backup demo database on source
$backupQuery = "BACKUP DATABASE [$dbName] TO DISK = N'$backupFilePath' WITH INIT, COPY_ONLY;"

Write-Host "Backing up $dbName on $sourceInstance..."
& "/opt/mssql-tools/bin/sqlcmd" `
    -S $sourceInstance `
    -U $SqlUsername `
    -P $SqlPassword `
    -Q $backupQuery

# Step 2: Copy backup file from source to target (you can use scp or ensure shared volume)
# Example with scp (replace with your method)
Write-Host "Copying backup file to target server..."
$scpCommand = "scp ${SourceSQLHost}:${backupFilePath} ${TargetSQLHost1}:${backupFilePath}"

Invoke-Expression $scpCommand

# Step 3: Restore the demo database on the target
# First, get logical file names from backup
$logicalNames = & "/opt/mssql-tools/bin/sqlcmd" `
    -S $targetInstance `
    -U $SqlUsername `
    -P $SqlPassword `
    -Q "RESTORE FILELISTONLY FROM DISK = N'$backupFilePath'" `
    -h -1 -W | Where-Object { $_ -and $_ -notmatch 'rows affected' }

# Parse logical names
$dataLogicalName = ($logicalNames | Where-Object { $_ -match '.*\.mdf' }) -split '\s+' | Select-Object -First 1
$logLogicalName = ($logicalNames | Where-Object { $_ -match '.*\.ldf' }) -split '\s+' | Select-Object -First 1

# Define restore paths
$dataFilePath = "/var/opt/mssql/data/$dbName.mdf"
$logFilePath = "/var/opt/mssql/data/$dbName_log.ldf"

# Restore query
$restoreQuery = @"
RESTORE DATABASE [$dbName]
FROM DISK = N'$backupFilePath'
WITH MOVE N'$dataLogicalName' TO N'$dataFilePath',
     MOVE N'$logLogicalName' TO N'$logFilePath',
     REPLACE;
"@

Write-Host "Restoring $dbName on $targetInstance..."
& "/opt/mssql-tools/bin/sqlcmd" `
    -S $targetInstance `
    -U $SqlUsername `
    -P $SqlPassword `
    -Q $restoreQuery
