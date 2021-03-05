#Requires -Version 2.0 -Module Az.ImageBuilder, Az.ManagedServiceIdentity

function Enable-AteaAIBIdentity
{
  <#
      .SYNOPSIS
      Enable AIB identity
  
      .DESCRIPTION
      Enable Azure Image Builder identity
  
      .EXAMPLE
      Enable-AteaAIBIdentity
  
      .LINK
      -
  
      .INPUTS
      None
  
      .OUTPUTS
      None
  
      .NOTES
      Filename  : Enable-AteaAIBIdentity.ps1
      Author    : Lars Krogh Paulsen, lars.krogh.paulsen@atea.dk
      Version   : 1.0.0
      Date      : 05-03-2021
      Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and is not supported by the authors or ATEA A/S
  #>

  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'

  $imageBuilderModule = 'Az.ImageBuilder'
  $managedServiceIdentityModule = 'Az.ManagedServiceIdentity'
  $imageResourceGroup = 'lskp-dev-aib-rg'
  $location = 'West Europe'
  $subscriptionID = (Get-AzContext).Subscription.Id

  if ($null -eq (Get-Module -ListAvailable -Name $managedServiceIdentityModule)) 
  {
    Install-Module -Name $managedServiceIdentityModule -Force -AllowPrerelease
  }
  if ($null -eq (Get-Module -ListAvailable -Name $imageBuilderModule)) 
  {
    Install-Module -Name $imageBuilderModule -Force -AllowPrerelease
  }
  Import-Module -Name $managedServiceIdentityModule
  Import-Module -Name $imageBuilderModule

  # Create the Resource Group
  New-AzResourceGroup -Name $imageResourceGroup -Location $location

  # Create the Managed Identity and use the current time to verify names are unique
  [int]$timeInt = $(Get-Date -UFormat '%s')
  $imageRoleDefName = ('Azure Image Builder Image Def {0}' -f $timeInt)
  $identityName = ('lskpIdentity{0}' -f $timeInt)

  # Create the user identity
  New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

  # Assign permissions for identity to distribute images (downloads a .json file from github with the settings and updates the file with the new subscription settings)
  [string]$tempFolderPath = ([IO.Path]::GetTempPath()) + ([guid]::NewGuid())
  $identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId
  $aibRoleImageCreationUrl = 'https://raw.githubusercontent.com/larskroghdk/AIB/main/aibRoleImageCreation.json'
  $aibRoleImageCreationPath = ('{0}\aibRoleImageCreation.json' -f $tempFolderPath)

  # Create a folder for the json file
  $null = New-Item -ItemType Directory -Path ('{0}' -f $tempFolderPath) -Force

  # Download the file
  Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

  # Modify the json file
  $fileContent = Get-Content -Path $aibRoleImageCreationPath -Raw
  $fileContent = $fileContent -replace '_replace_subscriptionid_', $subscriptionID
  $fileContent = $fileContent -replace '_replace_rgName_', $imageResourceGroup
  $fileContent = $fileContent -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
  $fileContent | Out-File -FilePath $aibRoleImageCreationPath -Force

  # Create the Role definition
  New-AzRoleDefinition -InputFile $aibRoleImageCreationPath

  # Grant the Role definition to the Image Builder service principle
  $params = @{
    ObjectId           = $identityNamePrincipalId
    RoleDefinitionName = $imageRoleDefName
    Scope              = ('/subscriptions/{0}/resourceGroups/{1}' -f $subscriptionID, $imageResourceGroup)
  }
  New-AzRoleAssignment @params

  # Verify Role Assignment
  Get-AzRoleAssignment -ObjectId $identityNamePrincipalId | Select-Object -Property DisplayName, RoleDefinitionName

  # Cleanup
  Remove-Item $tempFolderPath -Force -ErrorAction SilentlyContinue
}

. Enable-AteaAIBIdentity
