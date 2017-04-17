Describe "Tests Get-CRCertificate" {
    Context "Skype Federation (port 5061) certificate from Microsoft" {
        $EdgeCertificate = Get-CRCertificate -ComputerName 'sipfed.microsoft.com' -Port 5061 -ComponentType 'Skype Federation External'
        It "contains the expected computer name" {
            $EdgeCertificate.ComputerName | Should Be 'sipfed.microsoft.com'
        }
        It "is still valid" {
            $EdgeCertificate.DaysUntilExpiration -gt 5 | Should Be $true
        }
        It "contains subject alternate names" {
            $EdgeCertificate.SubjectAlternateNames.split(',').count -gt 1 | Should Be $true
        }
    }
}