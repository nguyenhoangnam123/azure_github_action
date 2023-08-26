$appId = "080b8d68-fd36-471b-bc32-d009ba39ec24"
$tenantId = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
$password = "ZpK8Q~e75fWxFDTb_d2t9RywTzDmU4R_y8-sJaVS"
$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($appId, $secpasswd)
$ConnectionString="Data Source=namnh21894-dev-mssqlserver-main.database.windows.net; Initial Catalog=namnh21894-dev-mssql-db;"
#$Query=@"
#CREATE USER [terraform-msi] FROM EXTERNAL PROVIDER
#ALTER ROLE db_datareader ADD MEMBER [terraform-msi]
#"@

$Query=@"
SELECT DP1.name AS DatabaseRoleName,
   isnull (DP2.name, 'No members') AS DatabaseUserName
 FROM sys.database_role_members AS DRM
 RIGHT OUTER JOIN sys.database_principals AS DP1
   ON DRM.role_principal_id = DP1.principal_id
 LEFT OUTER JOIN sys.database_principals AS DP2
   ON DRM.member_principal_id = DP2.principal_id
WHERE DP1.type = 'R'
ORDER BY DP1.name;
"@

Connect-AzAccount -ServicePrincipal -Credential $mycreds -Tenant $tenantId
    #get token
    $context =Get-AzContext
    $dexResourceUrl='https://database.windows.net/'
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account,
                                    $context.Environment,
                                    $context.Tenant.Id.ToString(),
                                     $null,
                                     [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never,
                                     $null, $dexResourceUrl).AccessToken
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    try
    {
        $SqlConnection.ConnectionString = $ConnectionString
        if ($token)
        {
            $SqlConnection.AccessToken = $token
        }
        $SqlConnection.Open()

        $SqlCmd.Connection = $SqlConnection

        $SqlCmd.CommandText = $Query
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet)
        #Outputs query
        $DataSet.Tables
    }
    finally
    {
        $SqlAdapter.Dispose()
        $SqlCmd.Dispose()
        $SqlConnection.Dispose()
    }
Disconnect-AzAccount

