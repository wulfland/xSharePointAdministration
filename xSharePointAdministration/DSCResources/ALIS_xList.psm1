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
        $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
        $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().TrimEnd("/lists")
        $webRelativeUrl = $Url.Replace($webUrl, "")

    	$web = $gc | Get-SPWeb $webUrl -ErrorAction SilentlyContinue -Verbose:$false

        $ensureResult = "Present"
        $titleResult = $listName
        $descriptionResult = ""
        $templateIdResult = "100"
        $templateFeatureId = $null

        if ($web -eq $null)
        {
            $ensureResult = "Absent"
        }
        else
        {
            try
            {
                $list = $web.GetList($Url)
                $titleResult = $list.Title
                $descriptionResult = $list.Description
                $templateIdResult = $list.BaseTemplate
                $templateFeatureId = $list.TemplateFeatureId
            }
            catch
            {
                $ensureResult = "Absent"
            }
        }

        $result = @{
		    Url = $Url
		    Ensure = $ensureResult
		    Title = $titleResult
		    Description = $descriptionResult
		    TemplateId = $templateIdResult
		    FeatureId = $templateFeatureId
            DocTemplateType = "101"
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
		[String]$Url,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present",

		[String]$Title,

		[String]$Description,

		[String]$TemplateId = "100",

		[String]$FeatureId,

        [String]$DocTemplateType = "101"
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
        $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().TrimEnd("/lists")
        $webRelativeUrl = $Url.Replace($webUrl, "")

        $web = $gc | Get-SPWeb $webUrl -ErrorAction SilentlyContinue -Verbose:$false

        if ($web -eq $null)
        {
            Throw-TerminatingError -errorId "MissingWeb" -errorMessage "The parent web of the list '$Url' could not be found or accessed." -errorCategory InvalidArgument
            return
        }

        try
        {
            $list = $web.GetList($Url)
        }
        catch
        {
            if ($Ensure -eq "Present")
            {
                if (-not $Title)
                {
                    $Title = $listName
                }

                if ($FeatureId)
                {
                    $id = $web.Lists.Add($Title, $Description, $webRelativeUrl, $FeatureId, $TemplateId, $DocTemplateType)
                }
                else
                {
                    $id = $web.Lists.Add($listName, $Description, $TemplateId)
                }

                $list = $web.Lists[$id]
                Write-Verbose "List '$Title' (ID: '$id') sucessfully created."
            }
        }

        if ($Ensure -eq "Absent")
        {
            $list.Delete()
            Write-Verbose "List '$Url' successfully deleted."
        }
        else
        {
            $needsUpdate = $false

            if ($Title)
            {
                if ($list.Title -ne $Title)
                {
                    $list.Title = $Title
                    $needsUpdate = $true
                    Write-Verbose "Updated Title to '$Title'."
                }
            }

            if ($Description)
            {
                if ($list.Description -ne $Description)
                {
                    $list.Description = $Description
                    $needsUpdate = $true
                    Write-Verbose "Updated Description to '$Description'."
                }
            }

            if ($needsUpdate)
            {
                $list.Update()
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
		[String]$Url,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present",

		[String]$Title,

		[String]$Description,

		[String]$TemplateId = "100",

		[String]$FeatureId,

        [String]$DocTemplateType = "101"
	)

    Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {
        $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
        $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().TrimEnd("/lists")
        $webRelativeUrl = $Url.Replace($webUrl, "")

        $web = $gc | Get-SPWeb $webUrl -ErrorAction SilentlyContinue -Verbose:$false

        if ($web -eq $null)
        {
            Throw-TerminatingError -errorId "MissingWeb" -errorMessage "The parent web of the list '$Url' could not be found or accessed." -errorCategory InvalidArgument
            return
        }

        try
        {
            $list = $web.GetList($Url)

            if ($Ensure -eq "Absent")
            {
                Write-Verbose "The ensure state 'Present' does not match the desired state '$Ensure'."
                return $false
            }
        }
        catch
        {
            if ($Ensure -eq "Present")
            {
                Write-Verbose "The ensure state 'Absent' does not match the desired state '$Ensure'."
                return $false
            }
            else
            {
                return $true
            }
        }

        if (-not $Title)
        {
            $Title = $listName
        }

        if ($Title -ne $list.Title)
        {
            Write-Verbose "The title '$($list.Title)' does not match the desired state '$Title'."
            return $false
        }

        if ($Description -ne $list.Description)
        {
            Write-Verbose "The description '$($list.Description)' does not match the desired state '$Description'."
            return $false                
        }


        return $true;
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

