

<#
.SYNOPSIS
1. Obtain the token from Bloomberg server, endpoint 
https://bsso.blpprofessional.com/ext/api/as/token.oauth2

2. Exports yesterday's Bloomberg market data file to CSV the following endpoints

Weekly
https://api.bloomberg.com/eap/catalogs/67974/content/responses/swaps-yyyyMMdd-swapsDataReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/futures-yyyyMMdd-futuresDataReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/overnightIndexSwaps-yyyyMMdd-onIndexSwapsDataReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/globalMarkets-yyyyMMdd-globalMarketsReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/counterpartyData-yyyyMMdd-counterpartyDataReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/cashBBSW-yyyyMMdd-cashBBSWReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/basis6s3s-yyyyMMdd-basis6s3sDataReqV1.csv
https://api.bloomberg.com/eap/catalogs/67974/content/responses/basis3s1s-yyyyMMdd-basis3s1sDataReqV1.csv



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

# Select the regional API endpoint.
$ApiBaseUrls = @{
    Global = "https://gsb-test.archerirm.com.au"
    AU     = "https://gsb-test.archerirm.com.au"
  
}

# The collection of requestName and requestId sits in a json file
#$Config = Get-Content ".\bloomberg_parameters.json" -Raw | ConvertFrom-Json

#$Catalog = $Config.catalog

#$Requests = $Config.collections.$RunFrequency

$UserId = 3289
		

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

$TomorrowLocal = $TodayLocal.AddDays(1)

$TomorrowLocalDate = $TomorrowLocal.ToString("yyyy-MM-dd")

# Create DateTimeOffset values using the UTC offset that applied at each
# midnight. Calculating both offsets separately handles daylight-saving changes.
$StartDate = [datetimeoffset]::new(
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)



Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# To be set up in the environment and comment out these lines
$InstanceName = "710144"
$Username     = "databricks_service_test"
$UserDomain   = "Test"
$Password     = "Archer@123!!"


function Get-ArcherSessionToken {
	param (
		[Parameter(Mandatory = $true)]
		[string]$BaseUrl,
		
		[Parameter(Mandatory = $true)]
		[hashtable]$TokenHeaders,
		
		[Parameter(Mandatory = $true)]
		[hashtable]$TokenBody,
		
		[int]$MaximumAttempts = 5
	)
	


	$TokenBodyJson = $TokenBody | ConvertTo-Json

	$Session_Token = $null
	$Attempt = 0

	$tokenResponse = $null

	do {
		$Attempt++

		try {
			Write-Host "Getting Archer session token - attempt $Attempt"
			
			$LoginUrl = "$BaseUrl/platformapi/core/security/login"
			
			Write-Host "Login Url : $LoginUrl"

			$TokenResponse = Invoke-RestMethod `
				-Uri $LoginUrl `
				-Method POST `
				-Headers $TokenHeaders `
				-ContentType "application/json" `
				-Body $TokenBodyJson `
				-ErrorAction $ErrorActionPreference

			# Get Session token
			$Session_Token = $TokenResponse.RequestedObject.SessionToken
			
			Write-host "Session_Token $Session_Token"
		

			if ([string]::IsNullOrWhiteSpace($Session_Token)) {
				throw "Session Token endpoint returned no access_token."
			}

			Write-Host "Session Token obtained successfully."

			# Success - exit the DO loop
			return $Session_Token
		}
		catch {
			Write-Host "Session Token request failed." 
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
}

function Revoke-ArcherPATToken {
	param (
		[Parameter(Mandatory = $true)]
		[string]$BaseUrl,
		
		[Parameter(Mandatory = $true)]
		[hashtable]$TokenHeaders,
		
		[Parameter(Mandatory = $true)]
		[hashtable]$TokenBody,
		
		[int]$MaximumAttempts = 5
	)
	
	$RevokeSuccessful = $false

	$Attempt = 0
	$MaximumAttempts = 5

	do {
		$Attempt++

		try {
			Write-Host "Revoke PAT ID $PAT_id - attempt $Attempt"
			
			$RevokeBodyJson = $Tokenbody | ConvertTo-Json

			$RevokeResponse = Invoke-RestMethod `
				-Uri "$BaseUrl/api/V2/PersonalAccessToken($PAT_id)" `
				-Method DELETE `
				-Headers $Headers `
				-ContentType "application/json" `
				-Body $RevokeBodyJson `
				-ErrorAction $ErrorActionPreference
		

			Write-Host "PAT Token ID $PAT_Id revoked successfully."
			
			$RevokeSuccessful = $true

			# Success - exit the DO loop
			return $RevokeSuccessful
		}
		catch {
			Write-Host "Revoke PAT ID $PAT_id revoke request failed " 
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

	} while ($Attempt -le $MaximumAttempts)
}


$TokenHeaders = @{
		"Accept"                = "application/json"
		"Content-Type"          = "application/json"
	}
	
	
$TokenBody = @{
		"InstanceName" = "$InstanceName"
		"Username"     = "$UserName"
		"UserDomain"   = "$UserDomain"
		"Password"     = "$Password"
}

$Session_Token = Get-ArcherSessionToken `
	-BaseUrl $ApiBaseUrls[$ApiRegion] `
	-Tokenheaders $TokenHeaders `
	-TokenBody $TokenBody
	

if ([string]::IsNullOrWhiteSpace($Session_Token)) {
		 throw "Cannot proceed with the collections because no Session Token was obtained"
		}


## Create a Personal Access Token

$PATHeaders = @{
	"Accept"                = "application/json"
	"Content-Type"          = "application/json"
	"Authorization"         = "Archer session-id=$Session_Token"

}


$PATBody = @{
	request = @{
    "UserId"		= $UserId
	"Name"			= "Archer API PAT Token"
	"Description"	= "Token for automated script"
	"ExpirationDate"= "$TomorrowLocalDate"
	
	}
}

$PATBodyJson = $PATBody | ConvertTo-Json


$PAT_Token = $null
$PAT_Id = $null
$Attempt = 0
$MaximumAttempts = 3

$PATTokenResponse = $null


do {
    $Attempt++

    try {
        Write-Host "Getting Archer PAT - attempt $Attempt"

        $PATTokenResponse = Invoke-RestMethod `
            -Uri "$($ApiBaseUrls[$ApiRegion])/api/V2/PersonalAccessToken/Create" `
            -Method POST `
            -Headers $PATHeaders `
            -ContentType "application/json" `
            -Body $PATBodyJson `
            -ErrorAction $ErrorActionPreference

        # Get PAT token
        $PAT_Token = $PATTokenResponse.Token
		
		$PAT_Id = $PATTokenResponse.Id
		
		Write-host "PAT Token $PAT_Token"
		Write-host "PAT Id    $PAT_Id"

        if ([string]::IsNullOrWhiteSpace($PAT_Token)) {
            throw "PAT Token endpoint returned no PAT_token."
        }

        Write-Host "PAT Token obtained successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "PAT Token request failed." 
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

} while ($Attempt -le $MaximumAttempts)

## Done Create a Personal Access Token




if ([string]::IsNullOrWhiteSpace($PAT_Token)) {
		 throw "Cannot proceed with the collections because no PAT Token was obtained"
		}
		
#############################################################################################
#############################################################################################
#############################################################################################

# Need to call Search to ensure the report_id exists before continue processing

# Search Report

$RequestHeaders = @{
	"Accept"                = "application/json"
	"Content-Type"          = "application/json"
	"Authorization"         = "Archer session-id=$PAT_Token"

}
$report_id = 12795

$RequestBody = $null

$RequestBodyJson = $RequestBody | ConvertTo-Json

$Attempt = 0
$MaximumAttempts = 3

$SearchSuccessful = $false

do {
    $Attempt++


    try {
        Write-Host "Proceeding Search Report - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/results?ReportId=$report_id&ViewType=Report&PageNum=0&PageSize=100&PerformFacetedSearch=false&IncludeAllContentIds=false"
		
		Write-Host "requestUrl $requestUrl"


        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -ErrorAction $ErrorActionPreference
		
		$SearchSuccessful = $true
		

        Write-Host "Request Search Report for Report $report_id successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Get Report Criteria request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ($SearchSuccessful -ne $true) {
		 throw "Cannot proceed with the collections because no Report $report_id found"
		}



#############################################################################################
#############################################################################################
#############################################################################################


# Get Report Criteria

$RequestHeaders = @{
	"Accept"                = "application/json"
	"Content-Type"          = "application/json"
	"Authorization"         = "Archer session-id=$PAT_Token"

}


$RequestBody = $null

$RequestBodyJson = $RequestBody | ConvertTo-Json

$Attempt = 0
$MaximumAttempts = 3

$ReportCriteria = $null



do {
    $Attempt++
	
	

    try {
        Write-Host "Proceeding Get Report Criteria - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/reportCriteria?reportId=$report_id"
		
		Write-Host "requestUrl $requestUrl"


        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -Body $RequestBodyJson `
            -ErrorAction $ErrorActionPreference

        # Get PAT token
        # $PAT_Token = $PATTokenResponse.Token
		
		#$ReportCriteria = $RequestResponse | ConvertTo-Json -Depth 100
		
		$ReportCriteria = $RequestResponse 
		
		#Write-host "Get Report Criteria Response : $ReportCriteria"

       # if ([string]::IsNullOrWhiteSpace($PAT_Token)) {
       #     throw "Request Get Report Criteria endpoint returned with Error."
       # }

        Write-Host "Request Get Report Criteria for Report $report_id successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Get Report Criteria request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ([string]::IsNullOrWhiteSpace($ReportCriteria)) {
		 throw "Cannot proceed with the collections because no Report Criteria was obtained"
		}


### Done API call to Get Report Details

#############################################################################################
#############################################################################################
#############################################################################################
# API call to get Report Details

$Attempt = 0
$MaximumAttempts = 5

$ReportDetails = $null

$RequestResponse = $null

do {
    $Attempt++
	
    try {
        Write-Host "Proceeding Get Report Details - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/reportDetails?reportIds=$report_id"
		
		Write-Host "requestUrl = $requestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -Body $RequestBodyJson `
            -ErrorAction $ErrorActionPreference
		
		#$ReportDetails = $RequestResponse | ConvertTo-Json -Depth 100
		
		$ReportDetails = $RequestResponse 
		
		#Write-host "Get Report Details Response : $ReportDetails"

        Write-Host "Request Get Report Details for Report $report_id successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Get Report Details request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ([string]::IsNullOrWhiteSpace($ReportDetails)) {
		 throw "Cannot proceed with the collections because no Report Details was obtained"
		}

# Done with API call to get Report Details

# End of Get Report Criteria

# Load Json from File
$RequestBodyPostExport = Get-Content ".\post_export_request_body.json" -Raw | ConvertFrom-Json

#Write-Host "The ReportDetails $ReportDetails"

$RequestBodyPostExport.requestParameters.reportPayload.reportDetail = $ReportDetails.reports[0]

$RequestBodyPostExport.requestParameters.reportPayload.reportCriteria = $ReportCriteria

$RequestBodyPostExportJson = $RequestBodyPostExport | ConvertTo-Json -Depth 100

#Write-Host "RequestExport $RequestBodyPostExport"

#### Begin Post Export API

$Attempt = 0
$MaximumAttempts = 5

$RequestResponse = $null

$ExportId = $null

$ExportDownloadable = $false

$ExportName = $null

do {
    $Attempt++
	
    try {
        Write-Host "Proceeding Post Export - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export"
		
		Write-Host "requestUrl = $requestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method POST `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -Body $RequestBodyPostExportJson `
            -ErrorAction $ErrorActionPreference
		
		
		$ExportId = $RequestResponse.exportId
		
		$ExportName = $RequestResponse.exportName
		
		Write-host "Post Export Response ExportId : $ExportId"

        Write-Host "Post Export successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Post Export request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ([string]::IsNullOrWhiteSpace($ExportId)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


#### End of Post Export API

#### Begin Get Export

$Attempt = 0
$MaximumAttempts = 100

$RequestResponse = $null

$ExportDownloadAvailable = $false

do {
    $Attempt++
	
    try {
        Write-Host "Checking report Downloadable - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export/$ExportId"
		
		Write-Host "requestUrl = $requestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -ErrorAction $ErrorActionPreference
			
		$ExportDownloadAvailable = $RequestResponse.isDownloadAvailable
		
		Write-host "Get Export Response ExportId : $ExportId"
		
		Write-host "isDownloadAvailable : $ExportDownloadAvailable"

        Write-Host "Post Export successfully."

        # Success - exit the DO loop
		if ($ExportDownloadAvailable -eq $true) {
			break
		}
		
		Write-Host "Export not ready. Waiting for 300 seconds...."
		Start-sleep -Seconds 300
    }
    catch {
        Write-Host "Get Export request failed." 
        Write-Host "Error: $($_.Exception.Message)"

        if ($Attempt -ge $MaximumAttempts) {
            throw
        }

        Write-Host "Re-try again in 300 seconds..."
        Start-Sleep -Seconds 300
    }

} while ($Attempt -lt $MaximumAttempts)


if ($ExportDownloadAvailable -ne $true) {
	throw "Export was not download after $MaximumAttempts"
}

#############################################################################################
#############################################################################################
#############################################################################################

# Get the download-Url

$Attempt = 0
$MaximumAttempts = 5

$RequestResponse = $null

$DownloadUrl = $null


do {
    $Attempt++
	
    try {
        Write-Host "Proceeding get Export Url - attempt $Attempt"
		
		$requestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export/$ExportId/download-url"
		
		Write-Host "requestUrl = $requestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -ErrorAction $ErrorActionPreference
		
		
		$DownloadUrl = $RequestResponse.downloadUrl
		
		Write-host "Get Export Response ExportId : $ExportId"
		
		#Write-host "Get Export Response DownloadUrl : $DownloadUrl"

        Write-Host "Get Export Url successfully."

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Get Export DownloadUrl request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################

## Download the file

# Get the download-Url

$Attempt = 0
$MaximumAttempts = 5

$RequestResponse = $null

$DownloadSuccessful = $false

do {
    $Attempt++
	
    try {
        Write-Host "Proceeding to download report - attempt $Attempt"
		
		$requestUrl = "$DownloadUrl"
		
		Write-Host "requestUrl = $requestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $requestUrl `
            -Method GET `
            -Headers $RequestHeaders `
            -ContentType "application/json" `
            -ErrorAction $ErrorActionPreference
		
		
		#Write-host "Download Report: $RequestResponse"

        Write-Host "Report downloaded successfully."
		
		$DownloadSuccessful = $true

        # Success - exit the DO loop
        break
    }
    catch {
        Write-Host "Download request failed." 
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

} while ($Attempt -le $MaximumAttempts)


if ([string]::IsNullOrWhiteSpace($RequestResponse)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


$OutputFileName = "$($ExportName).csv" 

$OutputFileName = $OutputFileName -replace '[\\/:*?"<>|]', '_'

[string]$OutputPath = (
			Join-Path $PWD (
				$OutputFileName
			)
	)

if ($DownloadSuccessful -and $null -ne $RequestResponse) {

	$CsvData = @($RequestResponse | ConvertFrom-Csv)

	Write-Host "Number of records in the file : $($CsvData.Count)"
	
	$OutputDirectory = Split-Path -Parent $OutputPath
	
	if (
	-not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
	-not (Test-Path -LiteralPath $OutputDirectory)) {
		New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
	}


	#$CsvData | Format-Table
	
	Write-Host "ExportName $ExportName"
	Write-Host "OutputFileName $OutputFileName"
	Write-Host "OutputPath $OutputPath"

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



######### End of Download Export

#############################################################################################
#############################################################################################
#############################################################################################	
		
################# House Keeping		
## Once we are done Processing Archer APIs - we should revoke the PAT for security 

$Session_Token = Get-ArcherSessionToken `
	-BaseUrl $ApiBaseUrls[$ApiRegion] `
	-Tokenheaders $TokenHeaders `
	-TokenBody $TokenBody

## Revoke PAT using PAT_ID

$Headers = @{
		"Accept"                = "application/json"
		"Content-Type"          = "application/json"
		"Authorization"         = "Archer session-id=$Session_Token"

	}

$RevokeBody = @{
	"request"= @{
		"UserId"			= $UserId
		"Name"				= "My Archer API Token"
		"Description"		= "Token for automated script"
		"ExpirationDate"	= "$TomorrowLocalDate"
		}
}

$RevokeTokenStatus = Revoke-ArcherPATToken `
	-BaseUrl $ApiBaseUrls[$ApiRegion] `
	-Tokenheaders $Headers `
	-TokenBody $RevokeBody
## Done revoke a Personal Access Token



$EndDate = [datetimeoffset]::new(
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)



Write-Host "Archer Data Extract completed."
Write-Host "Timezone:    $($TimeZone.DisplayName)"
Write-Host "Start:       $($StartDate.ToString('o'))"
Write-Host "End:         $($EndDate.ToString('o'))"
