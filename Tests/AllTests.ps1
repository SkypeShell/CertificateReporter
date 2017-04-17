Import-Module $PSScriptRoot\..\CertificateReporter -Force
(Get-Module CertificateReporter).LogPipelineExecutionDetails = $true
. $PSScriptRoot\Get-CRCertificate.Tests.ps1
. $PSScriptRoot\Write-CRReport.Tests.ps1
. $PSScriptRoot\Integration.Tests.ps1
Remove-Module CertificateReporter