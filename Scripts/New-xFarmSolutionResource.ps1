$Name = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "The name of the farm solution (i.e. mysolution.wsp)."
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the solution is deployed. Set it to 'Absent' to ensure that the solution is retracted and removed from the farm."
$LiteralPath = New-xDscResourceProperty -Name LiteralPath -Type String -Attribute Required -Description "The path to the solution in the drop folder or file system."
$Version = New-xDscResourceProperty -Name Version -Type String -Attribute Write -Verbose "The version of the assembly (default is '1.0')." 
$WebAppa = New-xDscResourceProperty -Name WebApplications -Type String[] -Attribute Write -Description "One or more URL's of web application that the solution is deployed to. Leave empty to deploy to all web applications."
$Deployed = New-xDscResourceProperty -Name Deployed -Type Boolean -Attribute Write -Description "Default 'true'. Set this to 'false' to retract the solution but not remove it from the store."
$Local = New-xDscResourceProperty -Name Local -Type Boolean -Attribute Write -Description "Set 'Local' to true if you only deploy the solution on a single server."
$Force = New-xDscResourceProperty -Name Force -Type Boolean -Attribute Write -Description "Set 'Force' to true to force the deployment in case of errors. Be careful with this switch!"

New-xDscResource -Name ALIS_xFarmSolution -FriendlyName FarmSolution -ModuleName xSharePointAdministration -Property @($Name, $Ensure, $LiteralPath, $Version, $WebAppa, $Deployed, $Local, $Force) -Path 'C:\Program Files\WindowsPowerShell\Modules'