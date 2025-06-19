Describe "M3U URL Validation" {
    BeforeDiscovery {
        $rootDir = "$PSScriptRoot/../.."
        $m3uFiles = Get-ChildItem -Path $rootDir -Recurse -Filter "*.m3u"
        Write-Verbose "Discovering URLs to validate in M3U files..."
        # Create a hashtable to store URLs and their source files
        $urlMap = [hashtable]@{}
        $m3uFiles | ForEach-Object {
            $file = $_
            $urls = Get-Content $file.FullName | Where-Object { 
                [Uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute) 
            }
            
            foreach ($url in $urls) {
                if (-not $urlMap.ContainsKey($url)) {
                    $urlMap[$url] = @()
                }
                $urlMap[$url] += $file.FullName
            }
        }
        # side note: I HATE using global variables, but this is the only way
        # to share state between BeforeDiscovery and AfterEach since all other
        # scopes are sandboxed in Pester
        # see https://stackoverflow.com/q/66806373/1396477
        $global:urlsToTest = $urlMap.Keys | ForEach-Object {
            [PSCustomObject]@{
                Url = $_
                Files = $urlMap[$_]
            }
        }
        $global:urlTestsCompleted = 0
    }

    BeforeAll {
        function Test-Url {
            param(
                [string]$Url
            )
            try {
                $response = Invoke-WebRequest -Uri $Url -Method Head
                return $response.StatusCode -eq 200
            }
            catch {
                # Log more specific error information
                $errorType = $_.Exception.GetType().Name
                $errorMessage = $_.Exception.Message
                Write-Warning "Failed to access $Url - $errorType : $errorMessage"
                return $false
            }
        }
    }

    It "<_.Url> should be accessible" -ForEach $global:urlsToTest {
        Test-Url -Url $_.Url | Should -Be $true -Because "it is referenced in $($_.Files -join ', ')"
    }

    AfterEach {
        # without a progress bar, there is no way to know whether the tests
        # are running or if Pester is stuck. With over 4000 URLs to test,
        # this will take a while, so we need to show progress
        $global:urlTestsCompleted++
        Write-Progress -Activity "Validating URLs" `
            -Status "$global:urlTestsCompleted / $($global:urlsToTest.Count)" `
            -PercentComplete (($global:urlTestsCompleted / $global:urlsToTest.Count) * 100)
    }
}
