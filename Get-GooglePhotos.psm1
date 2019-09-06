# Import-Module .\Get-GooglePhotos.psm1

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

    Import-Module .\Get-GoogApiAuth.psm1
    Import-Module .\Get-GoogAPIAlbums.psm1

    if(-not (Get-GoogApiAuth -RefreshToken)){
        Get-GoogApiAuth
    }

    ###### Get list of files ######
    $CurrDate = Get-Date
    [int]$Year = $CurrDate.year
    [int]$Month = $CurrDate.month

    #. "$($env:USERPROFILE)\Documents\GooglePhotosAPIPowershell\Get-GoogApiAlbums.ps1"

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
            $DownloadURL = "$BaseUrl=dv"
        }
        $FullSavePath =  "$SavePath\$Year\$Month\$($Media.filename)"

        if(-not (Test-Path $FullSavePath)){
            $FullSavePath
            $RawImage = $(Invoke-WebRequest -Uri $DownloadURL).Content
            [io.file]::WriteAllBytes($FullSavePath, $RawImage)
        }
    }
}