param (
    [string]$SourceSQLHost,
    [string]$TargetSQLHost1,   # just one target now per run
    [string]$SqlUsername,
    [string]$SqlPassword,
    [string]$InstanceName1,
    [string]$InstanceName2
)

Import-Module SqlServer
$securePassword = ConvertTo-SecureString $SqlPassword -AsPlainText -Force

$sourceInstance = if ($InstanceName1 -ne '') { "$SourceSQLHost\$InstanceName1" } else { $SourceSQLHost }
$targetInstance = if ($InstanceName2 -ne '') { "$TargetSQLHost1\$InstanceName2" } else { $TargetSQLHost1 }

$source = New-Object Microsoft.SqlServer.Management.Smo.Server $sourceInstance
$source.ConnectionContext.LoginSecure = $false
$source.ConnectionContext.set_Login($SqlUsername)
$source.ConnectionContext.set_SecurePassword($securePassword)

$target = New-Object Microsoft.SqlServer.Management.Smo.Server $targetInstance
$target.ConnectionContext.LoginSecure = $false
$target.ConnectionContext.set_Login($SqlUsername)
$target.ConnectionContext.set_SecurePassword($securePassword)

$logins = $source.Logins | Where-Object { -not $_.IsSystemObject }

foreach ($login in $logins) {
    if (-not $target.Logins.Contains($login.Name)) {
        $createScript = $login.Script() -join "`n"
        Invoke-Sqlcmd -ServerInstance $targetInstance -Username $SqlUsername -Password $SqlPassword -Query $createScript
    }
}
