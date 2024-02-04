
$currentFolder = $PSScriptRoot
Set-Location $currentFolder

#. .\Copy_iPhone_byDaiyanYingyu_v1.ps1 -phoneName "Aaron's S21" -sourceFolder "Internal storage\DCIM\Family - Copy" -targetFolder "C:\downloads\Aaron Phone" -filter ".jpg|.gif|.mov|.mp4" 

. .\Copy_iPhone_byDaiyanYingyu_v1.ps1 -phoneName "Apple iPhone" -sourceFolder "Internal storage\DCIM" -targetFolder "C:\downloads\Megan Lisbon" -filter ".jpg|.gif|.mov|.mp4|.heic|.aae" 



