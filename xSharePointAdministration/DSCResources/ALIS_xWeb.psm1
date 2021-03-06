function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Url
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
    	$web = $gc | Get-SPWeb $Url -ErrorAction SilentlyContinue -Verbose:$false

        if ($web -eq $null)
        {
            $result =  @{
		        Url = $Url
		        Ensure = "Absent"
	        }
        }
        else
        {

	        $result = @{
		        Url = $web.Url
		        Ensure = "Present"
		        Description = $web.Description
		        Language = $web.Language
		        Template = "$($web.WebTemplate)#$($web.WebTemplateId)"
		        UniquePermissions = $web.HasUniquePerm
		        UseParentTopNav = $web.Navigation.UseShared
	        }
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
		$Url,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$Description,

        [System.String]
		$Name,

		[System.UInt32]
		$Language,

		[System.String]
		$Template,

		[System.Boolean]
		$UniquePermissions,

		[System.Boolean]
		$UseParentTopNav,

		[System.Boolean]
		$AddToQuickLaunch,

		[System.Boolean]
		$AddToTopNav
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        if ($Ensure -eq "Absent")
        {
            Remove-SPWeb $Url -AssignmentCollection $gc -Confirm:$false
            Write-Verbose "Web '$Url' successfully deleted."
        }
        else
        {
            $web = $gc | Get-SPWeb $Url -ErrorAction SilentlyContinue -Verbose:$false

            if ($web -eq $null)
            {
                $PSBoundParameters.Remove("Ensure") | Out-Null
                $PSBoundParameters.Remove("Debug") | Out-Null
                $PSBoundParameters.Remove("Confirm") | Out-Null

                Write-Verbose "Parameters: $($PSBoundParameters.Keys.ForEach({"-$_ $($PSBoundParameters.$_)"}) -join ' ')"

                $out = New-SPWeb @PSBoundParameters -Confirm:$false -AssignmentCollection $gc 

                Write-Verbose "SPWeb '$Url' was created successfully."
            }
            else
            {
                # Todo: set title, description navbar etc.
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
		$Url,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$Description,

        [System.String]
		$Name,

		[System.UInt32]
		$Language,

		[System.String]
		$Template,

		[System.Boolean]
		$UniquePermissions,

		[System.Boolean]
		$UseParentTopNav,

		[System.Boolean]
		$AddToQuickLaunch,

		[System.Boolean]
		$AddToTopNav
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
    	$web = $gc | Get-SPWeb $Url -ErrorAction SilentlyContinue -Verbose:$false

        if (($web -eq $null -and $Ensure -eq "Present") -or ($web -ne $null -and $Ensure -eq "Absent"))
        {
            Write-Verbose "The ensure state does not match the desired state '$Ensure'."
            return $false
        }

        # Todo: check name, description etc.

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

