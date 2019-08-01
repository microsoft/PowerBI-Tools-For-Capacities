################################################################################################################################################################################
# Script to setup a load test for Power BI Reports
#-------------------------------------------------------------------
#
# PRE-REQUISITES:
# ---------------
# Access to PowerBI Service
# One or more reports deployed to a group workspace (not My Workspace)
# Script requires "RealisticLoadTest.html", "PBIReport.JSON" and "PBIToken.JSON" files provided in the package.
# 
# Expected Result:
# ----------------
# Once the inputs are provided, script will save a folder in the current working directory for each report with copy of above mentioned files configured with respective inputs.
# You should manually edit the PBIReport.JSON file in each subdirectory further define the configuration of that load test. Feel free to rename the subdirectories to a meaningful name.
################################################################################################################################################################################

#Variables declaration
$destinationDir = ''
$workingDir = $pwd.Path
$masterFilesExists = $true
$multiReportConfiguration = $true
$htmlFileName = 'RealisticLoadTest.html'
$reportConfig = @{}
$reports = @()
$user = @{}

# Regular expressions to match and update JSON files
$token_regex = '(?<=PBIToken\":\s*\").*?(?=\")'
$reportUrlRegex = '(?<=reportUrl\":\s*\").*?(?=\")' 


#Function implementation to update token file
function UpdateTokenFile
{     
    $accessToken = Get-PowerBIAccessToken -AsString | % {$_.replace("Bearer ","").Trim()}
    $tokenJSONFile = Get-Content $(Join-Path $workingDir 'PBIToken.JSON') -raw;
    $new_TokenJSONFile = ($tokenJSONFile -replace $token_regex,$accessToken)
    $new_TokenJSONFile
    $destinationDir
    $new_TokenJSONFile | set-content $(Join-Path $destinationDir 'PBIToken.JSON')
}

#Function implementation to update report parameters file
function UpdateReportParameters
{
    $reportJSONFile = Get-Content $(Join-Path $workingDir 'PBIReport.JSON') -raw;
    $new_ReportJSONFile = ($reportJSONFile -replace $reportUrlRegex,$args[0])
    $new_ReportJSONFile
    $destinationDir
    $new_ReportJSONFile | set-content $(Join-Path $destinationDir 'PBIReport.JSON')
}

#verify if current working directory have master files. If not, prompt user for path of the files.
while($masterFilesExists)
{
    if(!(Test-Path -path $(Join-Path $workingDir $htmlFileName)) -and !(Test-Path -path $(Join-Path $workingDir 'PBIReport.JSON')) -and !(Test-Path -path $(Join-Path $workingDir 'PBIToken.JSON')))
    {
        Write-Host "The current working directory ($workingDir) doesn't have the master files required to proceed further." -ForegroundColor Yellow
        $workingDir = Read-Host -Prompt "Enter the directory path having master files"
    }
    else
    {     
     $masterFilesExists = $false   
    }
}

[int]$reportCount = Read-Host "How many reports you want to configure?"
$increment = 1
while($reportCount -gt 0)
{
    Write-Host "Gathering inputs for report $increment" -ForegroundColor Red
    
    # Get required inputs from user
    Write-Host "Select Id to authenticate to Power BI" -ForegroundColor Yellow
    $user = Login-PowerBI
    $user

    #Accessing list of workspaces
    $workSpaceList = Get-PowerBIWorkspace
    #can add my workspace and then not specify the WorkspaceId switch when we list reports below... TODO

    $workSpaceCounter = 1
    foreach($workSpace in $workSpaceList)
    {
        Write-Host "[$($workSpaceCounter)]" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($workSpace.Id) - $($workSpace.Name)" -ForegroundColor Green
        ++$workSpaceCounter
    }

    $workSpaceSelection = Read-Host "Select Work space index from above"

    #Accessing reports from selected work space
    Write-Host "Listing all reports from the selected work space" -ForegroundColor Yellow
    $reportList = Get-PowerBIReport -WorkspaceId $($workSpaceList[$workSpaceSelection-1].Id)

    $reportCounter = 1
    foreach($report in $reportList)
    {
        Write-Host "[$($reportCounter)]" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($report.Id) - $($report.Name)" -ForegroundColor Green
        ++$reportCounter
    }

    $reportSelection = Read-Host "Select report index from above"

    $reportUrl = $($reportList[$reportSelection-1].EmbedUrl) #Read-Host -Prompt 'Enter Report Embed URL'

    $reportList[$reportSelection-1]


    #Creating sub-folder to create a report set
    $destinationDir = new-item -Path $workingDir -Name $(get-date -f MM-dd-yyyy_HH_mm_ss) -ItemType directory

    #Copy master html file into the new directory
    Copy-Item $(Join-Path $workingDir $htmlFileName) -Destination $destinationDir

    #Function call to update Token file
    UpdateTokenFile

    #Function call to update report parameters file
    UpdateReportParameters($reportUrl)
    
    $reportConfig.WorkSpace = $($workSpaceList[$workSpaceSelection-1].Name)
    $reportConfig.ReportName = $($reportList[$reportSelection-1].Name)
    $reportConfig.ConfiguredReportPath = $(Join-Path $destinationDir $htmlFileName)
    $reportConfig.SessionsToRun = $instances
    
    $reports += New-Object PSobject -Property $reportConfig
    --$reportCount
    $increment++
}

Write-Host "Listing reports configuration" -ForegroundColor Yellow
$reports | Format-Table -AutoSize

"You should manually edit the PBIReport.JSON file in each subdirectory further define the configuration of that load test. Feel free to rename the subdirectories to a meaningful name."

"When ready, run Run_Load_Test_Only.ps1 to launch the test"

"At least every 60 minutes you will need to run Update_Token_Only.ps1"


