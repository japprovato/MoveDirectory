################################################################
# File:			MoveDirectoryScript.ps1
# Date: 		March 11, 2015 
# Author: 		Jordana Approvato
#
# Description:	Parses a CSV of file paths and moves or copies
# each dir and its children to a specified directory, depending on  
# which the user selects. Logs results.
################################################################
$ErrorActionPreference = "SilentlyContinue"

#import CSV
$importPath = "./paths.txt"
$paths = Import-Csv $importPath

#logFile path
$logFile = "./log.csv"

#destination: can use drive:\path or \\server\share\path
$newPath = "C:/To Be Deleted/"

#if $newPath does not exist, create it
if((Test-Path ($newPath)) -ne $true) 
{
	New-Item -ItemType directory -Path $newPath
}

#checking to see if $paths exists, if not, can't run program
if((Test-Path ($importPath)) -ne $true) 
{
	$timeStamp = [String](Get-Date)
	$logMessage = $timeStamp + "`t" + $importPath + "`t Error: Invalid Path`n"
}
else
{

#receiving user input
$option = " "
$optionPrompt = "What action would you like to take?)`n`t[1] Move Entire Folder Structure`n`t[2] Copy Folder Structure`n`t[3] Move Files Only, Keep Folder Structure`n`t[4] Cancel`n"
$option = Read-Host $optionPrompt
while($option -ne "1" -and $option -ne "2" -and $option -ne "3" -and $option -ne "4")
{
	$option = Read-Host "Invalid selection, please select one of the following: 1, 2, 3, 4"
}



#for loop to iterate through each path in CSV
for($i = 0; $i -lt $paths.count; $i++)
{
	#source
	$oldPath = $paths[$i].Paths
	
	#time stamp
	$timeStamp = [String](Get-Date)
	
	#option for log 
	$logOption = "No Action"
	
	if($option -eq "4")
	{
		$logMessage = $timestamp + "`t" + "Script exited by user"
		break
	}
	#test to see if path exists
	ElseIf ((Test-Path -Path $paths[$i].Paths) -ne $false)
	{

		#gets the directory name that we want to move 
		#i.e. if $oldPath = "C:/Documents/Folder1", $dir = "Folder1"
		$dir = split-path ($oldPath) -leaf
		
		#recreates a folder in destination path that matches the dir name
		#i.e. $newFolder = "C:/To Be Deleted/Folder1"
		$newFolderPath = $newPath + $dir
		
		#if $newFolderPath does not exist, create it
		if((Test-Path ($newFolderPath)) -ne $true) 
		{
			New-Item -ItemType directory -Path $newFolderPath
		}

		$oldFiles = get-childitem -Path $oldPath -recurse -force
		$oldFolders = $oldFiles | where-object { $_.PSIsContainer }

		#assures that FolderCount is not displaying null in Log file
		if ($oldFolders.count -eq $NULL)
		{
			$oldPathFolderCount = 0
		}
		else 
		{
			$oldPathFolderCount = $oldFolders.count
		}
		
		#assures that FileCount is not displaying null in Log file
		if ($oldFiles.count -eq $NULL)
		{
			$oldPathFileCount = 0
		}
		else 
		{	
			#Number of Items total minus Number of items that are containers (folders)
			#which equals the number of files (Items that are not containers).
			$oldPathFileCount = $oldFiles.count - $oldPathFolderCount
		}

		if($option -eq "1")		#MOVE & DELETE
		{
			#cmdlet that moves the file structure, and deletes the original dir
			robocopy $oldPath `"$newFolderPath`" /MIR /MOVE
			
			#makes sure duplicate folders/files are still being removed from original path
			if(Test-Path -Path $paths[$i].Paths)
			{
				Remove-Item $paths[$i].Paths -recurse
			}
			$logOption = "Option 1`tCopy All, Delete Original"
			echo "Option 1"
		}
		ElseIf($option -eq "2")	#Copy
		{
			#cmdlet that copies the file structure to the destination $newFolderPath
			robocopy $oldPath `"$newFolderPath`" /MIR
			
			$logOption = "Option 2`tCopy All, Keep Original"
			echo "Option 2"
		}
		ElseIf($option -eq "3")	#Move Files, keep Folders
		{
			#Get-ChildItem -Path $oldPath -Recurse -force | Where-Object {-not($_.psiscontainer)} | 
			#Foreach-Object { Move-Item -path $_ -destination $newFolderPath}
			
			Get-ChildItem -Path $oldPath -recurse | Where-Object {-not($_.psiscontainer)} | Move-Item -Destination $newFolderPath 
			
			$logOption = "Option 3`tMove Files Only, Keep Folder Structure"
			echo "Option 3"
		}
		
		#formatting log message
		$logMessage = $logMessage + ($timeStamp + "`t" + $oldPath + "`t" + $oldPathFileCount + " files exist" + "`t" + $oldPathFolderCount + " folders exist" + "`t" + $newFolderPath)
		
		$newFiles = get-childitem -Path $newFolderPath -recurse
		$newFolders = $newFiles | where-object { $_.PSIsContainer }
		
		if ($newFolders.count -eq $NULL)
		{
			$newPathFolderCount = 0
		}
		else 
		{
			$newPathFolderCount = $newFolders.count
		}
		
		if ($newFiles.count -eq $NULL)
		{
			$newPathFileCount = 0
		}
		else 
		{	
			#Number of Items total minus Number of items that are containers (folders)
			#which, clearly, equals the number of files (Items that are not containers).
			$newPathFileCount = $newFiles.count - $newPathFolderCount
		}
		
		$logMessage = $logMessage + ( "`t" + $newPathFileCount + " files successfully moved" + "`t" + $newPathFolderCount + " folders successfully moved" + "`t" + $logOption + "`n")
	}
	else
	{	
		$logMessage = $logMessage + ($timeStamp + "`t" + $oldPath + "`t" + "Error: Invalid Path" + "`n")
	}
}
}

#appending log message to log file
$logMessage | Out-File -FilePath $logFile -Append
