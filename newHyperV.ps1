configuration newHyperV

{

    param (

        #[string]$NodeName = 'localhost'

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xHyper-V

    node $AllNodes.Where{$_.Role -eq "Host"}.NodeName {

        WindowsFeature 'Hyper-V' {

            Ensure = 'Present'
            Name = 'Hyper-V'
            IncludeAllSubFeature = $true

        }

        WindowsFeature 'Hyper-V-Powershell' {

            Ensure = 'Present'
            Name = 'Hyper-V-Powershell'

        }

        File VMsDirectory {

            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = "$($env:SystemDrive)\VMs"

        }

        xVMSwitch LabSwitch {

            DependsOn = '[WindowsFeature]Hyper-V'
            Name = 'LabSwitch'
            Ensure = 'Present'
            Type = 'Internal'

        }

        xVMHyperV NewVM {
            Ensure          = 'Present'
            Name            = $AllNodes.Where{$_.Role -eq "WebServer"}.NodeName
            VhdPath         = $NewSystemVHDPath
            SwitchName      = "LabSwitch"
            State           = $State
            Path            = $Path
            Generation      = 2
        }

    }

}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName     = "HOST-1"
            Role = "Host"
            LogPath      = "C:\Logs"
        },


        @{
            NodeName     = "VM-1"
            Role         = "WebServer"
            SiteContents = "C:\Site1"
            SiteName     = "Website1"
        },


        @{
            NodeName     = "VM-2"
            Role         = "SQLServer"
        },

        @{
            NodeName     = "VM-3"
            Role         = "WebServer"
            SiteContents = "C:\Site2"
            SiteName     = "Website3"
        }
    );
}

newHyperV -ConfigurationData $ConfigData