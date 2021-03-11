## Powershell Script to remove user from an AD group 
## Input Parameter: CSV File with list of users; File name is expected as group name
## Run Script Example: ./RemoveUserFromADGroup.ps1 <GROUP_NAME>.csv

## ----Input Validation Starts----
$inputParameter = $args[0]
if(-not ($inputParameter)){
    Write-Host "Input Error: Filename is required" -ForegroundColor Red
    Exit
}
$fileInputParam = $inputParameter.IndexOf("\")
if($fileInputParam -eq -1){
    Write-Host "File path is assumed to be the current directory"
    $inputFile = Import-Csv (Get-ChildItem | Where-Object { $_.Name -eq $inputParameter})
    $groupName = $inputParameter.Substring(0, $inputParameter.IndexOf(".csv"))
    Write-Host "Using Group Name: $groupName `n"
}
else{
    $inputFile = Import-Csv $inputParameter
    $filepath = Get-ChildItem $inputParameter
    $groupName = $filepath.BaseName
    Write-Host "Using Group Name: $groupName `n" 
}
## ----Input Validation Ends----

## ---check if azure AD connection is already established (if not quit)---
try {
    Write-Host "Checking if Azure AD Connection is established..." -ForegroundColor Yellow
    $azconnect = Get-AzTenant -ErrorAction Stop
    $displayname = ($azconnect).Name
    write-host "Azure AD connection established to Tenant: $displayname `n `n `n" -ForegroundColor Green
    }
    catch {
    write-host "No connection to Azure AD was found. Please use Connect-AzureAD command `n" -ForegroundColor Red
    break
}

## ---Custom Function to check if an AD Group exists ---
Function Check-AdGroupExists(){
    param(
        [Parameter(Mandatory=$true)][string]$groupDisplayName
    )
    
    $group = Get-AzADGroup -SearchString $inputGroupName | Where-Object { $_.DisplayName -eq $groupDisplayName}
    if($group){ 
        $groupId = $group.Id
        Write-Host "$groupDisplayName : found. Group Id: $groupId" -ForegroundColor Green
        return $groupId
    } else {
        Write-Host "$groupDisplayName : is not found" -ForegroundColor Red
        return 
    }
}

## ---Custom Function to check if an AD UserPrincipalName exists ---
Function Check-AdUserExists(){
    param(
        [Parameter(Mandatory=$true)][string]$userPrincipalName
    )

    $user = Get-AzADUser -UserPrincipalName $userPrincipalName
    if($user){ 
        $userId = $user.Id
        Write-Host "$userPrincipalName : found. AD User Id: $userId" -ForegroundColor Green
        return $userId
    } else {
        Write-Host "$userPrincipalName : is not found" -ForegroundColor Red
        return 
    }
}

## ---Custom Function to check if given UserPricipalName exists in an AD Group---

Function Check-AdUserExistsInGroup(){
    param(
        [Parameter(Mandatory=$true)][string]$userPrincipalName,
        [Parameter(Mandatory=$true)][string]$groupId
    )

    $user = Get-AzADGroupMember -GroupObjectId $groupId | Where-Object { $_.UserPrincipalName -eq $userPrincipalName}
    if($user){ 
        Write-Host "$userPrincipalName : already exists in group: $groupId" -ForegroundColor Green
        return $true
    } else {
        Write-Host "$userPrincipalName : does not exist in group: $groupId" -ForegroundColor Red
        return $false
    }
}

## ---Process input file: 
## 1. Iterate through each line
## 2. extract group name and userPrincipalName
## 3. Check if AD group exists, if Yes - continue, No - Go to Next line
## 4. Check if AD user exists, if Yes - continue, No - Go to Next line
## 5. Check if AD user already in group, if No - continue, Yes - Go to Next line
## 6. Remove User from AD group
## Move to next line ---

$inputGroupName =  $groupName
foreach ($line in $inputFile)
{
    $lineIndex = $inputFile.IndexOf($line) + 1

    Write-Host "Start Processing Row# $lineIndex" -ForegroundColor Magenta
    
    $inputUser = $line.user_principal_name

    $groupId = Check-AdGroupExists $inputGroupName      ## ---Check if group exists---
    
    if($groupId){ 
        $userId = Check-AdUserExists $inputUser         ## ---Check if user exists---

        if($userId){ 

            if(Check-AdUserExistsInGroup $inputUser $groupId){   ## ---Check if user is already in the group ---
                try{
                    Remove-AzADGroupMember -MemberObjectId $userId -GroupObjectId $groupId      ## ---Remove User to the Group---
                    Write-Host "$inputUser : Removed from AD Group : $inputGroupName" -ForegroundColor Green
                    }
                catch {
                    Write-Error -Message $_.Exception
                    throw $_.Exception
                }
            }
            else{
                
            }
        }
    }
    Write-Host "End Processing Row# $lineIndex `n `n `n" -ForegroundColor Magenta
}
