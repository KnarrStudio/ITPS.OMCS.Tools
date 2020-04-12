function Test-SQLConnection
{    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory,HelpMessage='Add SQL ServerNAme',
                    ValueFromPipelineByPropertyName,
                    Position=0)]
        [String]$ConnectionString
    )
    try
    {
        $sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $ConnectionString

        $sqlConnection.Open()

        $sqlConnection.Close()


        return $true

    }
    catch
    {
        return $false

    }
}

Test-SQLConnection