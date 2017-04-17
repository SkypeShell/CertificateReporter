<#
.SYNOPSIS
    Gets all the relevant Skype servers and their certificates. Minimum role for SkypeAdminCredential: CsViewOnlyAdministrator
.DESCRIPTION
    Long description
.EXAMPLE
    $certsData = Get-CRSkypeCertCollection -SkypeFrontEndServer 'FE1.mandie.net' -SkypeAdminCredential 'mandie\dataadmin'
    Write-CRReport -ReportData $certsData -outputFilePath 'C:\temp\SkypeCerts.htm'
.EXAMPLE
    Get-CRSkypeCertCollection -SkypeFrontEndServer 'FE1.mandie.net' -SkypeAdminCredential 'mandie\dataadmin' | export-csv -path 'c:\temp\SkypeCerts.csv' -NoTypeInformation
#>
function Get-CRSkypeCertCollection {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName="Normal")]
        [string]
        [Alias("Server")]
        $SkypeFrontEndServer
        , [Parameter(Mandatory=$false,ParameterSetName="Normal")]
        [Alias("Credential")]
        [PSCredential]
        $SkypeAdminCredential
        ,[Parameter(Mandatory=$true,ParameterSetName="Bootleg")]
        [Switch]
        $Bootleg
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -eq "Normal") {
            if($PSCredential) {
                $skypeSession = New-PSSession -ConnectionUri "https://$SkypeFrontEndServer/OcsPowershell" -Credential $SkypeAdminCredential -Authentication Negotiate
            } else {
                $skypeSession = New-PSSession -ConnectionUri "https://$SkypeFrontEndServer/OcsPowershell" -Authentication NegotiateWithImplicitCredential
            }
            $null = Import-PSSession -Session $skypeSession -AllowClobber
        }
        $ReportData =  @()
        $certificateDB = Get-Content $PSScriptRoot\..\Resources\CertificateTypes.json | ConvertFrom-Json
    }
    
    process {
        if ($PSCmdlet.ParameterSetName -eq "Normal") {
            $SBA = (Get-CsPool).where({$_.services -like "*registrar*" -and $_.services.where({$_ -like "WebServer*"}).count -eq 0}).computers 
            $frontEndServer = (Get-CsPool).where({$_.services -like "*registrar*" -and $_.services -like "Conferencing*"}).computers
            $directorServer = (Get-CsPool).where({$_.services -like "*registrar*" -and $_.services -like "WebServer*" -and $_.services.where({$_ -like "Conferencing*"}).count -eq 0}).computers
            $mediationServer = (Get-CsPool).where({$_.services -like "*Mediation*" -and $_.services.where({$_ -like "registrar*"}).count -eq 0}).computers
            $edgeServer = (Get-CsPool).where({$_.services -like "*Edge*"}).computers

            # Limitation: does not explore the Office Web Apps Farm for individual servers
            $OfficeWebAppsServer =  (Get-cspool).where({$_.services -like "*WacServer*"}).computers

            # Filters out backup PSTN trunks to pair gateways with secondard Mediation Services - only shows PSTN trunks with "real" FQDNs
            # Alternatively, (Get-CsService -PstnGateway).Identity excluding anything in (Get-CsService -PstnGateway).DependentServiceList would work as well
            $PSTNGateway = (Get-CsPool).where({$_.services -like "PstnGateway*"}).computers

            #Excludes Standard Edition servers hosting their own FileStores
            $fileStore = (get-cspool).where({$_.services -like "FileStore*" -and $_.services.where({$_ -like "registrar*"}).count -eq 0}).computers
        
            foreach ($computerType in $certificateDB.Skype.PSObject.Properties.Name) {
                if (((get-variable $computerType).Value) -ne $null) {
                    foreach ($computer in (get-variable $computerType).Value) {
                        foreach ($certtype in $certificateDB.Skype.$computerType) {
                            $cert = Get-CRCertificate -ComputerName $computer -Port $certtype.Port -componentType $certtype.ComponentType
                            if ($cert -ne $null) {
                                $ReportData += $cert
                            }
                        }
                    }
                }    
            }
        } else {
            # Bootleg!
            $SkypeServers = Get-CRSkypeServerList
        }
        <#

        foreach ($server in $SBAs) {
            # Just get the certs from 5061
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5061 -ComponentType "SBA SIP" -ErrorAction SilentlyContinue 
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5067 -ComponentType "SBA Mediation" -ErrorAction SilentlyContinue
        }

        foreach ($server in $frontEndServers) {
            # Get certs from 5061
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5061 -ComponentType "Front End SIP" -ErrorAction SilentlyContinue
            # Get certs from 443
            $ReportData += Get-CRCertificate -ComputerName $server -Port 443 -ComponentType "Front End Web" -ErrorAction SilentlyContinue
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5067 -ComponentType "Front End Mediation" -ErrorAction SilentlyContinue
        }

        foreach ($server in $directorServers) {
            # Get certs from 5061
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5061 -ComponentType "Director SIP" -ErrorAction SilentlyContinue
            # Get certs from 443
            $ReportData += Get-CRCertificate -ComputerName $server -Port 443 -ComponentType "Director Web" -ErrorAction SilentlyContinue
            $ReportData += Get-CRCertificate -ComputerName $server -Port 444 -ComponentType "Director Service" -ErrorAction SilentlyContinue
        }

        foreach ($server in $mediationServers) {
             $ReportData += Get-CRCertificate -ComputerName $server -Port 5067 -ComponentType "Mediation Server" -ErrorAction SilentlyContinue
            # Get certs from 5067
        }

        foreach ($server in $edgeServers) {
            # Get certs from 5062, because that should be reachable from all internal clients
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5062 -ComponentType "Edge Internal" -ErrorAction SilentlyContinue
        }

        foreach ($server in $OfficeWebAppServers) {
            $ReportData += Get-CRCertificate -ComputerName $server -Port 443 -ComponentType "Office Web Apps Farm" -ErrorAction SilentlyContinue
        }

        foreach ($server in $PSTNGateways) {
            # Get certs from 5067
            $ReportData += Get-CRCertificate -ComputerName $server -Port 5067 -ComponentType "PSTN Gateway SIP" -ErrorAction SilentlyContinue
            # Get certs from 443
            $ReportData += Get-CRCertificate -ComputerName $server -Port 443 -ComponentType "PSTN Gateway Web" -ErrorAction SilentlyContinue
        }
        #>

<# Have not found a way to get these certs
        foreach ($server in $fileStores) {
            # Get certs from whatever SMB uses
            $ReportData += Get-CRCertificate -ComputerName $server -Port 3389 -ComponentType "File Share"
        }
        #>
    }
    
    end {
        $null = Remove-PSSession -Session $skypeSession
        return $ReportData
    }
}