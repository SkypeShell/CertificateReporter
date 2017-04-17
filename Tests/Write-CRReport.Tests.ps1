Describe "Tests Write-CRReport" {
    Write-CRReport -ReportData (Get-Service) -outputFilePath 'c:\temp\write-crreport.tests.htm'
    It "writes a file to 'c:\temp\write-crreport.tests.htm' with 'CertificateReport' in it" {
        'c:\temp\write-crreport.tests.htm' | Should Contain 'CertificateReport'
    }
    It "writes some CSS in that file" {
        'C:\Temp\write-crreport.tests.htm' | Should Contain '<style>td {'
    }
}