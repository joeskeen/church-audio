#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $false)]
    [switch]$CI = $false
)

$config = New-PesterConfiguration -Hashtable @{
    Run = @{
        Path = "$PSScriptRoot/tests"
        Exit = $true  # Exit with error code on test failure
    }
    Output = @{
        Verbosity = $CI ? 'Detailed' : 'Normal'
    }
}

Invoke-Pester -Configuration $config
