# Script Title: Check Patching Compliance Status with Proactive Remediation
<#
.DESCRIPTION
Script Title: Check Patching Compliance with Proactive Remediation
Demo
<YouTube video link--> https://youtu.be/lJGiGXPTwZo

NOTES
Version:         1.1
Author:          Chander Mani Pandey
Creation Date:   1 Jan 2025

Find Author on 
Youtube:-        https://www.youtube.com/@chandermanipandey8763
Twitter:-        https://twitter.com/Mani_CMPandey
LinkedIn:-       https://www.linkedin.com/in/chandermanipandey
#>
# 
$error.clear() ## this is the clear error history 
cls
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
 
#-----------------------------------------Detecting Machine is Compliant against Latest Patch Tuesday-----------------------------------------------------------
 
$CollectedData = $PatchDetails = $LatestPatches = @()
 
$InstlPatch = $InstlPatchRD = $OSBuild = $String = ""
 
$PatchReleaseDays = 0
#=====================Checking OS Version Missing===============--------------------------------------------------------------------------------------------------------
$OSBuild = ([System.Environment]::OSVersion.Version).Build
IF (!($OSBuild)) {
    $String = 'Failed to Find Build Info'
    Write-Host $String
    #exit 1
}
 
#===========Detecting latest Intalled KB==========================
[string]$InstlPatch = (Get-HotFix | Where-Object {$_.Description -match 'security'} | Sort-Object HotFixID -Descending | Select-Object -First 1).HotFixID
IF (!($InstlPatch)) {
    $String = 'Failed To Find Installed Patch'
    Write-Host $String
    #exit 1
}
 
 
$URI = 'https://aka.ms/Windows11UpdateHistory'
$CollectedData += (Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Continue).Links
$URI = 'https://support.microsoft.com/en-us/help/4043454'
$CollectedData += (Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Continue).Links
 
#$CollectedData | Export-Csv -Path "c:\report.csv" -NoTypeInformation
 
#============Checking if able to downlaod MS patch from MS sites(Internet)=======================================
 
IF (!($CollectedData)) {
    $String = 'Failed To Download MSPatchList'
    Write-Host $String
    #exit 1
}
 
 
#============Checking if able to Find MS patch ==============================================
 
$CollectedData = ($CollectedData | Where-Object {$_.class -eq 'supLeftNavLink' -and $_.outerHTML -match 'KB' -and $_.outerHTML -notmatch 'out-of-band' -and $_.outerHTML -notmatch 'preview' -and $_.outerHTML -notmatch 'mobile' -and $_.outerHTML -match $OSBuild}).outerHTML;
$CollectedData = $CollectedData | Select-Object -Unique
IF (!($CollectedData)) {
    $String = 'Failed To Find MSPatch'
    Write-Host $String
    #exit 1
}
 
 
Foreach ($Line in $CollectedData) {
	$ReleaseDate = $PatchID = ""
    $ReleaseDate = (($Line.Split('>')[1]).Split('&')[0]).trim()
    IF ($ReleaseDate -match 'build') {
        $ReleaseDate = ($ReleaseDate.split('-')[0]).trim()
    }
	$PatchID = ($Line.Split(' ;-') | Where-Object {$_ -match 'KB'}).trim()
    $PatchDetails += [PSCustomObject] @{MajorBuild = $OSBuild; PatchID = $PatchID; ReleaseDate = $ReleaseDate;}
}
$PatchDetails = $PatchDetails | Select-Object MajorBuild,PatchID,ReleaseDate -Unique | Sort-Object PatchID -Descending;
IF (!($PatchDetails)) {
    $String = 'Failed To Find Patch List'
    Write-Host $String
    #exit 1
}
$Today = Get-Date; $LatestDate = ($PatchDetails | Select-Object -First 1).ReleaseDate
$DiffDays = ([datetime]$Today - [datetime]$LatestDate).Days
[Int]$DateVar = $PatchReleaseDays/28
#IF ([int]$DiffDays -gt [int]$PatchReleaseDays) 
If ($DateVar -eq 0)
{
    $LatestPatches += $PatchDetails | Select-Object -First 1
}
ELSE {
    $LatestPatches += $PatchDetails | Select-Object -Skip $DateVar -First 1
}
IF (!($LatestPatches)) {
    $String = 'Failed To Find Latest Patch'
    Write-Host $String
    #exit 1
}
Foreach ($BLD in $PatchDetails) {IF ($InstlPatch -eq $BLD.PatchID) {$InstlPatchRD = $BLD.ReleaseDate}}
IF (!($InstlPatchRD)) {
    $String = $InstlPatch + ';Failed To Find RlsDt'
    Write-Host $String
    #exit 1
}
#=================================== Converting dates in MM/dd/yy format================================================================================================
 
$LPRD = Get-Date -Date $LatestPatches.releasedate
$LatestPatchesreleasedate = $LPRD.ToString("MMMM d, yyyy")
$LatestPatche = $LatestPatches.PatchID
$IPRD = Get-Date -Date $InstlPatchRD
$FinalInstlPatchRD = $IPRD.ToString("MMMM d, yyyy")
 
 
$KBN1 = $KBN2 = "";
[int]$KBN1 = ($InstlPatch).Replace('KB','')
[int]$KBN2 = ($LatestPatches.PatchID).Replace('KB','')
IF ([int]$KBN1 -ge [int]$KBN2) {
    $String = 'Compliant'+' / ('+'InstalledPatch = ' + $InstlPatch +'; '+ $FinalInstlPatchRD+') / ('+'RequiredPatch = ' +$LatestPatche+'; '+ $LatestPatchesreleasedate  +')'
    Write-Host $String
    exit 0
}
ELSE {
     $String = 'Non-Compliant'+' / ('+'InstalledPatch = ' + $InstlPatch +'; '+ $FinalInstlPatchRD+') / ('+'RequiredPatch = ' +$LatestPatche+'; '+ $LatestPatchesreleasedate  +')'
    Write-Host $String
    exit 1
     
}
 