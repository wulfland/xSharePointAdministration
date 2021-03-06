function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ID,

		[parameter(Mandatory = $true)]
		[System.String]
		$Url
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        # get the installed feature
        $feature = $gc | Get-SPFeature $ID -ErrorAction SilentlyContinue -Verbose:$false

        $ensureResult = "Absent"
        $idResult = $ID
        $scopeResult = $null
        $versionResult = $null

        if ($feature -ne $null)
        {
            $idResult = $feature.Id
            $scopeResult = $feature.Scope

            # Check if the feature is installed at the specified scope
            $check = $null
            switch($feature.Scope)
            {
                "Farm"           { $check = Get-SPFeature $Id -Farm                -ErrorAction SilentlyContinue -Verbose:$false }
                "WebApplication" { $check = Get-SPFeature $Id -WebApplication $Url -ErrorAction SilentlyContinue -Verbose:$false }
                "Site"           { $check = Get-SPFeature $Id -Site $Url           -ErrorAction SilentlyContinue -Verbose:$false }
                "Web"            { $check = Get-SPFeature $Id -Web $Url            -ErrorAction SilentlyContinue -Verbose:$false }
            }
             
            if ($check -ne $null)
            {

                $ensureResult = "Present"
                $versionResult = $check.Version
            }
        }
	    
	    $result = @{
		    ID = $idResult
		    Ensure = $ensureResult
		    Url = $url
		    Scope = $scopeResult
		    Version = $versionResult
	    } 

        $result
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
		$ID,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[System.Boolean]
		$Force = $false
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        # get the installed feature
        $feature = $gc | Get-SPFeature $ID -ErrorAction SilentlyContinue -Verbose:$false

        if ($feature -eq $null)
        {
            if ($Ensure -eq "Present")
            {
                Install-SPFeature -AllExistingFeatures
            }
            else
            {
                Write-Verbose "Feature is in desired state 'Absent'."
                return
            }
        }

        $feature = $gc | Get-SPFeature $ID -ErrorAction SilentlyContinue -Verbose:$false

        if ($feature -eq $null)
        {
            Throw-TerminatingError -errorId "FeatureNotFound" -errorMessage "A feature with the ID '$Id' could not be found. Are you're missing a solution?" -errorCategory NotInstalled
        }
        else
        {
            # Check if the feature is installed at the specified scope
            $check = $null
            switch($feature.Scope)
            {
                "Farm"           { $check = Get-SPFeature $Id -Farm                -ErrorAction SilentlyContinue -Verbose:$false }
                "WebApplication" { $check = Get-SPFeature $Id -WebApplication $Url -ErrorAction SilentlyContinue -Verbose:$false }
                "Site"           { $check = Get-SPFeature $Id -Site $Url           -ErrorAction SilentlyContinue -Verbose:$false }
                "Web"            { $check = Get-SPFeature $Id -Web $Url            -ErrorAction SilentlyContinue -Verbose:$false }
            }
             
            if ($check -eq $null)
            {
                if ($Ensure -eq "Present")
                {
                    if ($feature.Scope -eq "Farm")
                    {
                        Enable-SPFeature $Id -Force:$Force -AssignmentCollection $gc
                        Write-Verbose "The feature '$Id' was enabled in the farm."
                        return
                    }
                    else
                    {
                        Enable-SPFeature $Id -Url $Url -Force:$Force -AssignmentCollection $gc
                        Write-Verbose "The feature '$Id' was enabled in '$Url'."
                        return
                    }
                }
            }
            else
            {
                if ($Ensure -eq "Absent")
                {
                    if ($feature.Scope -eq "Farm")
                    {
                        Disable-SPFeature $Id -Force:$Force -AssignmentCollection $gc
                        Write-Verbose "The feature '$Id' was disabled in the farm."
                        return
                    }
                    else
                    {
                        Disable-SPFeature $Id -Url $Url -Force:$Force -AssignmentCollection $gc
                        Write-Verbose "The feature '$Id' was disabled in '$Url'."
                        return
                    }
                }   

                if ($check.Version -ne $feature.Version)
                {
                    $check.Upgrade($false)
                    Write-Verbose "The feature '$ID' was upgraded from '$($check.Version)' to '$($feature.Version)'."
                    return
                }
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
		$ID,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[System.Boolean]
		$Force = $false
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        # get the installed feature
        $feature = $gc | Get-SPFeature $ID -ErrorAction SilentlyContinue -Verbose:$false

        if ($feature -eq $null)
        {
            if ($Ensure -eq "Present")
            {
                Write-Verbose "The ensure state '$($Get["Ensure"])' of feature '$ID' does not match the desired state '$Ensure' because it is not installed in the farm."
                return $false
            }
        }
        else
        {
            # Check if the feature is installed at the specified scope
            $check = $null
            switch($feature.Scope)
            {
                "Farm"           { $check = Get-SPFeature $Id -Farm                -ErrorAction SilentlyContinue -Verbose:$false }
                "WebApplication" { $check = Get-SPFeature $Id -WebApplication $Url -ErrorAction SilentlyContinue -Verbose:$false }
                "Site"           { $check = Get-SPFeature $Id -Site $Url           -ErrorAction SilentlyContinue -Verbose:$false }
                "Web"            { $check = Get-SPFeature $Id -Web $Url            -ErrorAction SilentlyContinue -Verbose:$false }
            }
             
            if ($check -eq $null)
            {
                if ($Ensure -eq "Present")
                {
                    Write-Verbose "The ensure state 'Absent' of feature '$ID' does not match the desired state 'Present' because it is not activated at the desired scope."
                    return $false
                }
            }
            else
            {
                if ($Ensure -eq "Absent")
                {
                    Write-Verbose "The ensure state 'Present' of feature '$ID' does not match the desired state 'Absent' because it is activated at the desired scope."
                    return $false
                }   

                if ($check.Version -ne $feature.Version)
                {
                    Write-Verbose "The version of feature '$ID' does not match the installed feature version and needs an upgrade."
                    return $false
                }
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

