Param( 
[string]$WorkDir = "$(System.DefaultWorkingDirectory)/$(Release.PrimaryArtifactSourceAlias)/Drop/LogicApps/Scripts"
)
Write-Output 'start parameter building'
#Specify the path

#$WorkDir = "$(System.DefaultWorkingDirectory)/$(Release.PrimaryArtifactSourceAlias)/Drop/LogicApps/Scripts"
$WorkParamPath =[string]::format("{0}/LogicAppParameters.json", $WorkDir)
$JSON =Get-Content -Path $WorkParamPath  | ConvertFrom-JSON
$LogicAppsToBeDeployed = $JSON.LogicApps
$FileReaderParameters = $JSON.FileReader
$ServiceBusImportFOParameters = $JSON.ServiceBusImportFO
$AzureBlobImportFOParameters = $JSON.AzureBlobImportFO
$webserviceInboundParameters = $JSON.WebserviceInboundFO
$ServiceBusOutboundFileParameters = $JSON.ServiceBusOutboundFile
$AzureBlobOutboundFileParameters = $JSON.AzureBlobOutboundFile

#region helper functions

#region Inbound Logic App parameter function

#FileReader
function BuildFileReaderParameterFile{
param ($FileReaderParameter)
$FileReaderJsonTemplate = @'
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "fileAPIId": { "value": "" },
    "azureblobAPIId": { "value": "" },
    "servicebusAPIId": { "value": "" },
    "filesystem_rootfolder": {
      "value": ""
    },
    "IntegrationName": {"value": ""},
    "logicAppName": {
      "value": ""
    },
    "recurrence-frequency": { "value": "" },
    "recurrence-interval": { "value": "" },
    "azureblob_container": {
      "value": ""
    }
  }
}      
'@
$objects= $FileReaderJsonTemplate|ConvertFrom-Json 
$objects.parameters.azureblob_container.value = $FileReaderParameter.IntegrationName
$objects.parameters.fileAPIId.value = "norlys-erp-filelocal-{0}" -f $FileReaderParameter.Environment
$objects.parameters.azureblobAPIId.value = "norlys-erp-azureblob-{0}" -f $fileReaderParameter.Environment
$objects.parameters.IntegrationName.value = $FileReaderParameter.IntegrationName
$objects.parameters.servicebusAPIId.value = "norlys-erp-servicebus-{0}" -f $fileReaderParameter.Environment
$objects.parameters.filesystem_rootfolder.value = "{0}" -f $fileReaderParameter.RootFolder
$objects.parameters.logicAppName.value ="norlys-erp-filereader-{1}-{0}" -f $fileReaderParameter.Environment, $FileReaderParameter.IntegrationName
$objects.parameters.'recurrence-frequency'.value="{0}" -f $fileReaderParameter.'recurrence-frequency'
$objects.parameters.'recurrence-interval'.value="{0}" -f $fileReaderParameter.'recurrence-interval'

return  $objects|ConvertTo-Json -Depth 100
    #$FileReaderJson -f $fileReaderParameter.Environment, $fileReaderParameter.IntegrationName, $fileReaderParameter.RootFolder, $fileReaderParameter.'recurrence-frequency', $fileReaderParameter.'recurrence-interval'
}

#ServiceBus
function BuildServiceBusImportFOParameterFile{
param ($Parameter)

$ServiceBusImportFOParameterJsonTemplate = @'
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
    "dynamicsAXAPIId": { "value": "" },
    "servicebusAPIId": { "value": "" },
    "logicAppName": {"value": ""},
    "MessageType": { "value": "" },
    "D365FO_HOST": {"value": ""},
    "IntegrationName": {"value": ""},
    "recurrence-frequency": { "value": "" },
    "recurrence-interval": { "value": "" }
  }
}     
'@
$objects= $ServiceBusImportFOParameterJsonTemplate|ConvertFrom-Json 
$objects.parameters.dynamicsAXAPIId.value = "norlys-erp-dynamicsax-{0}" -f $Parameter.Environment
$objects.parameters.servicebusAPIId.value = "norlys-erp-servicebus-{0}" -f $Parameter.Environment
$objects.parameters.MessageType.value = $Parameter.MessageType
$objects.parameters.IntegrationName.value = $Parameter.IntegrationName
$objects.parameters.D365FO_HOST.value = $Parameter.D365FO
$objects.parameters.logicAppName.value ="norlys-erp-ServiceBusImportFO-{1}-{0}" -f $Parameter.Environment, $Parameter.IntegrationName
$objects.parameters.'recurrence-frequency'.value=$Parameter.'recurrence-frequency'
$objects.parameters.'recurrence-interval'.value=$Parameter.'recurrence-interval'

return  $objects|ConvertTo-Json -Depth 100

}

#AzureBLOB
function BuildAzureBLOBImportFOParameterFile{
param ($Parameter)

$AzureBlobImportFOParameterJsonTemplate = @'
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
    "dynamicsAXAPIId": { "value": "" },
    "azureblobAPIId": { "value": "" },
    "logicAppName": {"value": ""},
    "MessageType": { "value": "" },
    "azureblob_container": {"value": ""},
    "D365FO_HOST": {"value": ""},
    "IntegrationName": {"value": ""},
    "recurrence-frequency": { "value": "" },
    "recurrence-interval": { "value": "" }
    }
}     
'@
$objects= $AzureBlobImportFOParameterJsonTemplate|ConvertFrom-Json 
$objects.parameters.dynamicsAXAPIId.value = "norlys-erp-dynamicsax-{0}" -f $Parameter.Environment
$objects.parameters.azureblobAPIId.value = "norlys-erp-azureblob-{0}" -f $Parameter.Environment
$objects.parameters.MessageType.value = $Parameter.MessageType
$objects.parameters.IntegrationName.value = $Parameter.IntegrationName
$objects.parameters.azureblob_container.value = $Parameter.IntegrationName
$objects.parameters.D365FO_HOST.value = $Parameter.D365FO
$objects.parameters.logicAppName.value ="norlys-erp-AzureBlobImportFO-{1}-{0}" -f $Parameter.Environment, $Parameter.IntegrationName
$objects.parameters.'recurrence-frequency'.value=$Parameter.'recurrence-frequency'
$objects.parameters.'recurrence-interval'.value=$Parameter.'recurrence-interval'

return  $objects|ConvertTo-Json -Depth 100
}

#webserviceinbound
function BuildWebserviceinboundParameterFile{
param ($Parameter)
$JsonTemplate = @'
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "azureblobAPIId": { "value": "" },
    "servicebusAPIId": { "value": "" },
    "logicAppName": {
      "value": ""
    },
    "IntegrationName": {
      "value": ""
    }
  }
}      
'@
$objects= $JsonTemplate|ConvertFrom-Json 

$objects.parameters.azureblobAPIId.value = "norlys-erp-azureblob-{0}" -f $Parameter.Environment
$objects.parameters.IntegrationName.value = $Parameter.IntegrationName
$objects.parameters.servicebusAPIId.value = "norlys-erp-servicebus-{0}" -f $Parameter.Environment
$objects.parameters.logicAppName.value ="norlys-erp-webserviceFOInbound-{1}-{0}" -f $Parameter.Environment, $Parameter.IntegrationName

return  $objects|ConvertTo-Json -Depth 100
    #$FileReaderJson -f $fileReaderParameter.Environment, $fileReaderParameter.IntegrationName, $fileReaderParameter.RootFolder, $fileReaderParameter.'recurrence-frequency', $fileReaderParameter.'recurrence-interval'
}

#endregion

#region Outbound Logic App parameter functions

#region ServiceBus File Outbound

function BuildServiceBusOutboundParameterFile{
param ($Parameter)
$JsonTemplate = @'
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "filesystem_writefolder": {"value": ""},
    "fileAPIId": {"value": ""},
    "servicebusAPIId": { "value": "" },
    "logicAppName": {"value": ""},
    "MessageType": { "value": "" },
    "recurrence-frequency": { "value": "" },
    "recurrence-interval": { "value": "" },
    "azureblobAPIId": {"value": ""},
    "IntegrationName": {"value": ""},
    "azureblob_container": {"value": ""}
  }
}      
'@
$objects= $JsonTemplate|ConvertFrom-Json 


$objects.parameters.azureblobAPIId.value = "norlys-erp-azureblob-{0}" -f $Parameter.Environment
$objects.parameters.MessageType.value = $Parameter.MessageType
$objects.parameters.IntegrationName.value = $Parameter.IntegrationName
$objects.parameters.azureblob_container.value = $Parameter.IntegrationName
$objects.parameters.fileAPIId.value = "norlys-erp-filelocal-{0}" -f $FileReaderParameter.Environment
$objects.parameters.servicebusAPIId.value = "norlys-erp-servicebus-{0}" -f $fileReaderParameter.Environment
$objects.parameters.filesystem_writefolder.value = "{0}" -f $fileReaderParameter.WriteRootFolder
$objects.parameters.logicAppName.value ="norlys-erp-ServiceBusOutboundFile-{1}-{0}" -f $Parameter.Environment, $Parameter.IntegrationName
$objects.parameters.'recurrence-frequency'.value=$Parameter.'recurrence-frequency'
$objects.parameters.'recurrence-interval'.value=$Parameter.'recurrence-interval'
return  $objects|ConvertTo-Json -Depth 100
    #$FileReaderJson -f $fileReaderParameter.Environment, $fileReaderParameter.IntegrationName, $fileReaderParameter.RootFolder, $fileReaderParameter.'recurrence-frequency', $fileReaderParameter.'recurrence-interval'
}

#endregion

#region AzureBlob file outbound

function BuildAzureBlobOutboundParameterFile{
param ($Parameter)
$JsonTemplate = @'
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "filesystem_writefolder": {"value": ""},
    "fileAPIId": {"value": ""},    
    "logicAppName": {"value": ""},
    "MessageType": { "value": "" },
    "recurrence-frequency": { "value": "" },
    "recurrence-interval": { "value": "" },
    "azureblobAPIId": {"value": ""},
    "IntegrationName": {"value": ""},
    "azureblob_container": {"value": ""}
  }
}      
'@
$objects= $JsonTemplate|ConvertFrom-Json 


$objects.parameters.azureblobAPIId.value = "norlys-erp-azureblob-{0}" -f $Parameter.Environment
$objects.parameters.MessageType.value = $Parameter.MessageType
$objects.parameters.IntegrationName.value = $Parameter.IntegrationName
$objects.parameters.azureblob_container.value = $Parameter.IntegrationName
$objects.parameters.fileAPIId.value = "norlys-erp-filelocal-{0}" -f $FileReaderParameter.Environment

$objects.parameters.filesystem_writefolder.value = "{0}" -f $fileReaderParameter.WriteRootFolder
$objects.parameters.logicAppName.value ="norlys-erp-AzureBlobOutboundFile-{1}-{0}" -f $Parameter.Environment, $Parameter.IntegrationName
$objects.parameters.'recurrence-frequency'.value=$Parameter.'recurrence-frequency'
$objects.parameters.'recurrence-interval'.value=$Parameter.'recurrence-interval'
return  $objects|ConvertTo-Json -Depth 100
    #$FileReaderJson -f $fileReaderParameter.Environment, $fileReaderParameter.IntegrationName, $fileReaderParameter.RootFolder, $fileReaderParameter.'recurrence-frequency', $fileReaderParameter.'recurrence-interval'
}

#endregion

#endregion

#endregion

#region Main

#region inbound parameters

#region Filereader Parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'FileReader'}))
{
    #create integration subfolders
    $IntegrationDir = "{0}/{1}" -f $WorkDir,$LogicApp.IntegrationName 
    Write-Output 'checking for IntegrationName subdirectories'
    if (!(Test-Path $IntegrationDir)) { New-Item -ItemType Directory  -Path $IntegrationDir 
    Write-Output 'createded directorie' $IntegrationDir}
    
    $FileReaderParameter = $FileReaderParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')

    if($FileReaderParameter.Count -gt 0)
    {
        $FileReaderParametersPath  = "{0}\{1}\{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputFileReader =  BuildFileReaderParameterFile ($FileReaderParameter)| Out-File $FileReaderParametersPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
    
}
#endregion

#region servicebus parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'ServiceBusImportFO'}))
{
    $ServiceBusImportFOParameter = $ServiceBusImportFOParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')

    if($ServiceBusImportFOParameter.Count -gt 0)
    {
        $ServiceBusImportFOParametersPath  = "{0}/{1}/{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputServiceBusImportFO =  BuildServiceBusImportFOParameterFile ($ServiceBusImportFOParameter)| Out-File $ServiceBusImportFOParametersPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
}
#endregion

#region azureblob parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'AzureBlobImportFO'}))
{
    $AzureBlobImportFOParameter = $AzureBlobImportFOParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')
    if($AzureBlobImportFOParameter.Count -gt 0)
    {
        $AzureBlobImportFOParametersPath= "{0}/{1}/{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputAzureBlobImportFO =  BuildAzureBLOBImportFOParameterFile ($AzureBlobImportFOParameter)| Out-File $AzureBlobImportFOParametersPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
}
#endregion

#region webserviceFOInbound parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'WebserviceInboundFO'}))
{
    $webserviceInboundParameter = $webserviceInboundParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')

    if($webserviceInboundParameter.Count -gt 0)
    {
        $webserviceInboundParameterPath  = "{0}\{1}\{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputwebserviceInboundParameter =  BuildwebserviceInboundParameterFile ($webserviceInboundParameter)| Out-File $webserviceInboundParameterPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
    
}
#endregion

#endregion

#region outbound parameters

#region servicebus outbound file parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'ServiceBusOutboundFile'}))
{
    $ServiceBusOutboundFileParameter = $ServiceBusOutboundFileParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')

    if($ServiceBusOutboundFileParameter.Count -gt 0)
    {
        $ServiceBusOutboundFileParameterPath  = "{0}\{1}\{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputServiceBusOutboundFileParameter =  BuildServiceBusOutboundParameterFile ($ServiceBusOutboundFileParameter)| Out-File $ServiceBusOutboundFileParameterPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
    
}
#endregion

#region Azureblob outbound file parameters

foreach ($LogicApp in $LogicAppsToBeDeployed.Where({$_.LogicAppName -eq 'AzureBlobOutboundFile'}))
{
    $AzureBlobOutboundFileParameter = $AzureBlobOutboundFileParameters.Where({$_.Environment -eq $LogicApp.Environment -and $_.IntegrationName -eq $LogicApp.IntegrationName },'First')

    if($AzureBlobOutboundFileParameters.Count -gt 0)
    {
        $AzureBlobOutboundFileParameterPath  = "{0}\{1}\{2}" -f $WorkDir, $LogicApp.IntegrationName, $LogicApp.Filename
        $outputFileParameter =  BuildAzureBlobOutboundParameterFile ($AzureBlobOutboundFileParameter)| Out-File $AzureBlobOutboundFileParameterPath
    }
    else
    {
        $MyWarning= "No parameters found for Logic App:{0} for combination of Environment:{1} and IntegrationName:{2}" -f $LogicApp.LogicAppName, $LogicApp.Environment, $LogicApp.IntegrationName
        Write-Warning $MyWarning 
    } 
    
}
#endregion

#endregion

#endregion

