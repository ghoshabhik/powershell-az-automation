# Get subscription ID
#$subcriptionId = Get-AzSubscription | where-object {$_.Name -like "Primary*"} | Select-Object -Property Id

$inputFile = Import-Csv .\RemoveUserFromADGroup.csv

foreach ($line in $inputFile)
{
    $inputGroupName =  $line.group_name
    $inputUser = $line.user
    $group = Get-AzADGroup -SearchString $inputGroupName | Where-Object { $_.DisplayName -eq $inputGroupName}
    if($group){ #Validate if the group exists
        $groupId = $group.Id
        Write-Host "$inputGroupName : found with Group Id: $groupId"
        $user = Get-AzADUser -UserPrincipalName $inputUser
        if($user){ #Validate if the user exists
            $userId = $user.Id
            $userName = $inputUser.Substring(0, $inputUser.IndexOf("@"))
            Write-Host "$userName : found with User Id: $userId"
            try{
                Remove-AzADGroupMember -MemberObjectId $userId -GroupObjectId $groupId
                Write-Host "$userName : Removed from AD Group : $inputGroupName"
            }
            catch {
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }
        else{
            Write-Host "$inputUser : is not found"
        }
    }
    else{
        Write-Host "$inputGroupName : is not found"
    }
}

