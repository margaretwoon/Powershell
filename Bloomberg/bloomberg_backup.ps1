

<#
.SYNOPSIS
Obtain the token from bloomberg server
Exports yesterday's bloomberg data file, bounced, and spam bloomberg events to CSV.

.NOTES
- "Yesterday" is calculated using the timezone specified in $TimeZoneId.
- On Windows, use a Windows timezone ID such as:
    "AUS Eastern Standard Time"
- On Linux/macOS, use an IANA timezone ID such as:
    "Australia/Sydney"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:SMTP2GO_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (
        Join-Path $PWD (
            "bloomberg-failed-events-{0}.csv" -f (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
        )
    ),

    [Parameter(Mandatory = $false)]
    [string]$TimeZoneId = "AUS Eastern Standard Time",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Global", "AU")]
    [string]$ApiRegion = "AU"
)

try {
    $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneId)
}
catch {
    throw "Timezone '$TimeZoneId' was not found on this computer. $($_.Exception.Message)"
}

# Calculate yesterday's local midnight and today's local midnight.
$NowInTimeZone = [System.TimeZoneInfo]::ConvertTime(
    [System.DateTimeOffset]::UtcNow,
    $TimeZone
)

$TodayLocal = [datetime]::SpecifyKind(
    $NowInTimeZone.Date,
    [System.DateTimeKind]::Unspecified
)

$YesterdayLocal = $TodayLocal.AddDays(-1)

$YesterdayLocalDate = $YesterdayLocal.ToString("yyyyMMdd")

# Create DateTimeOffset values using the UTC offset that applied at each
# midnight. Calculating both offsets separately handles daylight-saving changes.
$StartDate = [datetimeoffset]::new(
    $YesterdayLocal,
    $TimeZone.GetUtcOffset($YesterdayLocal)
)

$EndDate = [datetimeoffset]::new(
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)



Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ClientId = "3d7df1b4db611560c238faaf9ee72cd4"

$ClientSecret = "80ec5afbe48881f67f59d3128c8aab6ff08bca65050e1634613bced4a7a96fb0"

$Credentials = "${ClientId}:${ClientSecret}"

$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Credentials)

$Base64Credentials = [Convert]::ToBase64String($Bytes)


$TokenHeaders = @{
    "Accept"                = "*/*"
    "Content-Type"          = "application/json"
	"Authorization"         = "Basic $Base64Credentials"
}

$TokenBody = @{
	grant_type = "client_credentials"
}


$Token = $null
$Attempt = 0
$MaximumAttempts = 3

$tokenResponse = $null

do {
    $Attempt++

    try {
        Write-Host "Getting Bloomberg token - attempt $Attempt"

        $TokenResponse = Invoke-RestMethod `
            -Uri "https://bsso.blpprofessional.com/ext/api/as/token.oauth2" `
            -Method POST `
            -Headers $TokenHeaders `
            -ContentType "application/x-www-form-urlencoded" `
            -Body $TokenBody `
            -ErrorAction $ErrorActionPreference

        # Get access token
        $Token = $TokenResponse.access_token

        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw "Token endpoint returned no access_token."
        }

        Write-Host "Access token obtained successfully."

        # Success - leave the DO loop
        break
    }
    catch {
        Write-Host "Token request failed." 
        Write-Host "Error: $($_.Exception.Message)"
     

        if ($_.Exception.PSObject.Properties.Name -contains "Response") {
            if ($null -ne $_.Exception.Response) {
                Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)"
            }
        }

        if ($Attempt -ge $MaximumAttempts) {
            throw
        }

        Write-Host "Re-try again in 2 seconds..."
        Start-Sleep -Seconds 2
    }

} while ($Attempt -lt $MaximumAttempts)

# Select the regional API endpoint.
$ApiBaseUrls = @{
    Global = "https://api.bloomberg.com"
    AU     = "https://api.bloomberg.com"
  
}

$Catalog = "67974"

$RequestName = "swaps"

#$RequestId = "swapsDataReqV1"

$RequestId = "uMu4EPM7d4wg"

$OutputFileName = "$RequestName-$YesterdayLocalDate-$RequestId.csv" 


[string]$OutputPath = (
        Join-Path $PWD (
            $OutputFileName
        )
)

$Endpoint = "$($ApiBaseUrls[$ApiRegion])/eap/catalogs/$($Catalog)/content/responses/$($OutputFileName)"

#Write-Host "Endpoint $Endpoint"

$Headers = @{
    "Accept"                = "application/json"
    "Content-Type"          = "application/json"
    "Authorization"         = "Bearer $Token"
}

if ([string]::IsNullOrWhiteSpace($Token)) {
     throw "Cannot continue because no access token was obtained"
    }
	
$MaximumAttempts = 5
$Attempt = 0
	
$ResponseData = $null
$RequestSuccessful = $false

while ($true) {
 
    $Attempt++

    try {
		$Response = Invoke-RestMethod `
			-Method GET `
			-Uri $Endpoint `
			-Headers $Headers `
			-TimeoutSec 120 `
			-ErrorAction $ErrorActionPreference
				
		$ResponseData = $Response
		
		#Write-Host "Response $Response"
			
		if ([string]::IsNullOrWhiteSpace($ResponseData)) {
			throw "Bloomberg returned an empty response."
		}
		
		$RequestSuccessful = $true

		Write-Host "Bloomberg response received successfully for $($OutputFileName)."
		
		break
		}
        
		catch {
            $StatusCode = $null
			
			Write-Warning "Request failed : $($_.Exception.Message)"
			
			if ($_.Exception.PSObject.Properties.Name -contains "Response") {
				if ($null -ne $_.Exception.Response) {
					$StatusCode = [int]$_.Exception.Response.StatusCode
				}
			}

            $RetryableStatusCodes = @(429, 500, 502, 503, 504)

            if (
                $Attempt -ge $MaximumAttempts -or
                $StatusCode -notin $RetryableStatusCodes
            ) {
                throw
            }

            $DelaySeconds = [math]::Pow(2, $Attempt)
            Write-Warning (
                "Bloomberg returned HTTP {0}. Retrying in {1} seconds..." -f
                $StatusCode, $DelaySeconds
            )

            Start-Sleep -Seconds $DelaySeconds
        }
 }




if ($RequestSuccessful -and $null -ne $ResponseData) {

	$CsvData = $ResponseData | ConvertFrom-Csv

	Write-Host "Number of records : $($CsvData.Count)"
	
	$OutputDirectory = Split-Path -Parent $OutputPath
	
	if (
    -not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
    -not (Test-Path -LiteralPath $OutputDirectory)) {
		New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
	}


	#$CsvData | Format-Table

	$CsvData | Export-Csv `
            -Path $OutputPath `
			-NoTypeInformation `
			-Encoding UTF8
			
	Write-Host "CSV saved to : $OutputPath"
	}


if (
    -not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
    -not (Test-Path -LiteralPath $OutputDirectory)
) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}


#Write-Host "Token : $Token"
Write-Host "Bloomberg token complete."
Write-Host "Endpoint:    $($Endpoint)"
Write-Host "Timezone:    $($TimeZone.DisplayName)"
Write-Host "Start:       $($StartDate.ToString('o'))"
Write-Host "End:         $($EndDate.ToString('o'))"
Write-Host "Record count: $($CsvData.Count)"
Write-Host "CSV file:    $OutputPath"