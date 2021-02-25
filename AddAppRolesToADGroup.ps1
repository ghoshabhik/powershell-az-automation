# Get subscription ID
#$subcriptionId = Get-AzSubscription | where-object {$_.Name -like "Primary*"} | Select-Object -Property Id
$resourceGroupName = "DEV_LAB"
$inputFile = Import-Csv .\AddRolesToADGroups.csv

foreach ($line in $inputFile)
{
    $inputGroupName =  $line.group_name
    $inputAppName = $line.app_name
    $inputRoleName = $line.role_type
    $group = Get-AzADGroup -SearchString $inputGroupName | Where-Object { $_.DisplayName -eq $inputGroupName}
    if($group){ #Validate The Group exists
        $inputGroupId = $group.Id
        Write-Host "$inputGroupName : found. Group Id: $inputGroupId"
        $app = Get-AzResource -ResourceGroupName $resourceGroupName -Name $inputAppName
        if($app){
            $resourceType = $app.ResourceType
            try{
                $newAssignment = New-AzRoleAssignment -ObjectId $inputGroupId `
                                    -RoleDefinitionName $inputRoleName `
                                    -ResourceName $inputAppName `
                                    -ResourceType $resourceType `
                                    -ResourceGroupName $resourceGroupName
                Write-Host "$newAssignment : Role assignment is created"
            }
            catch {
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }
        else {
            Write-Host "$inputAppName : is not found, please submit the job with correct App name"
        }
    }
    else{
        Write-Host "$inputGroupName : is not found, please submit the job with correct AD Group name"
    }
}

