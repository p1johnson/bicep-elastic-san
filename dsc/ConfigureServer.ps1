Configuration ConfigureServer {

    Param ()

    #Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration, GPRegistryPolicyDsc, NetworkingDsc, ComputerManagementDsc

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node 'localhost'

    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        
        RegistryPolicyFile DisableServerManagerStart {
            Key        = 'Software\Policies\Microsoft\Windows\Server\ServerManager'
            TargetType = 'ComputerConfiguration'
            ValueName  = 'DoNotOpenAtLogon'
            ValueData  = 1
            ValueType  = 'DWORD'
        }

        RegistryPolicyFile DisableNewNetworkPrompt {
            Key        = 'System\CurrentControlSet\Control\Network\NewNetworkWindowOff'
            TargetType = 'ComputerConfiguration'
            ValueName = '(Default)'
            ValueType = 'String'
            Ensure = 'Present'
        }

        RefreshRegistryPolicy RefreshPolicy {
            IsSingleInstance = 'Yes'
            DependsOn        = '[RegistryPolicyFile]DisableServerManagerStart','[RegistryPolicyFile]DisableNewNetworkPrompt'
        }

        NetConnectionProfile SetPrivateInterface
        {
            InterfaceAlias   = $InterfaceAlias
            NetworkCategory  = 'Private'
        }
        
        FirewallProfile ConfigurePrivateFirewallProfile
        {
            Name = 'Private'
            Enabled = 'False'
        }

        Service MSiSCSI
        {
            Name = 'MSiSCSI'
            StartupType = 'Automatic'
            State = 'Running'
        }

        WindowsFeature Multipath-IO
        {
            Name = 'Multipath-IO'
            Ensure = 'Present'
        }

        PendingReboot Reboot
        {
            Name = 'Reboot'
            DependsOn = '[WindowsFeature]Multipath-IO','[Service]MSiSCSI'
        }

        Script MultipathSupport
        {
            GetScript = {
                $returnValue = (Get-MSDSMAutomaticClaimSettings)
                return $returnValue
            }
            TestScript = {
                $returnValue = $false
                if ((Get-MSDSMAutomaticClaimSettings).iSCSI) {
                    if ((Get-MSDSMGlobalDefaultLoadBalancePolicy) -eq 'RR') {
                        $returnValue = $true
                    }
                }
                return $returnValue
            }
            SetScript = {
                Enable-MSDSMAutomaticClaim -BusType iSCSI
                Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR
            }
            DependsOn = '[PendingReboot]Reboot'
        }
    }

}