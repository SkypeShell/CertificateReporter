<#
.SYNOPSIS
    Creates a new, empty file for the report to be written to
.DESCRIPTION
    This cmdlet is not exported from the module because we want to be able to change
    its behavior on a whim
.EXAMPLE
    CreateHtmFile
    # Creates a file in c:\temp, named SfBCertReport-yyyy_MM_dd-HH_mm.htm
.EXAMPLE
    CreateHtmFile -Directory 'D:\SkypeReports'
    # Creates a file in D:\SkypeReports, SfBCertReport-yyyy_MM_dd-HH_mm.htm
.EXAMPLE
    CreateHtmFile -Path 'D:\SkypeReports\TheReportForTheConsultants.htm'
#>
function CreateHtmFile {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $outputDirectory="C:\temp",
        [Parameter(Mandatory=$false)]
        [string]
        $outputFileName
    )
    
    begin {
    }
    
    process {
        if ($outputFileName) {
            $ServicesFileName = $outputFileName
        } else {
            $FileDate = "{0:yyyy_MM_dd-HH_mm}" -f (get-date)
            $ServicesFileName = $outputDirectory+"\SfBCertReport-"+$FileDate+".htm"
        }
    $HTMLFile = New-Item -ItemType file $ServicesFileName -Force
    return $HTMLFile
    }
    
    end {
    }
}