#
# Authored by: Adam H. Meadvin 
# Email: h3rbert@protonmail.ch
# GitHub: @GhostMach 
# Creation Date: 16 May 2021
#

$BreakLoop = $False
$LoopCnt = 0

function CreateComputerName {
	[CmdletBinding()]
	Param(
		[Parameter (position=0)][string]$FirstNameParam, `
		[Parameter (position=1)][string]$LastNameParam, `
		[Parameter (position=2)][string]$MiddleInitParam, `
		[Parameter (position=3)][string]$UniqueNameParam
	)

	$LastNameSplit = ($LastNameParam -split '[" "\-]') -join ""
	$AppendNames = $FirstNameParam + $MiddleInitParam + $LastNameSplit
	$GTCNetworkID = [regex]::Match($AppendNames,'^[a-z|A-Z]{1,8}').Value
	$GTCSerial =  [regex]::Match($(Get-WmiObject Win32_bios).Serialnumber,'.{7}$').Value

	$NetworkUniqueNames = [ordered]@{
    UniqueName = $UniqueNameParam.ToUpper() + $GTCSerial.ToUpper()
    NetworkName = $GTCNetworkID.ToUpper() + $GTCSerial.ToUpper()
	}
	
	$CompNames = New-Object -TypeName PSObject -Property $NetworkUniqueNames
	
	return $CompNames
}

function RenameComputer {
	[CmdletBinding()]
	Param(
		[Parameter (Mandatory=$true, position=0)][string]$CompNameParam, `
		[Parameter (Mandatory=$true, position=1)][string]$RestartCompParam
	)

	Write-Progress -Activity "Renaming Workstation"
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -Value $CompNameParam
	$LocalStringVal = Get-ItemPropertyValue -Path "HKLM:\Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\" -Name "LocalizedString"
	if($LocalStringVal -ne "%computername%"){
		Set-ItemProperty -Path "HKLM:\Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\" -Name "LocalizedString" -Value "%computername%"
	}

	if($RestartCompParam -eq "Y"){
		Rename-Computer -NewName $CompNameParam -Restart -Force
	}elseif($RestartCompParam -eq "N"){
		Rename-Computer -NewName $CompNameParam -Force
		Write-Host "Please restart machine at later time to complete name-change process."
		Start-Sleep 5		
	}
}

Write-Host "************************`n* " -Foreground Cyan -NoNewLine
Write-Host "Computer Rename Tool" -Foreground Green -NoNewLine
Write-Host " *`n************************`n`n" -Foreground Cyan

while(($LoopCnt -ne 3) -and ($BreakLoop -eq $False)){
	$UniqueNameQuery = Read-Host "Enter a unique user logon name, instead of a user's name? [Y]es or [N]o"
	$UniqueNameQueryLoopCnt = 0
	while($UniqueNameQuery -notmatch '^[Y|y|N|n](?!.)' -and $UniqueNameQueryLoopCnt -ne 3){
		$UniqueNameQuery = Read-Host "Confirm if you want to create a user logon name? - Enter [Y]es or [N]o"
		$UniqueNameQueryLoopCnt++
	}
	
	if($UniqueNameQueryLoopCnt -eq 3){
		break
	}
	
	if($UniqueNameQuery -match '^[Y|y](?!.)'){
	$UniqueName = Read-Host "Enter a unique user logon name up to (8) characters in length, which may include a small dash symbol"
	$UniqueNameLoopCnt = 0
	
	while($UniqueName -ne [regex]::Match($UniqueName,'^[\w|\-]{1,8}').Value -xor $UniqueName -eq "" -and $UniqueNameLoopCnt -ne 3){
		$UniqueName = Read-Host "Unique Name - Enter up to (8) characters in length without spaces, which may include a small dash symbol"
		$UniqueNameLoopCnt++
	}

	if($UniqueNameLoopCnt -eq 3){
		break
	}
	
	$GTC_CompNames = CreateComputerName -UniqueNameParam $UniqueName
	Write-Host "`n`nBased on the following name entered - `nUnique Name: "$UniqueName
	Write-Host "With computer serial #:" $(Get-WmiObject Win32_bios).Serialnumber
	$UniqueNameConfirm = Read-Host "`n`nConfirm new computer name is correct -" $($GTC_CompNames.UniqueName) "- [Y]es or [N]o"
	$UniqueNameConfirmLoopCnt = 0
		while($UniqueNameConfirm -notmatch '^[Y|y|N|n](?!.)' -and $UniqueNameConfirmLoopCnt -ne 3){
			$UniqueNameConfirm = Read-Host "Confirm new computer name? - Enter [Y]es or [N]o"
			$UniqueNameConfirmLoopCnt++
		}
		if($UniqueNameConfirmLoopCnt -eq 3){
			break
		}

		if($UniqueNameConfirm -match '^[Y|y](?!.)'){
			$GTC_CompNames.NetworkName = $null			
			$Exit = "Restart"
		} elseif($UniqueNameConfirm -match '^[N|n](?!.)'){
			$LoopCnt++
			}	
	} else {
		$FirstName = Read-Host "Enter First Name"
		$FirstNameSplit = ($FirstName -split '[" "\-]' |% { $_[0] }) -join ""
		$FirstNameCharCnt = $FirstNameSplit.length
		$FirstNameLoopCnt = 0
		while($FirstName -ne [regex]::Match($FirstName,'[a-z|A-Z|\s|\-]{1,20}').Value -xor $FirstNameCharCnt -ge 3 -xor $FirstName -eq "" -and $FirstNameLoopCnt -ne 3){
			$FirstName = Read-Host "First Name - Enter up to (2) names that cumulatively do NOT exceed (20) charcters in length"
			$FirstNameSplit = ($FirstName -split '[" "\-]' |% { $_[0] }) -join ""
			$FirstNameCharCnt = $FirstNameSplit.length
			$FirstNameLoopCnt++
		}

		if($FirstNameLoopCnt -eq 3){
			break
		}
		$LastName = Read-Host "Enter Last Name"
		$LastNameLoopCnt = 0
		while($LastName -ne [regex]::Match($LastName,'[a-z|A-Z|\s|\-]{1,40}').Value -xor $LastName -eq "" -and $LastNameLoopCnt -ne 3){
			$LastName = Read-Host "Last Name - Enter only a string up to (40) charcters long"
			$LastNameLoopCnt++
		}
		if($LastNameLoopCnt -eq 3){
			break
		}
		$MiddleInitialQuery = Read-Host "Middle Initial? [Y]es or [N]o"
		$MiddleInitialQueryLoopCnt = 0
		while($MiddleInitialQuery -notmatch '^[Y|y|N|n]{1}(?!.)' -and $MiddleInitialQueryLoopCnt -ne 3){
			$MiddleInitialQuery = Read-Host "Confirm Middle Initial? - Enter [Y]es or [N]o"
			$MiddleInitialQueryLoopCnt++
		}
		if($MiddleInitialQueryLoopCnt -eq 3){
			break
		}
		if($MiddleInitialQuery -match '^[Y|y](?!.)'){
		$MiddleInitial = Read-Host "Enter Middle Initial (without period)"
		$MiddleInitialLoopCnt = 0
		while($MiddleInitial -notmatch '^[a-z|A-Z](?!.)' -and $MiddleInitialLoopCnt -ne 3){
			$MiddleInitial = Read-Host "Middle Initial - Enter only ONE charcter, without (trailing) period"
			$MiddleInitialLoopCnt++
		}
		if($MiddleInitialLoopCnt -eq 3){
			break
		}
	
		$GTC_CompNames = CreateComputerName $FirstNameSplit $LastName $MiddleInitial
		Write-Host "`n`nBased on the following names entered - `nLast Name: "$LastName "`nFirst Name: "$FirstName "`nMiddle Initial: "$MiddleInitial
		Write-Host "With computer serial #:" $(Get-WmiObject Win32_bios).Serialnumber
		$MiddleInitialConfirm = Read-Host "`n`nConfirm new computer name is correct -" $($GTC_CompNames.NetworkName) "- [Y]es or [N]o"
		$MiddleInitialConfirmLoopCnt = 0
		while($MiddleInitialConfirm -notmatch '^[Y|y|N|n]{1}(?!.)' -and $MiddleInitialConfirmLoopCnt -ne 3){
			$MiddleInitialConfirm = Read-Host "Confirm new computer name? - Enter [Y]es or [N]o"
			$MiddleInitialConfirmLoopCnt++
		}
		if($MiddleInitialConfirmLoopCnt -eq 3){
			break
		}
	
		if($MiddleInitialConfirm -match '^[Y|y](?!.)'){
			$GTC_CompNames.UniqueName = $null
			$Exit = "Restart"	
		} elseif($MiddleInitialConfirm -match '^[N|n](?!.)'){
			$LoopCnt++
		}
		} elseif($MiddleInitialQuery -match '^[N|n](?!.)'){
		$GTC_CompNames = CreateComputerName $FirstNameSplit $LastName
		Write-Host "`n`nBased on the following names entered - `nLast Name: "$LastName "`nFirst Name: "$FirstName
		Write-Host "With computer serial #:" $(Get-WmiObject Win32_bios).Serialnumber
		$RegularNameConfirm = Read-Host "`n`nConfirm new computer name is correct -" $($GTC_CompNames.NetworkName) "- [Y]es or [N]o"
		$RegularNameConfirmLoopCnt = 0
		while($RegularNameConfirm -notmatch '^[Y|y|N|n]{1}(?!.)' -and $RegularNameConfirmLoopCnt -ne 3){
			$RegularNameConfirm = Read-Host "Confirm new computer name? - Enter [Y]es or [N]o"
			$RegularNameConfirmLoopCnt++
		}
		if($RegularNameConfirmLoopCnt -eq 3){
			break
			}

		if($RegularNameConfirm -match '^[Y|y](?!.)'){
			$GTC_CompNames.UniqueName = $null
			$Exit = "Restart"
			}	
		} elseif($RegularNameConfirm -match '^[N|n](?!.)'){
			$LoopCnt++
			}
	}
	switch ($Exit) {
		Restart {
			$RestartComp = Read-Host "Restart computer after script has completed? [Y]es or [N]o"
			$RestartCompLoopCnt = 0
			while($RestartComp -notmatch '^[Y|y|N|n]{1}(?!.)' -and $RestartCompLoopCnt -ne 3){
				$RestartComp = Read-Host "Confirm restart? - Enter [Y]es or [N]o"
				$RestartCompLoopCnt++
			}
			if ($RestartComp -match '^[Y|y|N|n]{1}(?!.)'){
				$RestartComp = $RestartComp.ToUpper()
				$BreakLoop = $True
			}			
		}
		
	}

}

if(($UniqueNameQueryLoopCnt -eq 3) -xor ($UniqueNameLoopCnt -eq 3) -xor ($UniqueNameConfirmLoopCnt -eq 3) -xor ($LoopCnt -eq 3) `
	-xor ($FirstNameLoopCnt -eq 3) -xor ($LastNameLoopCnt -eq 3) -xor ($MiddleInitialLoopCnt -eq 3) -xor ($MiddleInitialQueryLoopCnt -eq 3) `
	-xor ($MiddleInitialConfirmLoopCnt -eq 3) -xor ($RegularNameConfirmLoopCnt -eq 3) -xor ($RestartCompLoopCnt -eq 3)){
	Write-Host "`n`nToo many unsuccessful attempts. Script is Terminating" -Foreground Red
	$KeyInput = Read-Host "Press, Enter to exit"
	if ($KeyInput -eq ""){
		exit
		}
} else{
	if($UniqueNameQuery.ToUpper() -ne "N"){
		RenameComputer $($GTC_CompNames.UniqueName) $RestartComp
	} else {
		RenameComputer $($GTC_CompNames.NetworkName) $RestartComp
	}
}
