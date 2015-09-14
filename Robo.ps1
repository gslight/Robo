## Change title of Window incase anyone has the session open when it runs.
$host.ui.RawUI.WindowTitle = "Robocopy Backup"

## What do you wish to copy?
$source=@("\\sourcedirectory1","\\sourcedirectory2","\\sourcedirectory3")

## Where do you want to place the backup?
$destination=@("\\destinationdirectory1","\\destinationdirectory2","\\destinationdirectory3")

## Where do you want to save the log file?
$logDestination="C:\Log Files\logReport.txt"

## This file is used for the process of checking
## whether or not the backup was successful
$backupReport="C:\Log Files\report.txt"

## Change as necessary
$successEmailTo="email1@email.com","email2@email.com"
$successEmailSubject="Backup Job Successful"
$successEmailFrom="Robocopy@email.com"
$successEmailSMTPServer="stmp.email"

$failEmailTo="email1@email.com","email2@email.com"
$failEmailSubject="Backup Job Failed"
$failEmailFrom="Robocopy@email.com"
$failEmailSMTPServer="stmp.email"

## Depending on how many directories you are checking, you will need to change -lt how many times this for loop will go
for ($i=0; $i -lt 3; $i++) {

## =========================================================
## ======== PLEASE DO NOT EDIT SCRIPT BELOW ================
## =========================================================

## Here we delete any previous log entries, just incase of errors where the new robocopy log did not update correctly.
if (Test-Path $logDestination) {
  Remove-Item $logDestination
}

Write-Host $i

## robocopy will mirror a directory and log the file, adjust the robocopy exlusions and command to your liking here
robocopy $source[$i] $destination[$i] /mir /log:$logDestination /NP /R:0 /W:2 /TEE

## this will take a snapshot of the source and destination directory
$shot1 = Dir $source[$i]
$shot2 = Dir $destination[$i]

## This will compare the two snapshots and append it to a backup report
Compare-Object $shot1 $shot2 -PassThru > $backupReport

## Get Log file first 7 and last 11 lines to put into EmailBody
$successEmailBody= Get-Content 'C:\Log Files\logReport.txt' | select -Skip 4 -First 5
$successEmailBody2=Get-Content 'C:\Log Files\logReport.txt' | select -Last 11
$failEmailBody= Get-Content 'C:\Log Files\logReport.txt' | select -Skip 4 -First 5
$failEmailBody2=Get-Content 'C:\Log Files\logReport.txt' | select -Last 11

$SuccessBody = $successEmailBody + $successEmailBody2 | Out-String
$FailBody = $failEmailBody + $failEmailBody2 | Out-String

## send a success email
function sendSuccessEmail{
send-mailmessage -from $successEmailFrom -to $successEmailTo -subject $successEmailSubject -body "$SuccessBody" -Attachments "$logDestination" -priority High -dno onSuccess, onFailure -smtpServer $successEmailSMTPServer
}

## send a failure email
function sendFailEmail{
send-mailmessage -from $failEmailFrom -to $failEmailTo -subject $failEmailSubject -body "$FailBody" -Attachments "$logDestination" -priority High -dno onSuccess, onFailure -smtpServer $failEmailSMTPServer
}

## if the logReport has somewhere in the file "Access is denied" it will send a failure email
$SearchString = "Access is denied" 
$Sel = select-string -pattern $SearchString -path $logDestination
If ($Sel -eq $null) 
    { echo "No Permission Errors" } 
Else 
    {sendFailEmail}

## if the backup report has no feedback (all files were copied successfully) it will send a success email, it also checks the previous
$File = Get-ChildItem $backupReport
if ($File.Length -eq 0 -and $Sel -eq $null) {sendSuccessEmail}

## if the backup report has feedback (all files were NOT copied successfully) it will send a failure email
$File = Get-ChildItem $backupReport
if ($File.Length -gt 0) {sendFailEmail}

}