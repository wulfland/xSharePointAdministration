$modulePath = 'C:\Program Files\WindowsPowerShell\Modules'

# Delete module...
Remove-Item -Path "$modulePath\xSharePointAdministration" -Force -Recurse 

# Create Farm Solution Resource
$Name        = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "The name of the farm solution (i.e. mysolution.wsp)."
$Ensure      = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the solution is deployed. Set it to 'Absent' to ensure that the solution is retracted and removed from the farm."
$LiteralPath = New-xDscResourceProperty -Name LiteralPath -Type String -Attribute Required -Description "The path to the solution in the drop folder or file system."
$Version     = New-xDscResourceProperty -Name Version -Type String -Attribute Write -Description "The version of the assembly (default is '1.0')." 
$WebAppa     = New-xDscResourceProperty -Name WebApplications -Type String[] -Attribute Write -Description "One or more URL's of web application that the solution is deployed to. Leave empty to deploy to all web applications."
$Deployed    = New-xDscResourceProperty -Name Deployed -Type Boolean -Attribute Write -Description "Default 'true'. Set this to 'false' to retract the solution but not remove it from the store."
$Local       = New-xDscResourceProperty -Name Local -Type Boolean -Attribute Write -Description "Set 'Local' to true if you only deploy the solution on a single server."
$Force       = New-xDscResourceProperty -Name Force -Type Boolean -Attribute Write -Description "Set 'Force' to true to force the deployment in case of errors. Be careful with this switch!"

New-xDscResource -Name ALIS_xFarmSolution -FriendlyName FarmSolution -ModuleName xSharePointAdministration -Property @($Name, $Ensure, $LiteralPath, $Version, $WebAppa, $Deployed, $Local, $Force) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFarmSolution.psm1 -Destination "$modulePath\xSharePointAdministration\DSCResources\ALIS_xFarmSolution\ALIS_xFarmSolution.psm1"

# Create List Resource
$Title       = New-xDscResourceProperty -Name Title -Type String -Attribute Key -Description "The title of the list."
$Ensure      = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the solution is deployed. Set it to 'Absent' to ensure that the solution is retracted and removed from the farm."
$Url         = New-xDscResourceProperty -Name Url -Type String -Attribute Required -Description "The absolute url of the list (i.e. http://localhost/web/lists/Lis1)."
$TemplateId  = New-xDscResourceProperty -Name TemplateId -Type String -Attribute Write

New-xDscResource -Name ALIS_xList -FriendlyName List -ModuleName xSharePointAdministration -Property @($Title, $Ensure, $Url, $TemplateId) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFarmSolution.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xFarmSolution\ALIS_xFarmSolution.psm1" -force


# Create Feature Resource
$ID      = New-xDscResourceProperty -Name ID      -Type String  -Attribute Key      -Description "The ID of the feature."
$Ensure  = New-xDscResourceProperty -Name Ensure  -Type String  -Attribute Write    -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the feature is actived. Set it to 'Absent' to ensure that the feature is deactivated."
$Url     = New-xDscResourceProperty -Name Url     -Type String  -Attribute Required -Description "The url of the corresponding scope to activate the feature." 
$Force   = New-xDscResourceProperty -Name Force   -Type Boolean -Attribute Write    -Description "Set 'Force' to true to force the activation of the feature."  
$Version = New-xDscResourceProperty -Name Version -Type String  -Attribute Read
$Scope  = New-xDscResourceProperty  -Name xScope -Type String  -Attribute Read -ValidateSet @("Web", "Site", "WebApplication", "Farm")

New-xDscResource -Name ALIS_xFeature -FriendlyName Feature -ModuleName xSharePointAdministration -Property @($ID, $Ensure, $Url, $Force, $Version, $Scope) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFeature.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xFeature\ALIS_xFeature.psm1" -force

Get-DscResource -Name FarmSolution
Get-DscResource -Name List 
Get-DscResource -Name Feature

copy-item .\xSharePointAdministration.psd1 "$modulePath\xSharePointAdministration\xSharePointAdministration.psd1"