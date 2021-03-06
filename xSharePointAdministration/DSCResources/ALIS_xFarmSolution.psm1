function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$LiteralPath
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

    try
    {

        $Solution = $gc | Get-SPSolution $Name -ErrorAction SilentlyContinue -Verbose:$false

        if ($Solution.count -eq 0)
        {
            $ensureResult = "Absent"
        }
        else
        {
            $ensureResult = "Present"
        }


        $webApps = $Solution.DeployedWebApplications | Select -ExpandProperty Url

        $version = $Solution.Properties["Version"]

	    $returnValue = @{
		    Name = $Solution.Name
		    Ensure = $ensureResult
		    LiteralPath = $LiteralPath
		    Version = $version
		    WebApplications = $webApps
            Deployed = $Solution.Deployed
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

		[parameter(Mandatory = $true)]
		[System.String]
		$LiteralPath,

		[System.String]
		$Version = "1.0",

		[System.String[]]
		$WebApplications = @(),

		[System.Boolean]
		$Deployed = $true,

		[System.Boolean]
		$Local = $false,

		[System.Boolean]
		$Force = $false
	)

    Ensure-PSSnapin

    if (!$PSBoundParameters.ContainsKey("Local"))
    {
        $PSBoundParameters.Add("Local", $Local);
    }

    if (!$PSBoundParameters.ContainsKey("Force"))
    {
        $PSBoundParameters.Add("Force", $Force);
    }

    $gc = Start-SPAssignment -Verbose:$false

    try
    {

        $Solution = $gc | Get-SPSolution $Name -ErrorAction SilentlyContinue -Verbose:$false

	    if ($Ensure -eq "Present")
        {
            if ($Solution -eq $null)
            {
                # Solution does not exist. Add to store
                $Solution = $gc | Add-SPSolution -LiteralPath $LiteralPath
                Write-Verbose "Solution $Name was uploaded to the farm."

                $Solution.Properties["Version"] = $Version
                $Solution.Update()
                Write-Verbose "Version of $Name was set to '$Version'."
            }

            $currentVersion = $Solution.Properties["Version"]

            if ($Version -ne $currentVersion)
            {
                # Version missmatch
                Write-Verbose "The version of $Name is '$currentVersion' but should be '$Version'."
                if (-not $Solution.Deployed)
                {
                    # Remove and add
                    Remove-SPSolution $Solution -Confirm:$false -AssignmentCollection $gc
                    Write-Verbose "Removed solution $Name with Version '$currentVersion'."

                    $Solution = $gc | Add-SPSolution -LiteralPath $LiteralPath
                    Write-Verbose "Solution $Name was uploaded to the farm."

                    $Solution.Properties["Version"] = $Version
                    $Solution.Update()
                    Write-Verbose "Version of $Name was set to '$Version'."
                }
                else
                {
                    # Update
                    $gc | Update-SPSolution $Name -LiteralPath $LiteralPath -GACDeployment:$Solution.ContainsGlobalAssembly -Local:$local -Confirm:$False
                    Write-Verbose "Solution $Name upgraded to version '$Version'."
                    $Solution = $gc | Get-SPSolution $Name
                    $Solution.Properties["Version"] = $Version
                    $Solution.Update()
                }
            }
            

            $skipWebApps = $false
            # Check Parameters
            if ($Deployed -ne $Solution.Deployed)
            {
                Write-Verbose "The deploy state of $Name is '$($Solution.Deployed)' but should be '$Deployed'."
                if ($Solution.Deployed)
                {
                    # Retract Solution globally
                    Retract-Solution $Solution $gc @()
                }
                else
                {
                    # Deploy solution
                    Deploy-Solution $Solution $gc $WebApplications
                }

                $skipWebApps = $true
            }

            if (-not $skipWebApps)
            {
                if ($WebApplications -eq $null -or $WebApplications.Length -eq 0)
                {
                    Write-Verbose "No explicit web applications specified."
                }
                else
                {
                    $webApps = $Solution.DeployedWebApplications | Select -ExpandProperty Url

                    # Retract solutions that are not in configuration
                    foreach ($webApp in $webApps)
                    {
                        if (-not $WebApplications.Contains($webApp))
                        {
                            Retract-Solution $Solution $gc @($webApp)
                        }
                    }

                    # Deploy solutions that are not deployed yet
                    foreach ($webApp in $WebApplications)
                    {
                        if (-not $webApps.Contains($webApp))
                        {
                            Deploy-Solution $Solution $gc @($webApp) 
                        }
                    }
                }
            }
            

            if (-not $Local)
            {
                $spAdminServiceName = "SPAdminV4"

                Stop-Service -Name $spAdminServiceName 
                Start-SPAdminJob 
                Start-Service -Name $spAdminServiceName
                Write-Verbose "Service '$spAdminServiceName' restarted."

                WaitFor-SolutionJob -Solution $solution
            }
        }
        else
        { 
            # Ensure Absent
            if ($Solution -ne $null)
            {
                if ($solution.Deployed) 
                {
                    Retract-Solution $Solution $gc 

                    if (-not $Local)
                    {
                        $spAdminServiceName = "SPAdminV4"

                        Stop-Service -Name $spAdminServiceName 
                        Start-SPAdminJob 
                        Start-Service -Name $spAdminServiceName
                        Write-Verbose "Service '$spAdminServiceName' restarted."

                        WaitFor-SolutionJob -Solution $solution
                    }
                }

                Get-SPSolution $name -AssignmentCollection $gc | Remove-SPSolution -Confirm:$false -AssignmentCollection $gc
                Write-Verbose "Solution $Name was removed from the farm."
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

		[parameter(Mandatory = $true)]
		[System.String]
		$LiteralPath,

		[System.String]
		$Version = "1.0",

		[System.String[]]
		$WebApplications = @(),

		[System.Boolean]
		$Deployed = $true,

		[System.Boolean]
		$Local = $false,

		[System.Boolean]
		$Force = $false
	)

	Ensure-PSSnapin

    $gc = Start-SPAssignment -Verbose:$false

	$Solution = $gc | Get-SPSolution $Name -ErrorAction SilentlyContinue -Verbose:$false

    try
    {

        if (($Ensure -eq "Present" -and $Solution -eq $null) -or ($Ensure -eq "Absent" -and $Solution -ne $null)){
    
            Write-Verbose "The ensure state of solution $Name does not match the desired state."
            return $false
        }

        if ($Solution -ne $null)
        {
            # Check Version
            $currentVersion = $Solution.Properties["Version"]
            if ($currentVersion -ne $Version)
            {
                Write-Verbose "The version '$currentVersion' of solution $Name does not match the desired state of '$Version'."
                return $false
            }

            # Check deployed state
            if ($Deployed -ne $Solution.Deployed)
            {
                Write-Verbose "The deployed state ($(Solution.Deployed)) of the solution $Name does not match the desired state ($Deployed)."
                return $false
            }

            # Check webapps
            if ($Solution.Deployed)
            {
                if ($WebApplications -ne $null)
                {
                    if ($WebApplications.Length -gt 0)
                    {
                        $webApps = $Solution.DeployedWebApplications | Select -ExpandProperty Url
                        if (Compare-Object -ReferenceObject $webApps -DifferenceObject $WebApplications -PassThru)
                        {
                            Write-Verbose "The deploy state of the web applications ($webApps) does not match the desired state ($WebApplications)."
                            return $false
                        }
                    }
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

function Deploy-Solution
{
    param
    (
        $solution,
        $gc,
        [string[]]$WebApps = @()
    )

    $v     = $PSBoundParameters.ContainsKey("Verbose")
    $l     = $PSBoundParameters["Local"]
    $force = $PSBoundParameters["Force"]
    $gac   = $solution.ContainsGlobalAssembly

    if (!$solution.ContainsWebApplicationResource) 
    {
        Write-Verbose "Begin deployment of solution '$($solution.name)' to the farm."
        $solution | Install-SPSolution -GACDeployment:$gac -AssignmentCollection $gc -Local:$l -Verbose:$v -Force:$force
        Write-Verbose "Solution '$($solution.name)' deployed to the farm."
    }
    else
    {
        if ($webApps -eq $null -or $webApps.Length -eq 0) 
        {
            Write-Verbose "Begin deployment of solution '$($solution.name)' to all web applications."
            $solution | Install-SPSolution -GACDeployment:$gac  -AllWebApplications -AssignmentCollection $gc -Local:$l -Verbose:$v -Force:$force
            Write-Verbose "Solution '$($solution.name)' deployed to all web applications."
        }
        else
        {
            foreach ($webApp in $webApps)
            {
                Write-Verbose "Begin deployment of solution '$($solution.name)' to web application '$webApp'."
                $solution | Install-SPSolution -GACDeployment:$gac  -WebApplication $webApp -AssignmentCollection $gc -Local:$l -Verbose:$v -Force:$force
                Write-Verbose "Solution '$($solution.name)' deployed to web application '$webApp'."
            }
        }
    }
}

function Retract-Solution
{
    [CmdletBinding()]
    param
    (
        $Solution, 
        $gc,
        [string[]]$WebApps = @()  
    )

    $v = $PSBoundParameters.ContainsKey("Verbose")
    $l = $PSBoundParameters["Local"]

    if ($solution.ContainsWebApplicationResource) 
    {
        if ($webApps -eq $null -or $webApps.Length -eq 0) 
        {
            $solution | Uninstall-SPSolution -AllWebApplications -AssignmentCollection $gc -Verbose:$v -Confirm:$false -Local:$l
            Write-Verbose "Solution '$($solution.name)' was retracted from all web applications." 
        }
        else
        {
            foreach ($webApp in $webApps)
            {
                $solution | Uninstall-SPSolution -webapplication $WebApp -AssignmentCollection $gc -Verbose:$v -Confirm:$false -Local:$l
                Write-Verbose "Solution '$($solution.name)' was retracted from web applications '$webApp'." 
            }
        }
    }
    else 
    {
        $solution | Uninstall-SPSolution -AssignmentCollection $gc -Verbose:$v -Confirm:$false -Local:$l
        Write-Verbose "Solution '$($solution.name)' was retracted from the farm."
    }
}

function WaitFor-SolutionJob
{
    [CmdletBinding()]
    param
    (
        [Microsoft.SharePoint.Administration.SPSolution]$Solution
    )

    Write-Verbose "Waiting for solution..."
    start-sleep -s 5

    while($Solution.JobExists)
    {
        Write-Verbose "."
        start-sleep -s 1
    }

    Write-Verbose "Result of job is '$($Solution.LastOperationResult)'."
}

Export-ModuleMember -Function *-TargetResource

