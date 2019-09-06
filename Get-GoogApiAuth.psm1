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
        start-process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList $env:GoogAPIAuth_AuthURL
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