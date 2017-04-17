<#
.SYNOPSIS
    Gets a re-formatted SSL certificate from a remote computer on a designated port (default 443)
.DESCRIPTION
    Technique for getting certificate from SslStream originally from Yoav Barzilay, @y0avb / https://y0av.me
    
    This function opens a TCP connection to the computer name/port combination, then attempts to authenticate,
    which makes the remote certificate available for inspection. It then parses the certificate into a more
    convenient form for the report.

.EXAMPLE
    Get-CRCertificate -computerName sip.mandie.net -port 5061 -componentType "External Edge Federation"
.EXAMPLE
    Import-CSV -Path C:\temp\myServers.csv | Get-CRCertificate | Export-CSV -Path 'MyServerCerts.csv' -NoTypeInformation
#>
function Get-CRCertificate {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [String]$ComputerName
        , [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
        [int]$Port
        , [Parameter(Mandatory=$false,ValueFromPipeline=$true,Position=2)]
        [String]$ComponentType="Web Server"
    )
    
    begin {
    }
    
    process {
        try {
    $tcpsocket = New-Object System.Net.Sockets.TcpClient
    $tcpsocket.ConnectAsync($ComputerName,$Port)

    #Socket Got connected get the tcp stream ready to read the certificate
    #write-host "Successfully Connected to $computername on $port" -ForegroundColor Green -BackgroundColor Black
    $tcpStream = $tcpsocket.GetStream()
    #Write-host "Reading SSL Certificate…." -ForegroundColor Yellow -BackgroundColor Black 
    #Create an SSL Connection 
    $sslStream = New-Object System.Net.Security.SslStream($tcpStream,$false)
    #Force the SSL Connection to send us the certificate
    $sslStream.AuthenticateAsClientAsync($ComputerName)

    #Read the certificate
    $certInfo = $sslStream.RemoteCertificate
    $returnobj = [ordered]@{
      ComputerName = $ComputerName;
      Port = $Port;
      Subject = $certInfo.Subject;
      SubjectAlternateNames = if ($certinfo.DnsNameList -ne $null) {$certInfo.DnsNameList -join ', '} else {''}
      Thumbprint = $certInfo.Thumbprint;
      Issuer = $certInfo.Issuer;
      KeySize = ($certInfo.PublicKey.EncodedKeyValue.RawData.Count - 14)*8;
      SerialNumber = $certInfo.SerialNumber;
      NotBefore = $certInfo.NotBefore;
      NotAfter = $certInfo.NotAfter;
      DaysUntilExpiration = ($certInfo.NotAfter - (get-date)).Days
      ComponentType = $ComponentType
    }
  new-object PSCustomObject -Property $returnobj
        }
        catch {
            write-warning "Could not get certificate for $ComputerName from port $Port"
        }
        finally {
            if ($tcpsocket -ne $null) {
                $tcpsocket.Dispose()  
            }
        }
}
        
    end {
    }
}