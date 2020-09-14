<#
 .Synopsis
  Downloads Google Photos

 .Description
  Replacement for the Google Photos -> Drive -> Download function 
  that was removed in July 2019 from Google Photos backup app https://www.google.com/photos/about/

  Saves Tokens, ID's and Secrets under C:\<User>\
  C:\<User>\GoogAPIAuth_client_id.txt
  C:\<User>\GoogAPIAuth_client_secret.txt
  C:\<User>\GoogAPIAuth_refresh_tokens.txt

  Install Module
  Import-Module C:\<PathToThisFile>\Get-GooglePhotos.psm1

 .Parameter Year
  Year of Photos Album

 .Parameter Month
  Month of Photos Album.

 .Parameter SavePath
  Root folder where to save Photos. For example, "C:\MyPictures" will create a folder
  struction C:\MyPictures\<Year>\<Month>

 .Example
   # Download Photos from Current Year and month to "C:\Users\<Username>\Pictures\GooglePhotos\<Year>\<Month>"
   Get-GooglePhotos

 .Example
   # Download Custom Year.  Month will default to current month.
   # Location "C:\Users\<Username>\Pictures\GooglePhotos\2020\<Month>"
   # where <Month> is the current month.
   Get-GooglePhotos -Year 2020

 .Example
   # Download Custom Month.  Year will default to current year.
   # Location "C:\Users\<Username>\Pictures\GooglePhotos\<year>\9"
   # where <year> is the current year.
   Get-GooglePhotos -Month 9

 .Example
   # Download Current Year and Month to a custom folder D:\MyPhotos. D:\MyPhotos must already exist.
   Get-GooglePhotos -SavePath D:\MyPhotos

#>

Function Get-GooglePhotos(){

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [int]$Year,
        [Parameter(Mandatory=$false)]
        [int]$Month,
        [Parameter(Mandatory=$false)]
        [string]$SavePath = "$env:USERPROFILE\Pictures\GooglePhotos"
    )

    ###### Authenticate with Googles API ######

#    . "$($PSScriptRoot)\Get-GoogApiAuth.ps1"
#    . "$($PSScriptRoot)\Get-GoogAPIAlbums.ps1"

    if(-not (Get-GoogApiAuth -RefreshToken)){
        Get-GoogApiAuth
    }

    ###### Get list of files ######
    $CurrDate = Get-Date
    if(-not $Year){[int]$Year = $CurrDate.year}
    if(-not $Month){[int]$Month = $CurrDate.month}

    #. "$($env:USERPROFILE)\Documents\GooglePhotosAPIPowershell\Get-GoogApiAlbums.ps1"

    Write-Output "Get-GoogApiAlbums -Year $($Year) -Month $($Month)"
    $Contents = Get-GoogApiAlbums -Year $Year -Month $Month


    ###### Compare and Download Files ######

    # Create Root Folder
    #$SavePath = "$env:USERPROFILE\Pictures\GooglePhotos"
    #$SavePath = "E:\MyPictures"
    if(-not (Test-Path $SavePath)){mkdir $SavePath -Force}
    if(-not (Test-Path "$SavePath\$Year")){mkdir "$SavePath\$Year" -Force}
    if(-not (Test-Path "$SavePath\$Year\$Month")){mkdir "$SavePath\$Year\$Month" -Force}

    # Save File to disk
    foreach($Media in $Contents){
        $Width = $Media.mediaMetadata.width
        $Height = $Media.mediaMetadata.Height
        $BaseUrl = $Media.baseUrl

        if($Media.mimeType -match "image"){
            #$DownloadURL = "$BaseUrl=w$($Width)-h$($Height)"
            $DownloadURL = "$BaseUrl=d"
        }elseif($Media.mimeType -match "video"){
            #$DownloadURL = "$BaseUrl=dv"
            $DownloadURL = "$BaseUrl=dv"
        }
        $FullSavePath =  "$SavePath\$Year\$Month\$($Media.filename)"

        if(-not (Test-Path $FullSavePath)){
            $FullSavePath
            #$DownloadURL
            $RawImage = $(Invoke-WebRequest -Uri $DownloadURL).Content
            [io.file]::WriteAllBytes($FullSavePath, $RawImage)
        }
    }
}

Function Get-Album (){
    param (
        [int]$Year,
        [int]$Month,
        [string]$nextPageToken = $null

    )

    $requestUri = "https://photoslibrary.googleapis.com/v1/mediaItems:search"
    $method = "POST"

    $Headers = @{
        Authorization = "Bearer $env:GoogAPIAuth_refresh_access_tokens";
    }

    $body = $null
    $body = [ordered]@{
        pageSize = 100
        filters = @{
        dateFilter = @{
            dates = @(
            @{
                year = $Year
                month = $Month
            }
            )
        }
        }
    }

    if($nextPageToken){
        $body.Add("pageToken", $nextPageToken)
    }

    $body = $body | ConvertTo-Json -Depth 100 -Compress
    # write-host $body -ForegroundColor Green

    #$Response = $null
    $Response = Invoke-RestMethod `
        -Body $body `
        -Headers $Headers `
        -Uri $requestUri `
        -Method $method `
        -ContentType 'application/json' #'application/x-www-form-urlencoded' # 'application/json' did not work
    Return $Response
}

function Get-GoogApiAlbums(){
    param (
        [int]$Year,
        [int]$Month
    )

    $CurrDate = Get-Date
    if(-not $Year){[int]$Year = $CurrDate.year}
    if(-not $Month){[int]$Month = $CurrDate.month}

    $Contents = Get-Album -Year $Year -Month $Month   
   
    $Results = $Null
    $TotalResults = $Null
    $NextToken = $Null
    [int]$count = 0

    do{

        if($NextToken){

            $Results = Get-Album -Year $Year -Month $Month -nextPageToken $NextToken

        }else{

            $Results = Get-Album -Year $Year -Month $Month

        }
        #$Results
        $count += $Results.mediaItems.Count
        $NextToken = ($Results).nextPageToken
        #$NextToken
        $Results.mediaItems    

    }until(-not $NextToken)
    

}

Function Get-GoogApiAuth (){

    param (
        [switch]$DontUseSavedCreds = $false,
        [switch]$Force = $false, # if $true, don't import saved creds from disk.
        [switch]$RefreshToken = $false # Good for one hour from the last refresh.
    )

    $env:GoogAPIAuth_token_uri = "https://oauth2.googleapis.com/token"
    $env:GoogAPIAuth_client_id_PATH = "$($env:USERPROFILE)\GoogAPIAuth_client_id.txt"
    $env:GoogAPIAuth_client_secret_PATH = "$($env:USERPROFILE)\GoogAPIAuth_client_secret.txt"
    $env:GoogAPIAuth_refresh_tokens_PATH = "$($env:USERPROFILE)\GoogAPIAuth_refresh_tokens.txt"

    # Import saved credentials
    if((-not $DontUseSavedCreds) -and (-not $Force)){

        $env:GoogAPIAuth_client_id = if(test-path $env:GoogAPIAuth_client_id_PATH){Get-Content $env:GoogAPIAuth_client_id_PATH}
        $env:GoogAPIAuth_client_secret = if(test-path $env:GoogAPIAuth_client_secret_PATH){Get-Content $env:GoogAPIAuth_client_secret_PATH}
        $env:GoogAPIAuth_refresh_tokens = if(test-path $env:GoogAPIAuth_refresh_tokens_PATH){Get-Content $env:GoogAPIAuth_refresh_tokens_PATH} # Good for 1 hour

    }

    # Refresh
    if($RefreshToken){
        $refreshTokenParams = @{
            client_id = $env:GoogAPIAuth_client_id;
            client_secret = $env:GoogAPIAuth_client_secret;
            refresh_token = $env:GoogAPIAuth_refresh_tokens; # Good for 1 hour
            grant_type = "refresh_token"; # Fixed value
        }

        $refreshtokens = Invoke-RestMethod -Uri $env:GoogAPIAuth_token_uri -Method POST -Body $refreshTokenParams # Run this every 3600 seconds
        $env:GoogAPIAuth_refresh_access_tokens = $refreshtokens.access_token

        if($refreshtokens){
            return $refreshtokens
        }else{
            # Write-Output "Token may have expired, run Get-GoogApiAuth without -RefreshToken"
        }

    }else{
    
        # https://console.developers.google.com/apis/credentials
        # "Create credentials" -> "OAuth client ID" -> "Web application" -> "Authorized redirect URIs" = https://localhost/ -> Create -> Create
        Function PromptCreds(){
            $CredentialsServer = "https://console.developers.google.com/apis/credentials"
            start-process -FilePath "$(${env:ProgramFiles(x86)})\Google\Chrome\Application\chrome.exe" -ArgumentList $CredentialsServer
    
            $env:GoogAPIAuth_client_id = Read-Host "`"Client ID`" from https://console.developers.google.com/apis/credentials"
            $env:GoogAPIAuth_client_secret = Read-Host "`"Client secret`" from https://console.developers.google.com/apis/credentials"

            # Save Creds to disk
            $env:GoogAPIAuth_client_id | Out-File $env:GoogAPIAuth_client_id_PATH -Force
            $env:GoogAPIAuth_client_secret | Out-File $env:GoogAPIAuth_client_secret_PATH -Force
        }
    
        # Force prompting for API credentials
        if($Force){
            PromptCreds
        }elseif((-not $env:GoogAPIAuth_client_id) -or (-not $env:GoogAPIAuth_client_secret)){
            PromptCreds
        }

        # Hard coded
        $env:GoogAPIAuth_redirect_uris = “https://localhost/”
        $env:GoogAPIAuth_scope = "https://www.googleapis.com/auth/photoslibrary" # https://developers.google.com/photos/library/guides/authentication-authorization
        $env:GoogAPIAuth_response_type = "code"
        $env:GoogAPIAuth_access_type = "offline"
        $env:GoogAPIAuth_approval_prompt = "force"
        $env:GoogAPIAuth_auth_uri = "https://accounts.google.com/o/oauth2/auth"
        $env:GoogAPIAuth_grant_type = "authorization_code"
        $env:GoogAPIAuth_AuthURL = "$($env:GoogAPIAuth_auth_uri)?client_id=$($env:GoogAPIAuth_client_id)&scope=$($env:GoogAPIAuth_scope)&response_type=$($env:GoogAPIAuth_response_type)&redirect_uri=$($env:GoogAPIAuth_redirect_uris)&access_type=$($env:GoogAPIAuth_access_type)&approval_prompt=$($env:GoogAPIAuth_approval_prompt)"

        # "Advanced" -> "Go to Project Default Service Account (unsafe)"
        # "Grant Project Default Service Account permission" = Allow
        # "You are allowing Project Default Service Account to: View your Google Analytics data" = Allow
        # "This site can’t be reached localhost refused to connect." message is okay. Ignore this. Just copy the URL from the browser to the note below
        # https://localhost/?code=4/qgFvS6gTRuq8LTxqhV-YNB-zxj2Mu712345678905-XxMy19TI9N9SgcGH1234567890q13O-KERlkkPhpYmsKg&scope=https://www.googleapis.com/auth/photoslibrary
        # $code = 4/qgFvS6gTRuq8LTxqhV-YNB-zxj2Mu712345678905-XxMy19TI9N9SgcGH1234567890q13O-KERlkkPhpYmsKg
        #start-process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList $env:GoogAPIAuth_AuthURL
        $ChromeX86Path = "$([Environment]::GetEnvironmentVariable("ProgramFiles(x86)"))\Google\Chrome\Application\chrome.exe"
        $ChromePath = "$([Environment]::GetEnvironmentVariable("ProgramFiles"))\Google\Chrome\Application\chrome.exe"
        if(test-path $ChromePath){start-process -FilePath $ChromePath -ArgumentList $env:GoogAPIAuth_AuthURL}
        elseif(test-path $ChromeX68Path){start-process -FilePath $ChromeX86Path -ArgumentList $env:GoogAPIAuth_AuthURL}

        $env:GoogAPIAuth_code = Read-Host "`"code=`" from return URL after accepting all prompts"

        $body = @{
          code = $env:GoogAPIAuth_code;
          client_id = $env:GoogAPIAuth_client_id;
          client_secret = $env:GoogAPIAuth_client_secret;
          redirect_uri = $env:GoogAPIAuth_redirect_uris;
          grant_type = $env:GoogAPIAuth_grant_type;
        };

        $token = Invoke-RestMethod -Uri $env:GoogAPIAuth_token_uri -Method POST -Body $body -ContentType “application/x-www-form-urlencoded”
        $token.refresh_token
        $env:GoogAPIAuth_refresh_tokens = $token.refresh_token
        $env:GoogAPIAuth_refresh_tokens | Out-File $env:GoogAPIAuth_refresh_tokens_PATH -Force
        return $token
    }    
}