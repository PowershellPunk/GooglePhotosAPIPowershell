###### Authenticate with Googles API ######

. "$($env:USERPROFILE)\Documents\GooglePhotosAPIPowershell\Get-GoogApiAuth.ps1"

if(-not (Get-GoogApiAuth -RefreshToken)){
    Get-GoogApiAuth
}

###### Get list of files ######
$CurrDate = Get-Date
[int]$Year = $CurrDate.year
[int]$Month = $CurrDate.month

. "$($env:USERPROFILE)\Documents\GooglePhotosAPIPowershell\Get-GoogApiAlbums.ps1"

$Contents = Get-GoogApiAlbums -Year $Year -Month $Month

###### Compare and Download Files ######

# Create Root Folder
#$RootPath = "$env:USERPROFILE\Pictures\GooglePhotos"
$RootPath = "E:\MyPictures"
if(-not (Test-Path $RootPath)){mkdir $RootPath -Force}
if(-not (Test-Path "$RootPath\$Year")){mkdir "$RootPath\$Year" -Force}
if(-not (Test-Path "$RootPath\$Year\$Month")){mkdir "$RootPath\$Year\$Month" -Force}

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
    $SavePath =  "$RootPath\$Year\$Month\$($Media.filename)"

    if(-not (Test-Path $SavePath)){
        $SavePath
        $RawImage = $(Invoke-WebRequest -Uri $DownloadURL).Content
        [io.file]::WriteAllBytes($SavePath, $RawImage)
    }
}