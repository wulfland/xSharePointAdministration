Configuration MyTestConfig
{
    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xUserProfileProperty
    

    Node localhost
    {
        xUserProfileProperty TestProperty
        {
            Name = "TestProperty"
            Ensure = "Absent"
            DisplayName = "Test Property 2"
            Privacy = "Private"
        }
    }
}

MyTestConfig -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\MyTestConfig -Wait -Force -Verbose