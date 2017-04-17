Param(
[String]$SkypeFrontEndServer,
[PSCredential]$SkypeAdminCredential
)

Describe "Tests functions together" {
    Context "Sample data" {
        $TestSystems = @( @{computerName='sipfed.microsoft.com';port=5061;componentType='Skype Federation'}
            , @{computerName='www.github.com';port=443;componentType='Web Server'}
        )
        $ReportData = foreach ($system in $TestSystems) { Get-CRCertificate @system }
        Write-CRReport -ReportData $ReportData -OutputFilePath 'C:\temp\Integration.htm'
        It "writes the certificates out to HTML" {
            'C:\Temp\Integration.htm' | Should Contain "sipfed.microsoft.com"
        }
    }
    Context "Live data from Skype" {
        $ReportData = Get-CRSkypeCertCollection -SkypeFrontEndServer $SkypeFrontEndServer -SkypeAdminCredential $SkypeAdminCredential
        Write-CRReport -ReportData $ReportData -OutputFilePath 'C:\temp\yaaaaas.htm'
        It "contains one of our Skype servers" {
            'C:\temp\yaaaaas.htm' | Should Contain "$SkypeFrontEndServer"
        }
    }
}