

<#
.SYNOPSIS
1. Obtain the token from Bloomberg server, endpoint 
https://bsso.blpprofessional.com/ext/api/as/token.oauth2

2. Exports a Archer Report file to CSV the following endpoints

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
    [string]$ApiKey = $env:ARCHER_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$TimeZoneId = "AUS Eastern Standard Time",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Global", "AU")]
    [string]$ApiRegion = "AU",
	
	[Parameter(Mandatory = $true)]
    [int]$ReportId
	
	
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
$UserId       = "3289"


function Invoke-MyAPI {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Url,
		
		[ValidateSet("GET", "POST", "DELETE")]
		[string]$Method = "POST",
		
		[Parameter(Mandatory = $true)]
		[hashtable]$Headers,
		
		$Body,
		
		[int]$MaximumAttempts = 3
	)
	
	$Attempt = 0


	while ($Attempt -lt $MaximumAttempts) {
		
		$Attempt++

		try {
			Write-Host "Attempt $Attempt"
			
			Write-Host "URl $Url"
			if ($null -ne $Body) {
				
				if ($Body -is [string]) {
					$BodyJson = $Body
				}
				else {
					$BodyJson = $Body | ConvertTo-Json -Depth 100
				}
			}
						
			$StatusCode = $null

			#$Response = Invoke-RestMethod @Parameters
				
			if ($null -ne $Body) {
				$Response = Invoke-RestMethod `
					-Uri $Url `
					-Method  $Method `
					-Headers $Headers `
					-ContentType "application/json" `
					-Body $BodyJson `
					-ErrorAction $ErrorActionPreference
			} else {
				$Response = Invoke-RestMethod `
					-Uri $Url `
					-Method  $Method `
					-Headers $Headers `
					-ContentType "application/json" `
					-ErrorAction $ErrorActionPreference
			}	
			
				
			Write-Host "Response $Response"
			
			
			return [PSCustomObject]@{
				Success    = $true
				StatusCode = $StatusCode
				Body       = $Response
			}
		}
		
		catch {
			#Write-Host "Attempt $Attempt failed." 
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

	} 
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

$Session_Token = $null

$statusCode = $null

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/platformapi/core/security/login"

$RequestResponse = Invoke-MyAPI `
	-Url $RequestUrl `
	-Method POST `
	-Headers $TokenHeaders `
	-Body $TokenBody
	
if ($RequestResponse.Success) {
	Write-Host "Login API Call successful"
}
	
$Session_Token = $RequestResponse.Body.RequestedObject.SessionToken

Write-Host "Session_Token $Session_Token"
	

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

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/api/V2/PersonalAccessToken/Create"

$RequestResponse = Invoke-MyAPI `
	-Url     $RequestUrl  `
	-Method  POST `
	-Headers $PATHeaders `
	-Body    $PATBody
	
Write-Host "Pass Create PAT API call!!"



if ($RequestResponse.StatusCode -eq 200) {
	Write-Host "Create Personal Access Token API Call successful"
}

$PAT_Token = $null
$PAT_Id = $null


$PAT_Token = $RequestResponse.Body.Token
		
$PAT_Id = $RequestResponse.Body.Id

if ([string]::IsNullOrWhiteSpace($PAT_Token)) {
		 throw "Cannot proceed with the collections because no PAT Token was obtained"
		}
		
## Done Create a Personal Access Token
		
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
$report_id = $ReportId

$RequestBody = $null

$RequestBodyJson = $RequestBody | ConvertTo-Json

$RequestResponse = $null 

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/results?ReportId=$report_id&ViewType=Report&PageNum=0&PageSize=100&PerformFacetedSearch=false&IncludeAllContentIds=false"

$RequestResponse = Invoke-MyAPI `
	-Url     $RequestUrl `
	-Method  GET `
	-Headers $RequestHeaders `
	-Body    $RequestBodyJson
	
Write-Host "Pass Create PAT API Call"

if ($RequestResponse.Success -ne $true) {
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

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/reportCriteria?reportId=$report_id"
		
Write-Host "requestUrl $RequestUrl"

$RequestResponse = Invoke-MyAPI `
	-Url $RequestUrl `
	-Method GET `
	-Headers $RequestHeaders `
	-Body $RequestBodyJson `

Write-Host "Pass Get Report Criteria API Call"

$ReportCriteria = $RequestResponse.Body

Write-Host "ReportCriteria $ReportCriteria"

if ([string]::IsNullOrWhiteSpace($ReportCriteria)) {
		 throw "Cannot proceed with the collections because no Report Criteria was obtained"
		}


### Done API call to Get Report Details

#############################################################################################
#############################################################################################
#############################################################################################
# API call to get Report Details

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/search/reportDetails?reportIds=$report_id" 

$RequestResponse = Invoke-MyAPI `
		-Url     $RequestUrl `
		-Method  GET `
		-Headers $RequestHeaders `
		-Body    $RequestBodyJson `
		
	
#$ReportDetails = $RequestResponse | ConvertTo-Json -Depth 100
	
$ReportDetails = $RequestResponse.Body 


Write-Host "Pass Get Report Details API Call"

if ([string]::IsNullOrWhiteSpace($ReportDetails)) {
		 throw "Cannot proceed with the collections because no Report Details was obtained"
		}

# Done with API call to get Report Details

# End of Get Report Criteria

# Load Json from File

Write-Host "IS the error here...."

$RequestBodyPostExport = Get-Content ".\post_export_request_body.json" -Raw | ConvertFrom-Json

Write-Host "The ReportDetails $ReportDetails.reports[0]"

$RequestBodyPostExport.requestParameters.reportPayload.reportDetail = $ReportDetails.reports[0]

$RequestBodyPostExport.requestParameters.reportPayload.reportCriteria = $ReportCriteria

$RequestBodyPostExportJson = $RequestBodyPostExport | ConvertTo-Json -Depth 100

#Write-Host "RequestExport $RequestBodyPostExport"

$OutputFileName = "$($ReportId).json" 

[string]$OutputPath = (
			Join-Path $PWD (
				$OutputFileName
			)
	)

if ($null -ne $RequestBodyPostExportJson) {
	
	$OutputDirectory = Split-Path -Parent $OutputPath
	
	if (
	-not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
	-not (Test-Path -LiteralPath $OutputDirectory)) {
		New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
	}

	Write-Host "OutputPath $OutputPath"

	$RequestBodyPostExportJson | Set-Content `
			-Path $OutputPath `
			-Encoding UTF8
			
	Write-Host "Json file : $OutputPath"
	}


if (
	-not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
	-not (Test-Path -LiteralPath $OutputDirectory)
) {
	New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}


#### Begin Post Export API

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export"

$RequestResponse = Invoke-MyAPI `
            -Url     $RequestUrl `
            -Method  POST `
            -Headers $RequestHeaders `
            -Body    $RequestBodyPostExportJson `
			
Write-Host "Pass Post Export API"
      	
$ExportId = $RequestResponse.Body.exportId
		
$ExportName = $RequestResponse.Body.exportName

Write-Host "Export id $ExportId"

Write-Host "Export Name $ExportName"

if ([string]::IsNullOrWhiteSpace($ExportId)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


#### End of Post Export API

#### Begin Get Export

$Attempt = 0
$MaximumAttempts = 10

$RequestResponse = $null

$ExportDownloadAvailable = $false

do {
    $Attempt++
	
    try {
        Write-Host "Checking report Downloadable - attempt $Attempt"
		
		$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export/$ExportId"
		
		Write-Host "requestUrl = $RequestUrl"

        $RequestResponse = Invoke-RestMethod `
            -Uri $RequestUrl `
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
		
		Write-Host "Export not ready. Waiting for 600 seconds...."
		Start-sleep -Seconds 600
    }
    catch {
        Write-Host "Get Export request failed." 
        Write-Host "Error: $($_.Exception.Message)"

        if ($Attempt -ge $MaximumAttempts) {
            throw
        }

        Write-Host "Re-try again in 600 seconds..."
        Start-Sleep -Seconds 600
    }

} while ($Attempt -lt $MaximumAttempts)


if ($ExportDownloadAvailable -ne $true) {
	throw "Export was not available to download after $MaximumAttempts"
}

#############################################################################################
#############################################################################################
#############################################################################################

# Get the download-Url

$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/ngrx/export/$ExportId/download-url"
		
Write-Host "requestUrl = $RequestUrl"

$RequestResponse = Invoke-MyAPI `
	-Url $RequestUrl `
	-Method GET `
	-Headers $RequestHeaders `
	-ErrorAction $ErrorActionPreference


$DownloadUrl = $RequestResponse.Body.downloadUrl


if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################

## Download the file

$RequestUrl = "$DownloadUrl"

Write-Host "requestUrl = $RequestUrl"

$RequestResponse = Invoke-MyAPI `
	-Url $RequestUrl `
	-Method GET `
	-Headers $RequestHeaders `
	

if ([string]::IsNullOrWhiteSpace($RequestResponse)) {
		 throw "Cannot proceed to download because no ExportId was obtained"
		}


$OutputFileName = "$($ExportName).csv" 

$OutputFileName = $OutputFileName -replace '[\\/:*?"<>|\[\]]', '_'

[string]$OutputPath = (
			Join-Path $PWD (
				$OutputFileName
			)
	)

if ($RequestResponse.Success -eq $true -and $null -ne $RequestResponse) {

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


# if (
	# -not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
	# -not (Test-Path -LiteralPath $OutputDirectory)
# ) {
	# New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
# }



######### End of Download Export

#############################################################################################
#############################################################################################
#############################################################################################	
		
################# House Keeping		
## Once we are done Processing Archer APIs - we should revoke the PAT for security 

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

# $Session_Token = $null

# $statusCode = $null

# $RequestUrl = "$($ApiBaseUrls[$ApiRegion])/platformapi/core/security/login"

# $RequestResponse = Invoke-MyAPI `
	# -Url $RequestUrl `
	# -Method POST `
	# -Headers $TokenHeaders `
	# -Body $TokenBody
	
# if ($RequestResponse.Success) {
	# Write-Host "Login API Call successful"
# }
	
# $Session_Token = $RequestResponse.Body.RequestedObject.SessionToken

# Write-Host "Session_Token $Session_Token"


## Revoke PAT using PAT_Id

$RevokeHeaders = @{
		"Accept"                = "application/json"
		"Content-Type"          = "application/json"
		"Authorization"         = "Archer session-id=$PAT_Token"

	}

$RevokeBody = @{
	"request"= @{
		"UserId"			= $UserId
		"Name"				= "My Archer API Token"
		"Description"		= "Token for automated script"
		"ExpirationDate"	= "$TomorrowLocalDate"
		}
}


$RequestUrl = "$($ApiBaseUrls[$ApiRegion])/api/V2/PersonalAccessToken($PAT_Id)"
	
$RequestResponse = Invoke-MyAPI `
	-Url $RequestUrl `
	-Method DELETE `
	-Headers $RevokeHeaders `
	-Body $$RevokeBody
	
if ($RequestResponse.StatusCode -eq 200) {
	Write-Host "Revoke API Call successful"
}
	
## Done revoke a Personal Access Token



$EndDate = [datetimeoffset]::new(
    $TodayLocal,
    $TimeZone.GetUtcOffset($TodayLocal)
)



Write-Host "Archer Data Extract completed."
Write-Host "Timezone:    $($TimeZone.DisplayName)"
Write-Host "Start:       $($StartDate.ToString('o'))"
Write-Host "End:         $($EndDate.ToString('o'))"
