<#
.SYNOPSIS
    Gets a list of Exchange Server FQDNs, types and sites from Active Directory - no Exchange RBAC membership necessary
.DESCRIPTION
    Long description
.EXAMPLE
    Get-CRExchangeServerList | Export-CSV c:\temp\myExchangeServers.csv -NoTypeInformation
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Get-CRExchangeServerList {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
    )
    
    begin {
    }
    
    process {
        $configurationContainer = 'CN=Configuration,'+ (((get-adforest).name.split('.') | ForEach-Object {"DC=$_"}) -join ',')
        # All Exchange Servers
        $exchServers = Get-ADObject -LDAPFilter '(&(objectclass=msexchexchangeserver)(!objectclass=msexchexchangetransportserver))' -SearchBase $configurationContainer -Properties networkAddress,msExchUMServerDialPlanLink,msExchServerSite,msExchVersion,msExchCurrentServerRoles,serialNumber
        
        foreach ($server in $exchServers) {
            if ($server.msExchUMServerDialPlanLink.count -gt 0) {
                $serverType = 'ExchangeUM'
                $version = $server.serialNumber
            } else {
                if ($server.objectClass -eq "msExchClientAccessArray"){
                    $serverType = 'ExchangeArray'
                    # No easy way to get the Exchange version of an array
                    $version = 'ExchangeArray'
                } else {
                    # is it an Edge server?
                    if ($server.msExchCurrentServerRoles -eq 64) {
                        $serverType = 'ExchangeEdge'
                        $version = $server.serialNumber
                    } 
                    # it's a mailbox and/or CAS server
                    else {
                        $serverType = 'Exchange'
                        $version = $server.serialNumber
                    }
                }
            }
            $fqdn = ($server.networkAddress -match "ncacn_ip_tcp:").split(':')[1]
            $site = $server.msexchserversite.split(',')[0].split('=')[1]
            [PSCustomObject]@{computerName=$fqdn;site=$site;componentType=$serverType;version=$version}
        }
    }
    
    end {
    }
}                  
