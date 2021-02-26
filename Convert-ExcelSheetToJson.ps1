<#
.SYNOPSIS
Converts an Excel sheet from a workbook to JSON

.DESCRIPTION
To allow for parsing of Excel Workbooks suitably in PowerShell, this script converts a sheet from a spreadsheet into a JSON file of the same structure as the sheet.

.PARAMETER InputFile
The Excel Workbook file to be converted.

.PARAMETER OutputFileName
The path to a JSON file to be created.

.PARAMETER SheetName
The name of the sheet from the Excel Workbook to convert. If only one sheet exists, it will convert that one.

.EXAMPLE
Convert-ExcelSheetToJson -InputFile MyExcelWorkbook.xlsx

.EXAMPLE 
Get-Item MyExcelWorkbook.xlsx | Convert-ExcelSheetToJson -OutputFileName MyConvertedFile.json -SheetName Sheet2
#>
[CmdletBinding()]
Param(    
    [Object]$InputFile,

    [Parameter()]
    [string]$OutputFileName,

    [Parameter()]
    [string]$SheetName
    )

#region prep
# Check what type of file $InputFile is, and update the variable accordingly
if ($InputFile -is "System.IO.FileSystemInfo") {
    $InputFile = $InputFile.FullName.ToString()
}
# Make sure the input file path is fully qualified
$InputFile = [System.IO.Path]::GetFullPath($InputFile)
Write-Output "Converting '$InputFile' to JSON"

# If no OutputfileName was specified, make one up
if (-not $OutputFileName) {
    $OutputFileName = [System.IO.Path]::GetFileNameWithoutExtension($(Split-Path $InputFile -Leaf))
    $OutputFileName = Join-Path $pwd ($OutputFileName + ".json")
}
# Make sure the output file path is fully qualified
$OutputFileName = [System.IO.Path]::GetFullPath($OutputFileName)

# Instantiate Excel
$excelApplication = New-Object -ComObject Excel.Application
$excelApplication.DisplayAlerts = $false
$Workbook = $excelApplication.Workbooks.Open($InputFile)
$SheetCount = $Workbook.Sheets.Count
# If SheetName wasn't specified, make sure there's only one sheet

Write-Verbose "Outputting sheet count '$SheetCount' "
#endregion prep

#iterate sheets
$resultsForAllSheets = New-Object -TypeName psobject

for($sheetNumber=0; $sheetNumber -lt $SheetCount;$sheetNumber++) 
{
# Grab the sheet to work with
$theSheet = @($Workbook.Sheets)[$sheetNumber]
$theSheetName = @($Workbook.Sheets)[$sheetNumber].Name
#results for one sheet
$results =@()
#region headers
# Get the row of headers
$Headers = @{}
$NumberOfColumns = 0
$FoundHeaderValue = $true
while ($FoundHeaderValue -eq $true) {
    $cellValue = $theSheet.Cells.Item(1, $NumberOfColumns+1).Text
    if ($cellValue.Trim().Length -eq 0) {
        $FoundHeaderValue = $false
    } else {
        $NumberOfColumns++
        $Headers.$NumberOfColumns = $cellValue
    }
}
#endregion headers

# Count the number of rows in use, ignore the header row
$rowsToIterate = $theSheet.UsedRange.Rows.Count

#region rows

foreach ($rowNumber in 2..$rowsToIterate+1) {
    if ($rowNumber -gt 1) {
        $result = @{}
        foreach ($columnNumber in $Headers.GetEnumerator()) {
            $ColumnName = $columnNumber.Value
            $CellValue = $theSheet.Cells.Item($rowNumber, $columnNumber.Name).Value2
            $result.Add($ColumnName,$cellValue)
        }
        $results+=$result
    }
}
$resultsAsJson = $results|ConvertTo-Json
Write-Output $resultsAsJson
#endregion rows

$resultsForAllSheets | Add-Member -MemberType NoteProperty -Name $theSheetName -Value $results

}

$resultsForAllSheets | ConvertTo-Json | Out-File -Encoding ASCII -FilePath $OutputFileName

Get-Item $OutputFileName

# Close the Workbook
$excelApplication.Workbooks.Close()
# Close Excel
[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelApplication)