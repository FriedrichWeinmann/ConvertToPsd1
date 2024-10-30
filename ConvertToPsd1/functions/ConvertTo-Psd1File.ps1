function ConvertTo-Psd1File {
	<#
	.SYNOPSIS
		Converts json files to psd1.
	
	.DESCRIPTION
		Converts json files to psd1.
		The psd1 file will be placed in the same path under the same name with just the extension updated.
	
	.PARAMETER Path
		Path to the files to convert.

	.PARAMETER OutPath
		Path where the resultant file should be placed.
		By default, it will be placed in the same path as the source file.

	.PARAMETER Depth
		How deeply nested information will be picked up.
		This command will automatically prevent infinite recursion, even without the -Depth parameter.
	
	.PARAMETER WriteError
		If the object in the input file has any issues, should an error be generated?
		Otherwise, just a warning will be given.
		Note: ErrorAction stop will always lead to terminating errors in case of parsing issues.
	
	.EXAMPLE
		PS C:\> Get-ChildItem -Path . -Filter *.json | ConvertTo-Psd1File

		Converts all json files in the current directory to psd1.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,

		[string]
		$OutPath,

		[int]
		$Depth,

		[switch]
		$WriteError
	)
	
	begin {
		$converter = [converter]::new($PSCmdlet, $WriteError, ($ErrorActionPreference -eq 'Stop'), $Depth)
	}
	process {
		foreach ($filePath in $Path) {
			$item = Get-Item -Path $filePath
			$data = Get-Content -LiteralPath $item.FullName | ConvertFrom-Json
			$lines = foreach ($entry in $data) {
				$converter.Convert($entry)
			}
			if ($OutPath) { $exportPath = Join-Path -Path $OutPath -ChildPath "$($item.BaseName).psd1" }
			else { $exportPath = Join-Path -Path $item.DirectoryName -ChildPath "$($item.BaseName).psd1" }
			$lines | Set-Content -LiteralPath $exportPath
		}
	}
}