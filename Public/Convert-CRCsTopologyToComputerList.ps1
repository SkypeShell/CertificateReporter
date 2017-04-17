<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Depends on my previous Get-CsTopologyFixed if you don't provide a CsTopology file
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Convert-CRCsTopologyToComputerList {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    
    begin {
    }
    
    process {
        
    }
    
    end {
    }
}