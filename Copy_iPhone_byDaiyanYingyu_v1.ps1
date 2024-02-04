# Windows Powershell Script to move a set of files (based on a filter) from a folder
# on a MTP device (e.g. Android phone) to a folder on a computer, using the Windows Shell.
# By Daiyan Yingyu, 19 March 2018, based on the (non-working) script found here:
#   https://www.pstips.net/access-file-system-against-mtp-connection.html
# as referenced here:
#   https://powershell.org/forums/topic/powershell-mtp-connections/
#
# This Powershell script is provided 'as-is', without any express or implied warranty.
# In no event will the author be held liable for any damages arising from the use of this script.
#
# Again, please note that used 'as-is' this script will MOVE files from you phone:
# the files will be DELETED from the source (the phone) and MOVED to the computer.
#
# If you want to copy files instead, you can replace the MoveHere function call with "CopyHere" instead.
# But once again, the author can take no responsibility for the use, or misuse, of this script.</em>
#
# MODIFICATIONS
#  - added ability to iterate subfolders (thanks vakio)

param([string]$phoneName,[string]$sourceFolder,[string]$targetFolder,[string]$filter='(.jpg)|(.mp4)$')
 
function Get-ShellProxy
{
    if( -not $global:ShellProxy)
    {
        $global:ShellProxy = new-object -com Shell.Application
    }
    $global:ShellProxy
}
 
function Get-Phone
{
    param($phoneName)
    $shell = Get-ShellProxy
    # 17 (0x11) = ssfDRIVES from the ShellSpecialFolderConstants (https://msdn.microsoft.com/en-us/library/windows/desktop/bb774096(v=vs.85).aspx)
    # => "My Computer" — the virtual folder that contains everything on the local computer: storage devices, printers, and Control Panel.
    # This folder can also contain mapped network drives.
    $shellItem = $shell.NameSpace(17).self
    $phone = $shellItem.GetFolder.items() | where { $_.name -eq $phoneName }
    return $phone
}
 
function Get-SubFolder
{
    param($parent,[string]$path)
    $pathParts = @( $path.Split([system.io.path]::DirectorySeparatorChar) )
    $current = $parent
    foreach ($pathPart in $pathParts)
    {
        if ($pathPart)
        {
            $current = $current.GetFolder.items() | where { $_.Name -eq $pathPart }
        }
    }
    return $current
}

function ProcessFiles ($folder, $copyAction) {
    $items = @( $folder.GetFolder.items() | where { $_.Name -match $filter } )

    if ($items)
    {
        $totalItems = $items.count
        if ($totalItems -gt 0)
        {
            # If destination path doesn't exist, create it only if we have some items to move
            if (-not (test-path $destinationFolderPath) )
            {
                $created = new-item -itemtype directory -path $destinationFolderPath
            }
 
            Write-Host "Processing Path : $phoneName\$phoneFolderPath $folder"
    
            Write-Verbose "Processing Path : $phoneName\$phoneFolderPath $folder"
            if ($copyAction -eq "MoveAndDelete") {
                Write-Host "Moving to : $destinationFolderPath"
            } else {
                Write-Host "Copying to : $destinationFolderPath"
            }

            
             
            $shell = Get-ShellProxy
            $destinationFolder = $shell.Namespace($destinationFolderPath).self
            $count = 0;
            foreach ($item in $items)
            {
                $fileName = $item.Name
 
                ++$count
                $percent = [int](($count * 100) / $totalItems)
                Write-Progress -Activity "Processing Files in $phoneName\$phoneFolderPath" `
                    -status "Processing File ${count} / ${totalItems} (${percent}%)" `
                    -CurrentOperation $fileName `
                    -PercentComplete $percent
 
                # Check the target file doesn't exist:
                $targetFilePath = join-path -path $destinationFolderPath -childPath $fileName
                if (test-path -path $targetFilePath)
                {
                    write-host "Destination file exists - file not moved:`n`t$targetFilePath $fileName" -ForegroundColor Red
                    #write-error "Destination file exists - file not moved:`n`t$targetFilePath"
                }
                else
                {
                    if ($copyAction -eq "MoveAndDelete") {
                        $destinationFolder.GetFolder.MoveHere($item) # moves the file to new location and DELETES from source location
                    } else {
                        $destinationFolder.GetFolder.CopyHere($item) # copies file to new location
                    }
                    if (test-path -path $targetFilePath)
                    {
                        # Optionally do something with the file, such as modify the name (e.g. removed phone-added prefix, etc.)
                    }
                    else
                    {
                        write-host "Failed to move file to destination:`n`t$targetFilePath" -ForegroundColor Red
                        #write-error "Failed to move file to destination:`n`t$targetFilePath"
                    }
                }
            }
        }
    }

}
 
$phoneFolderPath = $sourceFolder
$destinationFolderPath = $targetFolder
# Optionally add additional sub-folders to the destination path, such as one based on date
 
$phone = Get-Phone -phoneName $phoneName
$folder = Get-SubFolder -parent $phone -path $phoneFolderPath

$copyAction = "CopyFiles"
$prompt = Read-Host "Press ENTER for COPY. To MOVE files (and delete from original location) type 'm')"
if ($prompt -eq "m") {
    $copyAction = "MoveAndDelete"
}

<#
                $q = Read-Host "Are you sure - source files will be deleted (y/n)"
                if ($q -ne "y") {
                    Write-Host "Aborting" -ForegroundColor Yellow
                    return
                }
#>

ProcessFiles -folder $folder -copyAction $copyAction 

$items = $folder.GetFolder.items()
foreach ($item in $items) {
    if ($item.IsFolder) {
        ProcessFiles -folder $item -copyAction $copyAction
    }
} 

<#
To call the script you need to supply:

the name of the phone (or MTP device).  This is as it appears in Windows Explorer, and is usually the name you have given to the device in its settings
the path to the folder in the device.  Usually starts with something like “Phone” or “Internal shared storage”, etc.
the fully-qualified path to the folder on the computer to where you want to move the files.
a regular expression for all the files you want to move.  For example, for images and videos you might want ‘(.jpg)|(.mp4)$’

You can put the commands into a batch (command) script to move the files from several locations.  Here is an example:

@echo off
REM Example use of MoveFromPhone.ps1 to move pictures from a phone onto computer
REM
REM This Windows Command Line script is provided 'as-is', without any express or implied warranty.
REM In no event will the author be held liable for any damages arising from the use of this script.
REM
REM Again, please note that when used with the 'MoveFromPhone.ps1' as originally written,
REM files will be MOVED from you phone: they will be DELETED from the sourceFolder (the phone)
REM and MOVED to the targetFolder (on the computer).
REM
powershell Set-ExecutionPolicy RemoteSigned -scope currentuser
REM Camera files
powershell.exe "& '%~dp0MoveFromPhone.ps1' -phoneName 'MyPhone' -sourceFolder 'Internal shared storage\DCIM\Camera' -targetFolder 'C:\Users\Public\Pictures\Camera' -filter '(.jpg)|(.mp4)$'"
REM Facebook
powershell.exe "& '%~dp0MoveFromPhone.ps1' -phoneName 'MyPhone' -sourceFolder 'Internal shared storage\DCIM\Facebook' -targetFolder 'C:\Users\Public\Pictures\Facebook' -filter '(.jpg)|(.mp4)$'"
REM Screenshots
powershell.exe "& '%~dp0MoveFromPhone.ps1' -phoneName 'MyPhone' -sourceFolder 'Internal shared storage\DCIM\Screenshots' -targetFolder 'C:\Users\Public\Pictures\Screenshots' -filter '(.png)$'"
pause

#>
