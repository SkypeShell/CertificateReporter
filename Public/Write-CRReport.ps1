<#
.SYNOPSIS
    Writes HTML from array of objects, adding style and headers
.DESCRIPTION
    Still trying to figure out how to get $ReportData from the pipeline, like Export-CSV works
.EXAMPLE
    Write-CRReport -ReportData (Get-Service) -outputFilePath 'c:\temp\Services.htm'
.EXAMPLE
    Write-CRReport -ReportData ((Get-CsService -PSTN).PoolFqdn | Get-CRCertificate -Port 5067 -ComponentType 'PSTNGateway') -outputFilePath 'C:\temp\PSTNGateways.htm'
#>
function Write-CRReport {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [PSObject[]]$reportData
        ,[Parameter(Mandatory=$false)]
        [string]
        $outputFilePath
    )
    
    begin {
        if ($outputFilePath -notlike "*.htm" ) {
            $outputFilePath = (CreateHtmFile).FullName 
        }
        #$outputCss = Get-Content -Path (get-module SkypeCertificateReport).Path+'\..\Private\SkypeCertificateReport.css'
        $outputCss = Get-content -path $PSScriptRoot\..\Resources\CertificateReporter.css
        $header = "<title>CertificateReport</title><style>$outputCss</style><h1>Certificate Reporter</h1>"
        $footer = "Original concept by Guy Bachar and Yoav Barzilay, new realization by Amanda Debler"
        $outputData = @()
    }
    
    process {
        foreach ($reportDataElement in $reportData) {
            $outputData += $reportDataElement
        }
    }
    
    end {
        $outputData | ConvertTo-Html -Head $header -PostContent $footer | Out-File $outputFilePath
    }
}