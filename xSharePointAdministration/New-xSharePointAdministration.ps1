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

New-xDscResource -Name ALIS_xFarmSolution -FriendlyName xFarmSolution -ModuleName xSharePointAdministration -Property @($Name, $Ensure, $LiteralPath, $Version, $WebAppa, $Deployed, $Local, $Force) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFarmSolution.psm1 -Destination "$modulePath\xSharePointAdministration\DSCResources\ALIS_xFarmSolution\ALIS_xFarmSolution.psm1" -Force

# Create List Resource
# Note: the system account needs permissions to create or delete the list. Make sure to add a plicy to your web application.
$Url         = New-xDscResourceProperty -Name Url             -Type String -Attribute Key   -Description "The absolute url of the list (i.e. http://localhost/web/lists/List1)."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String -Attribute Write -Description "Set this to 'Present' to ensure that the list is present. Set it to 'Absent' to ensure that the list is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Title       = New-xDscResourceProperty -Name Title           -Type String -Attribute Write -Description "The desired title of the list."
$Description = New-xDscResourceProperty -Name Description     -Type String -Attribute Write -Description "The desired description of the list."
$TemplateId  = New-xDscResourceProperty -Name TemplateId      -Type String -Attribute Write -Description "The template id of the list (default: 100)."
$FeatureId   = New-xDscResourceProperty -Name FeatureId       -Type String -Attribute Write -Description "A string that contains the ID of the Feature that defines the list."
$DocTemplate = New-xDscResourceProperty -Name DocTemplateType -Type String -Attribute Write -Description "A string that contains the integer ID for the document template type. Default: 101"

New-xDscResource -Name ALIS_xList -FriendlyName xList -ModuleName xSharePointAdministration -Property @($Url, $Ensure, $Title, $Description, $TemplateId, $FeatureId, $DocTemplate) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xList.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xList\ALIS_xList.psm1" -force


# Create Feature Resource
$ID      = New-xDscResourceProperty -Name ID      -Type String  -Attribute Key      -Description "The ID of the feature."
$Ensure  = New-xDscResourceProperty -Name Ensure  -Type String  -Attribute Write    -Description "Set this to 'Present' to ensure that the feature is actived. Set it to 'Absent' to ensure that the feature is deactivated. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Url     = New-xDscResourceProperty -Name Url     -Type String  -Attribute Required -Description "The url of the corresponding scope to activate the feature." 
$Force   = New-xDscResourceProperty -Name Force   -Type Boolean -Attribute Write    -Description "Set 'Force' to true to force the activation of the feature."  

New-xDscResource -Name ALIS_xFeature -FriendlyName xFeature -ModuleName xSharePointAdministration -Property @($ID, $Ensure, $Url, $Force) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFeature.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xFeature\ALIS_xFeature.psm1" -force

# Create Site Resource
$Url                = New-xDscResourceProperty -Name Url -Type String -Attribute Key -Description "The URL of the site."
$Ensure             = New-xDscResourceProperty -Name Ensure  -Type String  -Attribute Write    -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the site exists. Set it to 'Absent' to ensure that the site is deleted. Default is 'Present'."
$Owner              = New-xDscResourceProperty -Name OwnerAlias -Type String -Attribute Write -Description "The logon name of the owner of the site collection. The default is the service user of the wmi service."
$SiteType           = New-xDscResourceProperty -Name AdministrationSiteType -Type String -Attribute Write -ValidateSet @("None", "TenantAdministration") -Description "Specifies the site type."
$CompatibilityLevel = New-xDscResourceProperty -Name CompatibilityLevel -Type Sint32 -Attribute Write -Description "Specifies the version of templates to use when creating a new SPSite object. This value sets the initial CompatibilityLevel value for the site collection. The values for this parameter can be either 14 for SharePoint Server 2010 experience sites or 15 for SharePoint Server 2013 experience sites . When this parameter is not specified, the CompatibilityLevel will default to the highest possible version for the web application depending on the CompatibilityRange setting."
$ContentDatabase    = New-xDscResourceProperty -Name ContentDatabase -Type String -Attribute Write -Description "Specifies the name or GUID of the content database in which to create the new site. If no content database is specified, the site collection is selected automatically. The type must be a valid database name in the form, SiteContent1212, or a GUID in the form, 1234-5678-9807."
$Description        = New-xDscResourceProperty -Name Description -Type String -Attribute Write -Description "The desired description of the site."
$HostHeader         = New-xDscResourceProperty -Name HostHeaderWebApplication -Type String -Attribute Write -Description "Specifies that if the URL provided is a host header, the HostHeaderWebApplication parameter must be the name, URL or GUID for the web application in which this site collection is created. If no value is specified, the value is left blank. The type must be a valid name in one of the following forms: WebApplication-1212, a URL (for example, http://server_name) or a GUID (for example, 1234-5678-9876-0987)"
$Language           = New-xDscResourceProperty -Name Language -Type Uint32 -Attribute Write -Description "Specifies the language ID for the new site collection. If no language is specified, the site collection is created with the same language that was specified when the product was installed. This must be a valid language identifier (LCID)."
$Name               = New-xDscResourceProperty -Name Name -Type String -Attribute Write -Description "The desired title for the site collection."
$QuotaTemplate      = New-xDscResourceProperty -Name QuotaTemplate -Type String -Attribute Write -Description "Specifies the quota template for the new site. The template must exist already. If no template is specified, no quota is applied."
$SiteSubscription   = New-xDscResourceProperty -Name SiteSubscription -Type String -Attribute Write -Description "Specifies the Site Group to get site collections."
$Template           = New-xDscResourceProperty -Name Template -Type String -Attribute Write -Description "Specifies the Web template for the root web of the new site collection. The template must be already installed. If no template is specified, no template is provisioned."

New-xDscResource -Name ALIS_xSite -FriendlyName xSite -ModuleName xSharePointAdministration -Property @($Url, $Ensure, $Owner, $SiteType, $CompatibilityLevel, $ContentDatabase, $Description, $HostHeader, $Language, $Name, $QuotaTemplate, $SiteSubscription, $Template) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xSite.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xSite\ALIS_xSite.psm1"

# Create Web Resource
$Url                = New-xDscResourceProperty -Name Url -Type String -Attribute Key -Description "The URL of the web site."
$Ensure             = New-xDscResourceProperty -Name Ensure  -Type String  -Attribute Write    -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the web site exists. Set it to 'Absent' to ensure that the web site is deleted. Default is 'Present'."
$Description        = New-xDscResourceProperty -Name Description -Type String -Attribute Write -Description "The desired description of the web site."
$Language           = New-xDscResourceProperty -Name Language -Type Uint32 -Attribute Write -Description "The desired language (LCID) of the web site."
$Name               = New-xDscResourceProperty -Name Name -Type String -Attribute Write -Description "The desired title of the web site."
$Template           = New-xDscResourceProperty -Name Template -Type String -Attribute Write -Description "The template for the web site (i.e. STS#0 for Team Site)"
$UniquePermissions  = New-xDscResourceProperty -Name UniquePermissions -Type Boolean -Attribute Write -Description "True to break permission inheritance; otherwise false."
$UseParentTopNav    = New-xDscResourceProperty -Name UseParentTopNav -Type Boolean -Attribute Write -Description "True to use the parent top navigation; otherwise false."
$AddToQuickLaunch   = New-xDscResourceProperty -Name AddToQuickLaunch -Type Boolean -Attribute Write -Description "True to add the web site to the quicklaunch; otherwise false."
$AddToTopNav        = New-xDscResourceProperty -Name AddToTopNav -Type Boolean -Attribute Write -Description "True to add the web site to the top navigation; otherwise false."

New-xDscResource -Name ALIS_xWeb -FriendlyName xWeb -ModuleName xSharePointAdministration -Property @($Url, $Ensure, $Description, $Name, $Language, $Template, $UniquePermissions, $UseParentTopNav, $AddToQuickLaunch, $AddToTopNav) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xWeb.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xWeb\ALIS_xWeb.psm1"

# Create User Profile Property Resource
# Note: make sure your system account has administrative priviledges on your user profile service!
$Name               = New-xDscResourceProperty -Name Name           -Type String -Attribute Key -Description "The internal name of the profile proprty."
$Ensure             = New-xDscResourceProperty -Name Ensure         -Type String -Attribute Write -ValidateSet @("Present", "Absent") -Description "Set this to 'Present' to ensure that the profile property exists. Set it to 'Absent' to ensure that it is deleted. Default is 'Present'."
$ConnectionName     = New-xDscResourceProperty -Name ConnectionName -Type String -Attribute Write -Description "The name of the ad synch connection"
$AttributeName      = New-xDscResourceProperty -Name AttributeName  -Type String -Attribute Write -Description "The name of the mapped attribute in active directory."
$DisplayName        = New-xDscResourceProperty -Name DisplayName    -Type String -Attribute Write
$PropertyType       = New-xDscResourceProperty -Name PropertyType   -Type String -Attribute Write -ValidateSet @("Binary", "Boolean", "Currency", "DateTime", "Double", "Integer", "LongBinary", "LongString", "Short", "Single", "String", "Variant")
$Privacy            = New-xDscResourceProperty -Name Privacy        -Type String -Attribute Write -ValidateSet @("Public", "Contacts", "Organization", "Manager", "Private", "NotSet")
$PrivacyPolicy      = New-xDscResourceProperty -Name PrivacyPolicy  -Type String -Attribute Write -ValidateSet @("mandatory", "optin", "optout", "disabled")
$PropertyLength     = New-xDscResourceProperty -Name PropertyLength -Type Sint32 -Attribute Write
$IsUserEditable     = New-xDscResourceProperty -Name IsUserEditable      -Type Boolean -Attribute Write
$IsVisibleOnEditor  = New-xDscResourceProperty -Name IsVisibleOnEditor   -Type Boolean -Attribute Write
$IsVisibleOnViewer  = New-xDscResourceProperty -Name IsVisibleOnViewer   -Type Boolean -Attribute Write
$IsEventLog         = New-xDscResourceProperty -Name IsEventLog          -Type Boolean -Attribute Write
$UserOverridePrivacy= New-xDscResourceProperty -Name UserOverridePrivacy -Type Boolean -Attribute Write
$DisplayOrder       = New-xDscResourceProperty -Name DisplayOrder        -Type Sint32 -Attribute Write
$Section            = New-xDscResourceProperty -Name Section             -Type String -Attribute Write
$IsMultivalued      = New-xDscResourceProperty -Name IsMultivalued       -Type Boolean -Attribute Write
$Separator          = New-xDscResourceProperty -Name Separator           -Type String -Attribute Write -ValidateSet @("Comma", "Semicolon", "Newline", "Unknown")
$MaximumShown       = New-xDscResourceProperty -Name MaximumShown        -Type Sint32 -Attribute Write


$properties = @($Name, $Ensure, $ConnectionName, $AttributeName, $DisplayName, $PropertyType, $Privacy, $PrivacyPolicy, $PropertyLength, $IsUserEditable, $IsVisibleOnEditor, $IsVisibleOnViewer, $IsEventLog, $UserOverridePrivacy, $DisplayOrder, $Section, $IsMultivalued, $Separator, $MaximumShown)
New-xDscResource -Name ALIS_xUserProfileProperty -FriendlyName xUserProfileProperty -ModuleName xSharePointAdministration -Property $properties  -Path $modulePath

Copy-Item .\DSCResources\ALIS_xUserProfileProperty.psm1 "$modulePath\xSharePointAdministration\DSCResources\ALIS_xUserProfileProperty\ALIS_xUserProfileProperty.psm1"

#Get-DscResource -Name xFarmSolution
#Get-DscResource -Name xList 
#Get-DscResource -Name xFeature
#Get-DscResource -Name xSite
#Get-DscResource -Name xWeb

#Test-xDscResource -Name xFarmSolution -Verbose
#Test-xDscResource -Name xList -Verbose
#Test-xDscResource -Name xFeature -Verbose
#Test-xDscResource -Name xWeb -Verbose
#Test-xDscResource -Name xSite -Verbose
#Test-xDscResource -Name xUserProfileProperty -Verbose

copy-item .\xSharePointAdministration.psd1 "$modulePath\xSharePointAdministration\xSharePointAdministration.psd1"