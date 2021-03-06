function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {

        $site = $gc | Get-SPSite -Limit 1 -WarningAction SilentlyContinue
        $context = [Microsoft.SharePoint.SPServiceContext]::GetContext($site);  

        if (!$context)
        {
            Throw-TerminatingError -errorId "ContextNull" -errorMessage "The server context could not be loaded."
        }

        $UPAConfMgr = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

        if (!$UPAConfMgr)
        {
            Throw-TerminatingError -errorId "UserProfileConfigManagerNull" -errorMessage "The UserProfileConfigManager could not be loaded."
        }

        $UPAConnMgr = $UPAConfMgr.ConnectionManager
        $userprofiletype = [Microsoft.Office.Server.UserProfiles.ProfileType]::User
        $CurrentConnection = $UPAConnMgr | where {$_.AccountDomain -eq $ConnectionDomain}
        $PropertyMapping = $CurrentConnection.PropertyMapping

        $userProfilePropertyManager = $UPAConfMgr.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties($userprofiletype)

        #Creating core properties
        $CoreProperties = $UPAConfMgr.ProfilePropertyManager.GetCoreProperties()                              

        $profile = $CoreProperties.GetPropertyByName($Name)

        if ($profile)
        {
            $ensure = "Present"
            $displayName = $profile.DisplayName
            $type   = $profile.Type
            $length = $profile.Length
            $isMultivalued = $profile.IsMultivalued
            $separator = $profile.Separator

            $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
            $userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName($userprofiletype))
            $userProfileProperties = $userProfile.Properties                                                  

            $Property = $userProfileProperties.GetPropertyByName($Name)

            $privacy = $Property.DefaultPrivacy
            $policy = $Property.PrivacyPolicy
            $editable = $property.IsUserEditable
            $order = $Property.DisplayOrder
            $override =  $property.UserOverridePrivacy
            

            $ProfileTypeProperty = $userProfileTypeProperties.GetPropertyByName($Name)

            $v1 = $ProfileTypeProperty.IsVisibleOnEditor
            $v2 = $ProfileTypeProperty.IsVisibleOnViewer
            $v3 = $ProfileTypeProperty.IsEventLog
            $MaximumShown = $ProfileTypeProperty.MaximumShown

            $section = ""

            foreach ($profileSubtypeProperty in $userProfile.PropertiesWithSection)
            {
                if ($profileSubtypeProperty.IsSection)
                {
                    $sec = $profileSubtypeProperty
                    $section = $profileSubtypeProperty.Name
                }

                if ($profileSubtypeProperty.Name -eq $Name)
                {
                    break
                }
            }

            if ($sec)
            {
                $order = $sec.DisplayOrder + $Property.DisplayOrder
            }
        }
        else
        {
            $ensure = "Absent"
            $displayName = ""
            $type   = ""
            $privacy = "NotSet"
            $policy = "disabled"
            $editable = $false
            $order = 0
            $override = $false
            $length = 0
            $v1 = $false
            $v2 = $false
            $v3 = $false
            $section = ""
            $isMultivalued = $false
            $separator = "Unknown"
            $maximumShown = 1
        }

	    $returnValue = @{
		    Name = $Name
		    Ensure = $ensure
		    ConnectionName = $CurrentConnection.DisplayName
		    AttributeName = ""
		    DisplayName = $displayName
		    PropertyType = $type
		    Privacy = $privacy
		    PrivacyPolicy = $policy
		    PropertyLength = $length
		    IsUserEditable = $editable
		    IsVisibleOnEditor = $v1
		    IsVisibleOnViewer = $v2
		    IsEventLog = $v3
		    UserOverridePrivacy = $override
		    DisplayOrder = $order
		    Section = $section
            IsMultivalued = $isMultivalued
            Separator = $separator
            MaximumShown = $maximumShown
	    }

	    $returnValue
    }
    finally
    {
        Stop-SPAssignment $gc -Verbose:$false

        Release-PSSnapin
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$ConnectionName,

		[System.String]
		$AttributeName,

		[System.String]
		$DisplayName,

		[ValidateSet("Binary","Boolean","Currency","DateTime","Double","Integer","LongBinary","LongString","Short","Single","String","Variant")]
		[System.String]
		$PropertyType = "String",

		[ValidateSet("Public","Contacts","Organization","Manager","Private","NotSet")]
		[System.String]
		$Privacy = "Private",

		[ValidateSet("mandatory","optin","optout","disabled")]
		[System.String]
		$PrivacyPolicy = "optout",

		[System.Int32]
		$PropertyLength = 25,

		[System.Boolean]
		$IsUserEditable = $false,

		[System.Boolean]
		$IsVisibleOnEditor = $false,

		[System.Boolean]
		$IsVisibleOnViewer = $false,

		[System.Boolean]
		$IsEventLog = $false,

		[System.Boolean]
		$UserOverridePrivacy = $false,

		[System.Int32]
		$DisplayOrder = 0,

		[System.String]
		$Section = "SPS-Section-CustomProperties",

        [System.Boolean]
		$IsMultivalued = $false,

		[ValidateSet("Comma","Semicolon","Newline","Unknown")]
		[System.String]
		$Separator = "Comma",

		[System.Int32]
		$MaximumShown = 1
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {

        $site = $gc | Get-SPSite -Limit 1 -WarningAction SilentlyContinue
        $context = [Microsoft.SharePoint.SPServiceContext]::GetContext($site);  

        if (!$context)
        {
            Throw-TerminatingError -errorId "ContextNull" -errorMessage "The server context could not be loaded."
        }

        $UPAConfMgr = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

        if (!$UPAConfMgr)
        {
            Throw-TerminatingError -errorId "UserProfileConfigManagerNull" -errorMessage "The UserProfileConfigManager could not be loaded."
        }

        $UPAConnMgr = $UPAConfMgr.ConnectionManager
        $userprofiletype = [Microsoft.Office.Server.UserProfiles.ProfileType]::User
        $CurrentConnection = $UPAConnMgr | where {$_.AccountDomain -eq $ConnectionDomain}
        $PropertyMapping = $CurrentConnection.PropertyMapping

        $userProfilePropertyManager = $UPAConfMgr.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties($userprofiletype)

        #get core properties
        $CoreProperties = $UPAConfMgr.ProfilePropertyManager.GetCoreProperties()       
        
        if ($Ensure -eq "Absent")
        {
            Write-Verbose "Remove property '$Name' because Ensure is 'Absent'."
            $CoreProperties.RemovePropertyByName($Name)
        }
        else
        {
            $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
            $userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName($userprofiletype))
            $userProfileProperties = $userProfile.Properties

            #$userProfileProperties
                                                           
            $sec = $userProfileProperties.GetSectionByName($Section);

            $NewUPProperty = $userProfileProperties.GetPropertyByName($Name)

            if (-not $DisplayName)
            {
                $DisplayName = $Name
            }

            if($NewUPProperty -eq $null)
            {
                Write-Verbose "Create property '$Name'..."

                #Creating a NewProperty with basic attributes
                $NewProperty = $CoreProperties.Create($false)
                $Newproperty.Name = $Name
                $NewProperty.DisplayName = $DisplayName
                $NewProperty.Type = $PropertyType
                $NewProperty.Length = $PropertyLength
                $NewProperty.IsMultivalued = $IsMultivalued
                $NewProperty.Separator = $Separator

                #Adding the new property to the core properties list
                $CoreProperties.Add($NewProperty)

                #Reinitializing the newly created property to change secondary attributes.
                $NewTypeProperty = $userProfileTypeProperties.Create($NewProperty)                                                                

                #Display attributes
                $NewTypeProperty.IsVisibleOnEditor = $IsVisibleOnEditor
                $NewTypeProperty.IsVisibleOnViewer = $IsVisibleOnViewer
                $NewTypeProperty.IsEventLog = $IsEventLog
                $NewTypeProperty.MaximumShown = $MaximumShown

                #Updating the new property's secondary attributes
                $userProfileTypeProperties.Add($NewTypeProperty)

                #Reinicializing the newly created property to privacy attributes.
                $NewSubProperty = $userProfileProperties.Create($NewTypeProperty)
                $NewSubProperty.DefaultPrivacy = [Microsoft.Office.Server.UserProfiles.Privacy]::$Privacy
                $NewSubProperty.PrivacyPolicy = [Microsoft.Office.Server.UserProfiles.PrivacyPolicy]::$PrivacyPolicy 

                $NewSubProperty.IsUserEditable = $IsUserEditable

                $NewSubProperty.UserOverridePrivacy = $UserOverridePrivacy

                #Finalizing the new property.
                $userProfileProperties.Add($NewSubProperty)

                if ($ConnectionName -and $AttributeName)
                {
                    #Add New Mapping for synchronization user profile data
                    $synchConnection = $UPAConfMgr.ConnectionManager[$ConnectionName]

                    if ($synchConnection.Type -eq "ActiveDirectoryImport"){
                        $synchConnection.AddPropertyMapping($AttributeName,$Name)
                        $synchConnection.Update()
                    }
                    else
                    {
                        $synchConnection.PropertyMapping.AddNewMapping([Microsoft.Office.Server.UserProfiles.ProfileType]::User,$Name,$AttributeName)
                    }
                }

                Write-Verbose "Property $Name successfully created."
            }
            else
            {
                Write-Verbose "Update property '$Name'..."

                if ($NewUPProperty.CoreProperty.DisplayName -ne $DisplayName)
                {
                    Write-Verbose "The display name '$($NewUPProperty.CoreProperty.DisplayName)' does not match the desired state '$DisplayName' and will be updated."
                    $NewUPProperty.CoreProperty.DisplayName = $DisplayName   
                }

                $NewUPTypeProperty = $userProfileTypeProperties.GetPropertyByName($Name)


                $NewUPTypeProperty.IsVisibleOnViewer = $IsVisibleOnViewer
                $NewUPTypeProperty.IsVisibleOnEditor = $IsVisibleOnEditor
                $NewUPTypeProperty.IsEventLog = $IsEventLog
                $NewUPTypeProperty.MaximumShown = $MaximumShown

                $NewUPProperty.DefaultPrivacy = [Microsoft.Office.Server.UserProfiles.Privacy]::$Privacy
                $NewUPProperty.PrivacyPolicy = [Microsoft.Office.Server.UserProfiles.PrivacyPolicy]::$PrivacyPolicy 

                $NewUPProperty.IsUserEditable = $IsUserEditable                                                                
                $NewUPProperty.UserOverridePrivacy = $UserOverridePrivacy

                $NewUPTypeProperty.CoreProperty.Commit()
                $NewUPProperty.Commit()
                $NewUPTypeProperty.Commit()

            }

            #Setting the display order
            if($DisplayOrder -ne "0")
            {
                $newOrder = $sec.DisplayOrder + $DisplayOrder
                Write-Verbose "Set display order for property to $newOrder (Section: $($sec.DisplayOrder) and Property: $DisplayOrder)"
                $userProfileProperties.SetDisplayOrderByPropertyName($Name, $newOrder)                                                   
            }
        }
    }
    finally
    {
        Stop-SPAssignment $gc -Verbose:$false

        Release-PSSnapin
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$ConnectionName,

		[System.String]
		$AttributeName,

		[System.String]
		$DisplayName,

		[ValidateSet("Binary","Boolean","Currency","DateTime","Double","Integer","LongBinary","LongString","Short","Single","String","Variant")]
		[System.String]
		$PropertyType = "String",

		[ValidateSet("Public","Contacts","Organization","Manager","Private","NotSet")]
		[System.String]
		$Privacy = "Private",

		[ValidateSet("mandatory","optin","optout","disabled")]
		[System.String]
		$PrivacyPolicy = "optout",

		[System.Int32]
		$PropertyLength = 25,

		[System.Boolean]
		$IsUserEditable = $false,

		[System.Boolean]
		$IsVisibleOnEditor = $false,

		[System.Boolean]
		$IsVisibleOnViewer = $false,

		[System.Boolean]
		$IsEventLog = $false,

		[System.Boolean]
		$UserOverridePrivacy = $false,

		[System.Int32]
		$DisplayOrder = 0,

		[System.String]
		$Section = "SPS-Section-CustomProperties",

        [System.Boolean]
		$IsMultivalued = $false,

		[ValidateSet("Comma","Semicolon","Newline","Unknown")]
		[System.String]
		$Separator = "Comma",

		[System.Int32]
		$MaximumShown = 1
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {

        $site = $gc | Get-SPSite -Limit 1 -WarningAction SilentlyContinue
        $context = [Microsoft.SharePoint.SPServiceContext]::GetContext($site);  

        if (!$context)
        {
            Throw-TerminatingError -errorId "ContextNull" -errorMessage "The server context could not be loaded."
        }

        $UPAConfMgr = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

        if (!$UPAConfMgr)
        {
            Throw-TerminatingError -errorId "UserProfileConfigManagerNull" -errorMessage "The UserProfileConfigManager could not be loaded."
        }

        $UPAConnMgr = $UPAConfMgr.ConnectionManager
        $userprofiletype = [Microsoft.Office.Server.UserProfiles.ProfileType]::User
        $CurrentConnection = $UPAConnMgr | where {$_.AccountDomain -eq $ConnectionDomain}
        $PropertyMapping = $CurrentConnection.PropertyMapping

        $userProfilePropertyManager = $UPAConfMgr.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties($userprofiletype)

        #get core properties
        $CoreProperties = $UPAConfMgr.ProfilePropertyManager.GetCoreProperties()
        
        $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
        $userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName($userprofiletype))
        $userProfileProperties = $userProfile.Properties
                                                           
        $sec = $userProfileProperties.GetSectionByName($Section);

        $profile = $userProfileProperties.GetPropertyByName($Name)       
        
        if ($profile -eq $null)
        {
            if ($Ensure -eq "Absent")
            {
                Write-Verbose "The ensure state 'Absent' does match the desired state 'Absent'."
                return $true
            }
            else
            {
                Write-Verbose "The ensure state 'Absent' does not match the desired state 'Present'."
                return $false
            }
        }
        else
        {
            if ($Ensure -eq "Absent")
            {
                Write-Verbose "The ensure state 'Present' does match the desired state 'Absent'."
                return $false
            }

            if ($DisplayName)
            {
                if ($DisplayName -ne $profile.DisplayName)
                {
                    Write-Verbose "The display name '$($profile.DisplayName)' does not match the desired display name '$DisplayName'."
                    return $false
                }
            }

            if ($IsMultivalued -ne $profile.CoreProperty.IsMultivalued)
            {
                Write-Verbose "The value of property 'IsMultivalued' is '$($profile.CoreProperty.IsMultivalued)' and does not match the desired state '$IsMultivalued'."
                return $false
            }

            if ($Separator -ne $profile.CoreProperty.Separator)
            {
                Write-Verbose "The value of property 'Separator' is '$($profile.CoreProperty.Separator)' and does not match the desired state '$Separator'."
                return $false
            }

            $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
            $userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName($userprofiletype))
            $userProfileProperties = $userProfile.Properties                                                  

            $Property = $userProfileProperties.GetPropertyByName($Name)

            if ($Privacy -ne $Property.DefaultPrivacy)
            {
                Write-Verbose "The value of property 'DefaultPrivacy' is '$($Property.DefaultPrivacy)' and does not match the desired state '$Privacy'."
                return $false
            }

            if ($PrivacyPolicy -ne $Property.PrivacyPolicy)
            {
                Write-Verbose "The value property 'PrivacyPolicy' is '$($Property.PrivacyPolicy)' and does not match the desired state '$PrivacyPolicy'."
                return $false
            }

            if ($IsUserEditable -ne $property.IsUserEditable)
            {
                Write-Verbose "The value of property 'IsUserEditable' is '$($property.IsUserEditable)' and does not match the desired state '$IsUserEditable'."
                return $false
            }

            if ($DisplayOrder -ne 0)
            {
                if ($DisplayOrder -ne $Property.DisplayOrder)
                {
                    Write-Verbose "The value of property 'DisplayOrder' is '$($Property.DisplayOrder)' and does not match the desired state '$DisplayOrder'."
                    return $false
                }
            }

            if ($UserOverridePrivacy -ne $property.UserOverridePrivacy)
            {
                Write-Verbose "The value of property 'UserOverridePrivacy' is '$($property.UserOverridePrivacy)' and does not match the desired state '$UserOverridePrivacy'."
                return $false
            }

            $ProfileTypeProperty = $userProfileTypeProperties.GetPropertyByName($Name)

            if ($IsVisibleOnEditor -ne $ProfileTypeProperty.IsVisibleOnEditor)
            {
                Write-Verbose "The value of property 'IsVisibleOnEditor' is '$($ProfileTypeProperty.IsVisibleOnEditor)' and does not match the desired state '$IsVisibleOnEditor'."
                return $false
            }

            if ($IsVisibleOnEditor -ne $ProfileTypeProperty.IsVisibleOnEditor)
            {
                Write-Verbose "The value of property 'IsVisibleOnEditor' is '$($ProfileTypeProperty.IsVisibleOnEditor)' and does not match the desired state '$IsVisibleOnEditor'."
                return $false
            }

            if ($IsVisibleOnViewer -ne $ProfileTypeProperty.IsVisibleOnViewer)
            {
                Write-Verbose "The value of property 'IsVisibleOnViewer' is '$($ProfileTypeProperty.IsVisibleOnViewer)' and does not match the desired state '$IsVisibleOnViewer'."
                return $false
            }

            if ($IsEventLog -ne $ProfileTypeProperty.IsEventLog)
            {
                Write-Verbose "The value of property 'IsEventLog' is '$($ProfileTypeProperty.IsEventLog)' and does not match the desired state '$IsEventLog'."
                return $false
            }  
            
            if ($MaximumShown -ne $ProfileTypeProperty.MaximumShown)
            {
                Write-Verbose "The value of property 'MaximumShown' is '$($ProfileTypeProperty.MaximumShown)' and does not match the desired state '$MaximumShown'."
                return $false
            }     
        }

        return $true
    }
    finally
    {
        Stop-SPAssignment $gc -Verbose:$false

        Release-PSSnapin
    }
}


function Ensure-PSSnapin
{
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
    {
        Add-PSSnapin "Microsoft.SharePoint.PowerShell" -Verbose:$false
        Write-Verbose "SharePoint Powershell Snapin loaded."
    } 

    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")  
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles")  
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles.UserProfileManager")  
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")  
}

function Release-PSSnapin
{
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -ne $null) 
    {
        Remove-PSSnapin "Microsoft.SharePoint.PowerShell" -Verbose:$false
        Write-Verbose "SharePoint Powershell Snapin removed."
    } 
}

function Throw-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [string]$errorId,
        [string]$errorMessage,
        [System.Management.Automation.ErrorCategory]$errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
    )

    $exception = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

    $PSCmdlet.ThrowTerminatingError($errorRecord);
}

Export-ModuleMember -Function *-TargetResource

