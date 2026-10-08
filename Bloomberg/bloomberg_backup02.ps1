

<#
.SYNOPSIS
Obtain the token from Bloomberg server
Exports yesterday's Bloomberg market data file to CSV.

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
    [string]$ApiKey = $env:BLOOMBERG_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$TimeZoneId = "AUS Eastern Standard Time",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Global", "AU")]
    [string]$ApiRegion = "AU"
)


$Catalog = "67974"

$BloombergFiles = @(
	[PSCustomObject]@{
		RequestName = "isin"
		#RequestId = "isinDataReqV1"
		RequestId = "uAnQP5HXaZXZ"
	}
	
	[PSCustomObject]@{
		RequestName = "cashBBSW"
		#RequestId = "cashBBSWReqV1"
		RequestId = "uTDFLNiSLxLe"
	}
	
	[PSCustomObject]@{
		RequestName = "globalMarkets"
		#RequestId = "globalMarketsReqV1"
		RequestId = "uKKoQTvXrq22"
	}
	
	[PSCustomObject]@{
		RequestName = "counterpartyData"
		#RequestId = "counterpartyDataReqV1"
		RequestId = "uAvmWVwmEV5g"
	}
	
	[PSCustomObject]@{
		RequestName = "futures"
		#RequestId = "futuresDataReqV1"
		RequestId = "uh6gfJEtgqdP"
	}
	
	[PSCustomObject]@{
		RequestName = "swaps"
		#RequestId = "swapsDataReqV1"
		RequestId = "uMu4EPM7d4wg"
	}
	
	[PSCustomObject]@{
		RequestName = "overnightIndexSwaps"
		#RequestId = "onIndexSwapsDataReqV1"
		RequestId = "uZeqogxxHtoa"
	}
	
	[PSCustomObject]@{
		RequestName = "basis3s1s"
		#RequestId = "basis3s1sDataReqV1"
		RequestId = "uERmT1caJ7qu"
	}
	
	[PSCustomObject]@{
		RequestName = "basis6s3s"
		#RequestId = "basis6s3sDataReqV1"
		RequestId = "uR2vnNa6UV95"
	}
	
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
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)




Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# To be set up in the environment
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

if ([string]::IsNullOrWhiteSpace($Token)) {
		 throw "Cannot continue because no access token was obtained"
		}

foreach ($Request in $BloombergFiles) {

	$OutputFileName = "$($Request.RequestName)-$YesterdayLocalDate-$($Request.RequestId).csv" 
	
	Write-Host "Processing:    $($request.RequestName)"

	[string]$OutputPath = (
			Join-Path $PWD (
				$OutputFileName
			)
	)

	$Endpoint = "$($ApiBaseUrls[$ApiRegion])/eap/catalogs/$($Catalog)/content/responses/$($OutputFileName)"

	Write-Host "Endpoint $Endpoint"

	$Headers = @{
		"Accept"                = "application/json"
		"Content-Type"          = "application/json"
		"Authorization"         = "Bearer $Token"
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
				
		Write-Host "CSV file : $OutputPath"
		Write-Host "Record count: $($CsvData.Count)"
		}


	if (
		-not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
		-not (Test-Path -LiteralPath $OutputDirectory)
	) {
		New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
	}

}

$EndDate = [datetimeoffset]::new(
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)


Write-Host "Bloomberg Data Extract completed."
Write-Host "Timezone:    $($TimeZone.DisplayName)"
Write-Host "Start:       $($StartDate.ToString('o'))"
Write-Host "End:         $($EndDate.ToString('o'))"
