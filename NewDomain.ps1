configuration NewDomain
{
   param
    (
        # 作成する際のコマンドの引数と対応している
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,
        [Parameter(Mandatory)]
        [pscredential]$domainCred,
        [Parameter(Mandatory)]
        [pscredential]$userCred
    )

    # xから始まるものはGithubから入手する必要がある。
    # インターネットに繋がる環境であれば、"Import-Module {ModuleName}"で取得できる。
    # 繋がらない場合は、ダウンロードしてきて取り込む必要がある。
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -moduleName xDHCpServer
    Import-DscResource -ModuleName xComputerManagement

    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {

        # プル型にするときなどの設定
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        # ホスト名の設定
        xComputer NewNameAndWorkgroup
        {
            Name          = $Node.NodeName
        }

        File ADFiles
        {
            DestinationPath = 'C:\NTDS'
            Type = 'Directory'
            Ensure = 'Present'
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        # Optional GUI tools
        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        # If this node is not AWS instance.
        xIPAddress NewIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = "Ethernet"
            SubnetMask     = 24
            AddressFamily  = "IPV4"
        }

        WindowsFeature DHCP {
            DependsOn = '[xIPAddress]NewIpAddress'
            Name = 'DHCP'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }

        WindowsFeature DHCPTools
        {
            DependsOn= '[WindowsFeature]DHCP'
            Ensure = 'Present'
            Name = 'RSAT-DHCP'
            IncludeAllSubFeature = $true
        }

        # No slash at end of folder paths
        xADDomain FirstDS
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            #DatabasePath = 'C:\NTDS'
            #LogPath = 'C:\NTDS'
            #SysvolPath = 'C:\NTDS'
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            RetryIntervalSec = $Node.RetryIntervalSec
            RetryCount = $Node.RetryCount
            DependsOn = "[xADDomain]FirstDS"
        }

        xADUser FirstUser
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            UserName = "user01"
            Password = $userCred
            Description = "First Domain User"
            StreetAddress = "101"
            PostalCode = "1XXXXXX"
            Country = JP
            Company = "Example"
            Office = "Tokyo"
            EmailAddress = "user01@example.co.jp"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xADGroup NewGroup
        {
            GroupName = "Group1"
            Description = 'Administrator Group'
            Members = "user01"
        }

        xADOrganizationalUnit NewOU
        {
            Name = OU1
            Path = "XXX"
        }

        # ゴミ箱
        xADRecycleBin NewBin
        {
            ForestFQDN = "recyclebin.example.local"
            EnterpriseAdministratorCredential = $domainCred
        }

        xADDomainDefaultPasswordPolicy NewPolicy
        {
            DomainName = "example.local"
            ComplexityEnabled = $false
            LockoutObservationWindow = $false
            MinPasswordAge = 5
            MaxPasswordAge = 45
            MinPasswordLength = 12
            PasswordHistoryCount = 10
        }

        xDhcpServerScope Scope
        {
            DependsOn = '[WindowsFeature]DHCP'
            Ensure = 'Present'
            IPEndRange = '10.0.xx.xxx'
            IPStartRange = '10.0.xx.xx'
            Name = 'PowerShellScope'
            SubnetMask = '255.255.255.0'
            LeaseDuration = '00:08:00'
            State = 'Active'
            AddressFamily = 'IPv4'
        } 
 
        xDhcpServerOption Option
        {
            Ensure = 'Present'
            ScopeID = '10.0.xx.xx'
            DnsDomain = 'example.local'
            DnsServerIPAddress = '10.0.xx.xx'
            AddressFamily = 'IPv4'
        }
    }

    Node $AllNodes.Where{$_.Role -eq "Secondary DC"}.Nodename
    {

        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        xComputer NewNameAndWorkgroup
        {
            Name = $Node.NodeName
        }

        File ADFiles
        {
            DestinationPath = 'C:\NTDS'
            Type = 'Directory'
            Ensure = 'Present'
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        # If this node is not AWS instance.
        xIPAddress NewIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = "Ethernet"
            SubnetMask     = 24
            AddressFamily  = "IPV4"
        }

        WindowsFeature DHCP {
            DependsOn = '[xIPAddress]NewIpAddress'
            Name = 'DHCP'
            Ensure = 'PRESENT'
            IncludeAllSubFeature = $true
        }

        WindowsFeature DHCPTools
        {
            DependsOn= '[WindowsFeature]DHCP'
            Ensure = 'Present'
            Name = 'RSAT-DHCP'
            IncludeAllSubFeature = $true
        }

        # No slash at end of folder paths
        xADDomain FirstDS
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            #DatabasePath = 'C:\NTDS'
            #LogPath = 'C:\NTDS'
            #SysvolPath = 'C:\NTDS'
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            RetryIntervalSec = $Node.RetryIntervalSec
            RetryCount = $Node.RetryCount
            DependsOn = "[xADDomain]FirstDS"
        }

        xADUser FirstUser
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            UserName = "user01"
            Password = $userCred
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xDhcpServerScope Scope
        {
            DependsOn = '[WindowsFeature]DHCP'
            Ensure = 'Present'
            IPEndRange = '10.0.xx.xxx'
            IPStartRange = '10.0.xx.xx'
            Name = 'PowerShellScope'
            SubnetMask = '255.255.255.0'
            LeaseDuration = '00:08:00'
            State = 'Active'
            AddressFamily = 'IPv4'
        } 
 
        xDhcpServerOption Option
        {
            Ensure = 'Present'
            ScopeID = '10.0.xx.xx'
            DnsDomain = 'example.local'
            DnsServerIPAddress = '10.0.xx.xx'
            AddressFamily = 'IPv4'
        }
    }
}

# Configuration Data for AD
$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "server1"
            Role = "Primary DC"
            IPAddress = "10.0.xx.xxx"
            DomainName = "example.local"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        },

        @{
            Nodename = "Server2"
            Role = "Secondary DC"
            IPAddress = "10.0.xx.xxx"
            DomainName = "example.local"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        }
    )
}

NewDomain -ConfigurationData $ConfigData `
    -safemodeAdministratorCred (Get-Credential -UserName '(Password Only)' `
        -Message "New Domain Safe Mode Administrator Password") `
    -domainCred (Get-Credential -UserName example\administrator `
        -Message "New Domain Admin Credential") `
    -userCred (Get-Credential -UserName example\user01 `
        -Message "New Domain User Credential")

# Make sure that LCM is set to continue configuration after reboot            
#Set-DSCLocalConfigurationManager -Path .\NewDomain –Verbose            
            
# Build the domain            
#Start-DscConfiguration -Wait -Force -Path .\NewDomain -Verbose  