Configuration MyTestConfig
{
    param([string]$LiteralPath)

    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xFarmSolution
    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xList
    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xFeature
    

    Node localhost
    {
        FarmSolution TestSolution.wsp
        {
            Name = "TestSolution.wsp"
            LiteralPath = $LiteralPath
            Version = "2.0"
            Ensure = "Present"
            Local = $true
            Deployed = $true
            Force = $false
        }

        Feature FarmFeature
        {
            ID = "b80acc14-17ab-4f62-a7ac-41d4a62b1323"
            Url = "http://localhost"
            Ensure = "Present"
            DependsOn = "[FarmSolution]TestSolution.wsp"
        }

        List List1
        {
            Title = "List1"
            TemplateId = "100"
            Url = "http://localhost/Lists/List1"
        }
    }
}

$literalPath = Resolve-Path .\TestSolution.wsp

MyTestConfig -literalPath $literalPath

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\MyTestConfig -Wait -Force -Verbose