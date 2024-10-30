# ConvertToPsd1

Welcome to the utility powershell module `ConvertToPsd1`.
Your one short stop to converting to psd1 format.

## Install

To install the module, run either of those, depending on your PowerShell version:

```powershell
# PS 5.1
Install-Module ConvertToPsd1 -Scope CurrentUser

# PS 7.4+
Install-PSResource ConvertToPsd1
```

## Profit

Time to get it on with generating psd1 content:

```powershell
Get-ChildItem | ConvertTo-Psd1
```

Converts all files & folders in the current path to a psd1-string representing its contents.
Each file processed separately.

```powershell
Get-ChildItem -Path . -Filter *.json | ConvertTo-Psd1File
```

Converts all json files in the current directory to psd1.
