# param (
#     [string]$SourceSQLHost,
#     [string]$TargetSQLHost1,
#     [string]$SqlUsername,
#     [string]$SqlPassword,
#     [string]$InstanceName1,
#     [string]$InstanceName2
# )

# $sourceInstance = if ($InstanceName1 -ne '') { "$SourceSQLHost\\$InstanceName1" } else { $SourceSQLHost }
# $targetInstance = if ($InstanceName2 -ne '') { "$TargetSQLHost1\\$InstanceName2" } else { $TargetSQLHost1 }

# # Get non-system logins from source
# $loginsQuery = @"
# SELECT 'CREATE LOGIN [' + sp.name + '] WITH PASSWORD = ' + 
#        CONVERT(VARCHAR(MAX), sl.password_hash, 1) + ', CHECK_POLICY = OFF;' AS CreateScript
# FROM sys.sql_logins sl
# JOIN sys.server_principals sp ON sl.principal_id = sp.principal_id
# WHERE sp.name NOT LIKE '##%' AND sp.name NOT LIKE 'NT AUTHORITY%' AND sp.name NOT LIKE 'NT SERVICE%'
# "@

# # Run query on source and save output
# $createLoginScripts = & "/opt/mssql-tools/bin/sqlcmd" -S $sourceInstance -U $SqlUsername -P $SqlPassword -Q $loginsQuery -h -1 -W | Where-Object { $_ -and $_ -notmatch 'rows affected' }

# # Apply scripts to target
# foreach ($script in $createLoginScripts) {
#     & "/opt/mssql-tools/bin/sqlcmd" -S $targetInstance -U $SqlUsername -P $SqlPassword -Q $script
# }
param (
    [string]$SourceSQLHost,
    [string]$TargetSQLHost1,
    [string]$SqlUsername,
    [string]$SqlPassword,
    [string]$InstanceName1,
    [string]$InstanceName2
)

# Compose full instance names (IP\Instance or just IP)
$sourceInstance = if ($InstanceName1 -ne '') { "$SourceSQLHost\\$InstanceName1" } else { $SourceSQLHost }
$targetInstance = if ($InstanceName2 -ne '') { "$TargetSQLHost1\\$InstanceName2" } else { $TargetSQLHost1 }

# Query to extract logins with hashed passwords (correct method)
$loginsQuery = @"
SELECT 
  'CREATE LOGIN [' + sp.name + '] WITH PASSWORD = 0x' + 
  CONVERT(VARCHAR(MAX), sl.password_hash, 2) + 
  ' HASHED, CHECK_POLICY = OFF;' AS CreateScript
FROM sys.sql_logins sl
JOIN sys.server_principals sp 
  ON sl.principal_id = sp.principal_id
WHERE sp.name NOT LIKE '##%' 
  AND sp.name NOT LIKE 'NT AUTHORITY%' 
  AND sp.name NOT LIKE 'NT SERVICE%'
"@

# Get the login creation scripts from the source instance
$createLoginScripts = & "/opt/mssql-tools/bin/sqlcmd" `
    -S $sourceInstance `
    -U $SqlUsername `
    -P $SqlPassword `
    -Q $loginsQuery `
    -h -1 -W | Where-Object { $_ -and $_ -notmatch 'rows affected' }

# Apply each script to the target instance
foreach ($script in $createLoginScripts) {
    & "/opt/mssql-tools/bin/sqlcmd" `
        -S $targetInstance `
        -U $SqlUsername `
        -P $SqlPassword `
        -Q $script
}
