# Adapted from Alex Limousin - https://gallery.technet.microsoft.com/scriptcenter/Convert-String-To-Date-6c35e7ff
# Needed to deal with [DateTime] type accelerator not playing nice with non en-US date formats

function convert-StringToDateTime{
    Param(
        [String]$DateTimeString
    )
    $DateTimeParts = $DateTimeString -split ' '
	
    $DateParts = $DateTimeParts[0] -split '/|-|\.'

    $DateFormatParts = (Get-Culture).DateTimeFormat.ShortDatePattern -split '/|-|\.'
    $Month_Index = ($DateFormatParts | Select-String -Pattern 'M').LineNumber - 1
    $Day_Index = ($DateFormatParts | Select-String -Pattern 'd').LineNumber - 1
    $Year_Index = ($DateFormatParts | Select-String -Pattern 'y').LineNumber - 1	
	
    $TimeParts = $DateTimeParts[1..$($DateTimeParts.Count - 1)]
	
    if (@($TimeParts).Count -eq 2)
    {
        $TimeFormatParts = (Get-Culture).DateTimeFormat.ShortTimePattern -split ' '
        
        $TT_Index = ($TimeFormatParts | Select-String -Pattern 't').LineNumber - 1
        $Time_Index = 1 - $TT_Index
            
        $Time = $TimeParts[$Time_Index,$TT_Index] -join ' '
    }
    else
    {
        $Time = $TimeParts
    }
        
    $DateTime = [DateTime] $($($DateParts[$Month_Index,$Day_Index,$Year_Index] -join '/') + ' ' + $Time)

        return $DateTime
}