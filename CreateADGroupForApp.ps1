# Get subscription ID
#$subcriptionId = Get-AzSubscription | where-object {$_.Name -like "Primary*"} | Select-Object -Property Id

$inputFile = Import-Csv .\CreateADGroupForApp.csv

foreach ($line in $inputFile)
{
    $inputGroupName =  $line.name
    $group = Get-AzADGroup -SearchString $inputGroupName | Where-Object { $_.DisplayName -eq $inputGroupName}
    if(! $group){
        Write-Host "$inputGroupName : doesn't exist. Creating New Group..."
        try{
            $newGroup = New-AzADGroup -DisplayName $inputGroupName  -MailNickName $inputGroupName+"test"
            Write-Host "$newGroup : Created"
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    else{
        Write-Host "$inputGroupName : A group with similar name exists. Ignoring..."
    }
}

