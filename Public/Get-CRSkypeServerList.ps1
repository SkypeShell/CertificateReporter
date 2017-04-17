<#
.SYNOPSIS
    Gets Skype servers from AD, not Skype
.DESCRIPTION
    This cmdlet uses the RTC (Lync/Skype for Business) data in the Configuration context of the local AD forest, or by searching the Lc Services under computers in your current AD domain (-Simple option)
.EXAMPLE
    Get-CRSkypeServerList | Get-CRCertificate | Export-CSV -Path C:\temp\MyCerts.csv -NoTypeInformation
.EXAMPLE
    Get-CRSkypeServerList -Simple
#>
function Get-CRSkypeServerList {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        # This option gets the server data from the local AD domain, which will miss the Edge servers
        [Parameter(Mandatory=$true)]
        [Switch]
        $Simple
    )
    
    begin {
    }
    
    process {
        if ($Simple) {
            $services = get-adobject -ldapfilter '(|(objectclass=msrtcsip-webcomponents)(objectclass=msrtcsip-server)(objectclass=msRTCSIP-MCU)(objectclass=msRTCSIP-ApplicationServer))'
            $serversHashtable = @{}
            # hashtable with key = grandparent cn, values = cn
            foreach ($service in $services) {
                $serviceName = $service.Name
                $serverName = $service.DistinguishedName.Split(',')[2].Split('=')[1]
                if ($serversHashtable[$serverName]) {
                    $serversHashtable[$serverName] += $serviceName
                } else {
                     $serversHashtable.Add($serverName, @($serviceName))   
                }
            }
            $serversCollection = $serversHashtable.GetEnumerator() | Sort-Object -Property Name

            foreach ($server in $serversCollection){
                if ($server.value -contains 'RTC Services') { $serverType = 'SBA' }
                if ($server.value -contains 'LS WebComponents Service') { $serverType = 'Director' }
                if ($server.value -contains 'LS AV MCU') { $serverType = 'FrontEnd' }
                [PSCustomObject]@{computerName=$server.name;componentType=$serverType}
            }

        } else {
            $configurationContainer = 'CN=Configuration,'+ (((get-adforest).name.split('.') | ForEach-Object {"DC=$_"}) -join ',')
            # All pools, whether Director, FrontEnd or SBA
            $rawPools = get-adobject -LDAPFilter '(objectClass=msrtcsip-pool)' -SearchBase $configurationContainer -Properties 'name','dnshostname','msrtcsip-pooldata','msrtcsip-pooldisplayname','distinguishedname','msrtcsip-pooltype','msrtcsip-poolversion'
            # An entry for each combination of pool or member server and several service types
            $trustedServices = get-adobject -LDAPFilter '(objectclass=msrtcsip-trustedservice)' -SearchBase $configurationContainer -Properties 'msrtcsip-routingpooldn','msrtcsip-trustedServerFQDN','msrtcsip-trustedserviceport','msrtcsip-trustedservicetype'
            # All pools and their member servers (if Enterprise)
            $trustedServers = get-adobject -LDAPFilter '(objectClass=msrtcsip-trustedserver)' -SearchBase $configurationContainer -Properties 'msrtcsip-trustedserverfqdn'
            # All Edge pools
            $edgeProxys = get-adobject -LDAPFilter '(objectClass=msrtcsip-edgeproxy)' -SearchBase $configurationContainer -Properties 'msrtcsip-edgeproxyfqdn'
            # All pools and member servers with web components (no SBAs)
            $webComponentsServers = Get-ADObject -LDAPFilter '(objectClass=msrtcsip-TrustedWebComponentsServer)' -SearchBase $configurationContainer -Properties 'msrtcsip-trustedwebcomponentsserverfqdn'
 
            # re-write $rawPools
            $pools = foreach ($pool in $rawPools) {
                [PSCustomObject]@{
                    poolFqdn = $pool.dnshostname
                    poolType = getPoolType($pool.'msrtcsip-pooldata'[0])
                    poolDN = $pool.distinguishedname
                }
# Take $service in $trustedServices
# if $service.'msrtcsip-trustedServerFQDN' not in $pools.dnsHostname
# try to match ($service.routingpoolDN) to 'CN=Lc Services,CN=Microsoft,'+($pools).distinguishedname

# if QoS + MediationServer: SBA
# if QoS, MediationServer and others: FrontEnd
# if QoS, no MediationServer, but others: Director
# if MediationServer but no QoS: MediationServer
# Edges are not in this one at all
     
            }
            # Edge pool re-write
            $edgePools = foreach ($edge in $edgeProxys) {
                [PSCustomObject]@{
                    poolFqdn = $edge.'msrtcsip-edgeproxyfqdn'
                    poolType = 'EdgePool'
                    poolDN = ''
                }
            }
        }
    }
    
    end {
    }
}

function getPoolType($poolData) {
    Switch($poolData.split('=')[1]) {
        CentralRegistrar {"FrontEndPool"}
        RemoteRegistrar {"SBA"}
        Director {"DirectorPool"}
        Default {"Other"}
    }
}