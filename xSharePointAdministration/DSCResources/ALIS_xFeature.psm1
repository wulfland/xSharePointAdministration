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
            switch(feature.Scope)
            {
                "Farm"           { $check = Get-SPFeature $Id -Farm                -ErrorAction SilentlyContinue }
                "WebApplication" { $check = Get-SPFeature $Id -WebApplication $Url -ErrorAction SilentlyContinue }
                "Site"           { $check = Get-SPFeature $Id -Site $Url           -ErrorAction SilentlyContinue }
                "Web"            { $check = Get-SPFeature $Id -Web $Url            -ErrorAction SilentlyContinue }
            }
             
            if ($check -ne $null)
            {

                $ensureResult = "Present"
                $versionResult = $check.Version
            }
        }
	    
	    $returnValue = @{
		    ID = $idResult
		    Ensure = $ensureResult
		    Url = $url
		    Scope = $scopeResult
		    Version = $versionResult
	    }

	    $returnValue
	    
    }
    finally
    {
        Stop-SPAssignment $gc -Verbose:$false
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

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1


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

    $Get = Get-TargetResource $ID $Url

    if ($Get["Ensure"] -ne $Ensure)
    {
        Write-Verbose "The ensure state '$($Get["Ensure"])' of feature '$ID' does not match the desired state '$Ensure'."
        return $false
    }

    if ($Get["Version"] -eq $null)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        # get the installed feature
        $feature = $gc | Get-SPFeature $ID -ErrorAction SilentlyContinue -Verbose:$false

        if ($feature.Version -ne $Get["Version"])
        {
            Write-Verbose "The Version '$($Get["Version"])' of the feature does not match the Version $($feature.Version) of the installed Feature."
            return $false
        }
	    
	    $returnValue = @{
		    ID = $feature.Id
		    Ensure = $ensureResult
		    Url = $url
		    Scope = $feature.Scope
		    Version = $feature.Version
	    }

	    $returnValue
	    
    }
    finally
    {
        Stop-SPAssignment $gc -Verbose:$false
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

Export-ModuleMember -Function *-TargetResource

