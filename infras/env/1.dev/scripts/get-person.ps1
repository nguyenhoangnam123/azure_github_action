$appId = "080b8d68-fd36-471b-bc32-d009ba39ec24"
$tenantId = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
$password = "G9b8Q~2UPdDtlOss9zSAx0t_V~XmZ0TxwB0.8aOb" # New-AzADSpCredential -ObjectId $credentialId
$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($appId, $secpasswd)
$ConnectionString="Data Source=namnh21894-mssql-dev-server.database.windows.net; Initial Catalog=terraform-dev-db;"
$Query="SELECT * FROM [dbo].[Persons]"

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
