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
            Version = "2.4"
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

        Feature WebAppFeature
        {
            ID = "c15f7007-d0ff-403c-88cb-697f811e8572"
            Url = "http://localhost"
            Ensure = "Present"
            DependsOn = "[FarmSolution]TestSolution.wsp"
        }

        Feature SiteFeature
        {
            ID = "06780b45-1731-4bf9-8686-d734703e0d0c"
            Url = "http://localhost"
            Ensure = "Present"
            DependsOn = "[FarmSolution]TestSolution.wsp"
        }

        Feature WebFeature
        {
            ID = "8fed3a9c-e338-475f-bab0-cded858378b4"
            Url = "http://localhost"
            Ensure = "Present"
            DependsOn = "[FarmSolution]TestSolution.wsp"
        }
    }
}

$literalPath = Resolve-Path .\TestSolution.wsp

MyTestConfig -literalPath $literalPath

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\MyTestConfig -Wait -Force -Verbose