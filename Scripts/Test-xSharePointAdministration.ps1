Configuration MyTestConfig
{
    param([string]$LiteralPath)

    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xFarmSolution

    Node localhost
    {
        FarmSolution TestSolution.wsp
        {
            Name = "TestSolution.wsp"
            LiteralPath = $LiteralPath
            Version = "1.0"
            Ensure = "Absent"
            Local = $false
            Deployed = $true
            Force = $false
        }
    }
}

$literalPath = Resolve-Path .\TestSolution.wsp

MyTestConfig -literalPath $literalPath

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\MyTestConfig -Wait -Force -Verbose