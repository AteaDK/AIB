#Requires -Version 3.0 -Module Az.Accounts

function Enable-AteaAIBFeatures 
{
  <#
      .SYNOPSIS
      Enable AIB features
  
      .DESCRIPTION
      Enable Azure Image builder features
      https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-powershell
  
      .EXAMPLE
      Enable-AteaAIBFeatures
  
      .LINK
      -
  
      .INPUTS
      None
  
      .OUTPUTS
      None
  
      .NOTES
      Filename  : Enable-AteaAIBFeatures.ps1
      Author    : Lars Krogh Paulsen, lars.krogh.paulsen@atea.dk
      Version   : 1.0.0
      Date      : 05-03-2021
      Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and is not supported by the authors or ATEA A/S
  #>

  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'

  # Set Variables for the commands
  $providerNamespace = 'Microsoft.VirtualMachineImages'
  $featureName = 'VirtualMachineTemplatePreview'

  # Log In
  Connect-AzAccount

  # View current subscription
  Get-AzContext

  # Set subscription 
  Set-AzContext

  # Register the Virtual Machine Template Preview feature
  Register-AzProviderFeature -ProviderNamespace $providerNamespace -FeatureName $featureName

  # Do not continue until the feature changes from Registering to Registered - verify status
  Get-AzProviderFeature -ProviderNamespace $providerNamespace -FeatureName $featureName

  # Register resource providers, if not already registered
  Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages |
  Where-Object -Property RegistrationState -NE -Value Registered |
  Register-AzResourceProvider
}

. Enable-AteaAIBFeatures 
