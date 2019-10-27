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

<#
function Get-GoogApiAlbums(){
    param (
        [int]$Year = $(Get-Date -Format yyyy),
        [int]$Month = $(Get-Date -Format MM)
    )

    $Contents = Get-Album -Year $Year -Month $Month   
   
    do{
        # Extra complexity due to an apparent bug on Googles side with 
        # NextPageToken being given, but no content on the next page.
        $Temp = Get-Album -Year $Year -Month $Month -nextPageToken $Temp.nextPageToken
        if($Temp.mediaItems.Count -gt 0){

            $Contents = $Temp
            #$Contents = Get-Album -Year $Year -Month $Month -nextPageToken $Contents.nextPageToken
            
        }
        $Contents.mediaItems
    }until(-not $Temp.nextPageToken -or ($Temp.mediaItems.Count -gt 0))
    
}
#>

function Get-GoogApiAlbums(){
    param (
        [int]$Year = $(Get-Date -Format yyyy),
        [int]$Month = $(Get-Date -Format MM)
    )

    $Contents = Get-Album -Year $Year -Month $Month   
   
    $Results = $Null
    $TotalResults = $Null
    $NextToken = $Null
    [int]$count = 0

    do{

        if($NextToken){
            $Results = Get-Album -Year 2019 -Month 10 -nextPageToken $NextToken
        }else{
            $Results = Get-Album -Year 2019 -Month 10
        }
        #$Results
        $count += $Results.mediaItems.Count
        $NextToken = ($Results).nextPageToken
        #$NextToken
        $Results.mediaItems    

    }until(-not $NextToken)
    

}
