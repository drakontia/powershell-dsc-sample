configuration NewComputer
{
   param
    (
        [Parameter(Mandatory)]
        [pscredential]$userPasswordCred
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xComputerManagement

    Node $AllNodes.Where{$_.Role -eq "VM"}.NodeName
    {
         LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        xComputer NewNameAndWorkgroup
        {
            Name          = $Node.NodeName
            #DomainName = "simpline.local"
            #JoinOU = "Line1"
            #WorkGroupName = "SIMPLINE"
            #Credential = $domainCred
        }

        xIPAddress NewIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = "Ethernet"
            SubnetMask     = 24
            AddressFamily  = "IPV4"
        }

        Group TestGroup
        {
            # This will remove TestGroup, if present
            # To create a new group, set Ensure to "Present“
            Ensure = "Present"
            GroupName = "TestGroup"
        }

        User NewUser
        {
            Ensure = "Present"
            UserName = "miura"
            FullName = "one miura"
            Description = "Develop member"
            Password = $userPasswordCred # This needs to be a credential object
            PasswordChangeNotAllowed = $false
            PasswordChangeRequired = $true
            PasswordNeverExpires = $false
            DependsOn = "[Group]TestGroup"
        }

        Environment EnvironmentExample
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Name = "TestEnvironmentVariable"
            Value = "TestValue"
        }
    }
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "server1"
            Role = "VM"
            IPAddress = "10.0.xx.xxx"
            DomainName = "example.local"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        },
        @{
            NodeName = "server2"
            Role = "VM"
            IPAddress = "10.0.xx.xxx"
            DomainName = "example.local"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        }
    )

}

NewComputer -ConfigurationData $ConfigData `
    -userPasswordCred (Get-Credential -UserName '(All User)' -Message "All User Credential")

# Build the computer
#Start-DscConfiguration -Wait -Force -Path .\NewComputer -Verbose  