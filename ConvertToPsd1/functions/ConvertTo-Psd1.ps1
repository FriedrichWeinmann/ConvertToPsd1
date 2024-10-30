function ConvertTo-Psd1 {
	<#
	.SYNOPSIS
		Converts objects into psd1 string.
	
	.DESCRIPTION
		Converts objects into psd1 string.
	
	.PARAMETER InputObject
		The item(s) to convert
	
	.PARAMETER Depth
		How deeply nested information will be picked up.
		This command will automatically prevent infinite recursion, even without the -Depth parameter.
	
	.PARAMETER WriteError
		If the object in the input file has any issues, should an error be generated?
		Otherwise, just a warning will be given.
		Note: ErrorAction stop will always lead to terminating errors in case of parsing issues.
	
	.EXAMPLE
		PS C:\> Get-ChildItem | ConvertTo-Psd1

		Converts all files & folders in the current path to a psd1-string representing its contents.
		Each file processed separately.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[object[]]
		$InputObject,

		[int]
		$Depth,

		[switch]
		$WriteError
	)
	begin {
		$converter = [converter]::new($PSCmdlet, $WriteError, ($ErrorActionPreference -eq 'Stop'), $Depth)
	}
	process {
		foreach ($item in $InputObject) {
			$converter.Convert($item)
		}
	}
}