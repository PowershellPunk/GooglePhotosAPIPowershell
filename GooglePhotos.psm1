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

 .Parameter Year
  Year of Photos Album

 .Parameter Month
  Month of Photos Album.

 .Parameter SavePath
  Root folder wher to save Photos. For example, "C:\MyPictures" will create a folder
  struction C:\MyPictures\<Year>\<Month>

 .Example
   # Download Photos from Current Year and month to "C:\<Username>\Pictures\GooglePhotos\<Year>\<Month>"
   Get-GooglePhotos

 .Example
   # Download Custom Year.  Month will default to current month.
   Get-GooglePhotos -Year 2009

 .Example
   # Download Custom Month.  Year will default to current year.
   Get-GooglePhotos -Month 09

 .Example
   # Download Current Year and Month to a custom folder D:\MyPhotos. D:\MyPhotos must exist.
   Get-GooglePhotos -SavePath D:\MyPhotos

#>

# Import-Module .\GooglePhotos.psm1

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

    . .\Get-GoogApiAuth.ps1
    . .\Get-GoogAPIAlbums.ps1

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