Configuration MyTestConfig
{
    Import-DscResource -ModuleName xSharePointAdministration -Name ALIS_xUserProfileProperty
    

    Node localhost
    {
        xUserProfileProperty TestProperty
        {
            Name = "TestProperty"
            Ensure = "Absent"
            DisplayName = "Test Property"
            Privacy = "Private"
        }

        xUserProfileProperty TestMultiLineProperty
        {
            Name = "TestProperty2"
            Ensure = "Absent"
            DisplayName = "Test Property 2"
            Privacy = "Private"
            IsMultivalued = $true
            Separator = "Semicolon"
            MaximumShown = 12
        }
    }
}

MyTestConfig -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\MyTestConfig -Wait -Force -Verbose

Get-DscConfiguration