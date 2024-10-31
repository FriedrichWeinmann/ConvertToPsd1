class Converter {
	[object] $Cmdlet
	[bool] $ThrowOnUnknown
	[bool] $Terminate
	[int] $Depth

	Converter([object]$Cmdlet, [bool] $ThrowOnUnknown, [bool] $Terminate, [int]$Depth) {
		$this.Cmdlet = $Cmdlet
		$this.ThrowOnUnknown = $ThrowOnUnknown
		$this.Terminate = $Terminate
		$this.Depth = $Depth
	}

	[string] ConvertValue([object] $Value, [object[]]$Parents, [int]$Depth) {
		# Those number-thingies
		if ($Value -is [int] -or $Value -is [long] -or $Value -is [double]) {
			return '{0}' -f $Value
		}

		# Case: Bool
		if ($Value -is [bool] -or $Value -is [System.Management.Automation.SwitchParameter]) {
			return '${0}' -f $Value
		}

		# Case: Null
		if ($null -eq $Value -or $Value -is [System.DBNull]) {
			return '$null'
		}

		# Case: DateTime
		if ($Value -is [datetime]) {
			return "'{0:yyyy-MM-dd HH:mm:ss.fffff zzz}'" -f $Value.ToUniversalTime()
		}

		# Case: Guid
		if ($Value -is [guid]) {
			return "'$Value'"
		}

		# Case: Version
		if ($Value -is [version]) {
			return "'$Value'"
		}

		# Case: String
		if ($Value -is [string] -or $Value -is [char] -or $Value -is [System.Uri]) {
			return '''{0}''' -f ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($Value))
		}

		# Case: Hashtable
		if ($Value -is [System.Collections.IDictionary]) {
			return $this.ConvertHashtable($Value, $Parents, $Depth)
		}

		# Case: IEnumerable
		if ($Value -is [System.Collections.IEnumerable]) {
			$oldIndent = '    ' * $Depth
			$newIndent = '    ' * ($Depth + 1)
			$newParent = @($Parents) + ,$Value
			$pieces = @("@(")
			
			foreach ($entry in $Value) {
				$pieces += $newIndent + $this.ConvertValue($entry, $newParent, $Depth)
			}

			$pieces += "$oldIndent)"
			return $pieces -join "`n"
		}

		# Case: Enum
		if ($Value -is [enum]) {
			return "'{0}'" -f ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($Value))
		}

		# Case: Assembly
		if ($Value -is [System.Reflection.Assembly] -or $Value -is [System.Reflection.TypeInfo]) {
			return "'{0}'" -f $Value.FullName
		}

		if ($Value -is [System.Management.Automation.ProviderInfo] -or $Value -is [System.Management.Automation.PSDriveInfo]) {
			return "'{0}'" -f $Value.Name
		}

		# Case: PSCustomObject
		if ($Value -is [PSCustomObject] -or $Value.PSObject.Properties.Count -gt 0) {
			return $this.ConvertPSCustomObject($Value, $Parents, $Depth)
		}

		$message = "Unexpected data entry: $Value ($($Value.GetType().FullName))"
		if ($this.ThrowOnUnknown -or $this.Terminate) {
			if ($null -eq $this.Cmdlet) {
				throw $message
			}

			$record = [System.Management.Automation.ErrorRecord]::new(
				[System.Management.Automation.ParseException]::new($message),
				'BadData',
				[System.Management.Automation.ErrorCategory]::ParserError,
				$Value
			)
			if ($this.Terminate) {
				$this.Cmdlet.ThrowTerminatingError($record)
			}
			$this.Cmdlet.WriteError($record)
		}
		$this.Cmdlet.WriteWarning($message)
		return "'{0}'" -f ("$Value" -replace "'", "''")
	}

	[string] ConvertHashtable([System.Collections.IDictionary]$Value, [object[]]$Parents, [int]$Depth) {
		if ($Value -in $Parents) { return "'System.Collections.Hashtable (recursed)'" }
		$newDepth = $Depth + 1
		if ($this.Depth -gt 0 -and $newDepth -gt $this.Depth) { return "'System.Collections.Hashtable'" }
		$oldIndent = '    ' * $Depth
		$newIndent = '    ' * $newDepth
		
		$newParents = @($Parents) + $Value
		$lines = @("$oldIndent@{")
		foreach ($entry in $Value.GetEnumerator()) {
			if ($Parents[-1] -is [System.IO.FileSystemInfo] -and $entry.Key -in 'Root', 'Parent', 'Directory') {
				$lines += '{2}{0} = ''{1}''' -f $entry.Key, $entry.Value, $newIndent
				continue
			}
			$lines += '{2}{0} = {1}' -f $entry.Key, $this.ConvertValue($entry.Value, $newParents, $newDepth), $newIndent
		}

		$lines += "$oldIndent}"
		return $lines -join "`n"
	}

	[string] ConvertPSCustomObject([object]$Value, [object[]]$Parents, [int]$Depth) {
		if ($Value -in $Parents) { return "'$($Value.GetType().FullName) (recursed)'" }
		if ($this.Depth -gt 0 -and $Depth -ge $this.Depth) { return "'$($Value.GetType().FullName)'" }
		
		$newParents = @($Parents) + $Value

		$hash = [ordered]@{}
		foreach ($property in $Value.PSObject.Properties) {
			$hash[$property.Name] = $property.Value
		}
		return $this.ConvertHashtable($hash, $newParents, $Depth)
	}

	[string] Convert([object]$Value) {
		if ($Value -is [System.Collections.IDictionary]) {
			return $this.ConvertHashtable($Value, @(), 0)
		}
		if ($Value -isnot [PSCustomObject]) {
			return $this.ConvertValue($Value, @(), 0)
		}
		return $this.ConvertPSCustomObject($Value, @(), 0)
	}
}