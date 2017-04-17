#Get public and private function definition files.
    $Classes = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue | where {$_.BaseName -notmatch "-"} )
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*-*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

. $PSScriptRoot\Public\Convert-StringToDateTime.ps1
. $PSScriptRoot\Public\CreateHtmFile.ps1
. $PSScriptRoot\Public\Get-CRCertificate.ps1
. $PSScriptRoot\Public\Get-CRSkypeCertCollection.ps1
. $PSScriptRoot\Public\Get-CRSkypeServerList.ps1
. $PSScriptRoot\Public\Get-CRExchangeServerList.ps1
. $PSScriptRoot\Public\Write-CRReport.ps1
<#
#Import classes first
    Foreach($import in @($Classes))
    {
        Try
        {
            . $import.fullname
            Write-Information "Imported class $($import.fullname): $_"
        }
        Catch
        {
            Write-Error -Message "Failed to import class $($import.fullname): $_"
        }
    }

#Dot source the files
    Foreach($import in @($Private+$Public))
    {
        Try
        {
            . $import.fullname
            Write-Information "Imported function $($import.fullname): $_"
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }
#>
# Here I might...
    # Read in or create an initial config file and variable
    # Export Public functions ($Public.BaseName) for WIP modules
    # Set variables visible to the module and its functions only
Export-ModuleMember -Function $Classes.Basename
Export-ModuleMember -Function $Public.Basename
