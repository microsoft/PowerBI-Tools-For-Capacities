################################################################################################################################################################################
# Script to assess the load capacity for Power BI Reports
#-------------------------------------------------------------------
#
# PRE-REQUISITES:
# ---------------
# Access to PowerBI Service
# Filter conditions need to be entered for report execution. 
# Filters conditions include Table Name, Column Name, Starting value of the column and Max value of the column. 
# The column selected should be a numeric where in an increment will be applied.
# Script requires "PBIESinglePageUOD_noADAL_event_filter_loop.html", "PBIReport.JSON" and "PBIToken.JSON" files provided in the package.
# 
#
# WORKING:
# --------
# Aad access token will be used for authorized login to access workspace, reports and initiate execution. 
# By default, Aad access token expires in 60 minutes and the html render stops with access error. 
# Number of instances given by the user decides the number of browser windows to be opened
#
#
# Expected Result:
# ----------------
# Once the inputs are provided, script will save a folder in the current working directory for each report with copy of above mentioned fils configured with respective inputs.
# Depending on the input whether to start executing the tests, script will open the browser windows as per the reports/instances configured.
################################################################################################################################################################################

#Variables declaration
$destinationDir = ''
$workingDir = $pwd.Path
$masterFilesExists = $true
$multiReportConfiguration = $true
$htmlFileName = 'PBIESinglePageUOD_noADAL_event_filter_loop.html'
$reportConfig = @{}
$reports = @()

# Regular expressions to match and update JSON files
$token_regex = '(?<=PBIToken\":\").*?(?=\")'
$reportUrlRegex = '(?<=reportUrl\":\").*?(?=\")' 
$filterTableRegex = '(?<=filterTable\":\").*?(?=\")'
$filterColumnRegex = '(?<=filterColumn\":\").*?(?=\")'
$minValueRegex = '(?<=filterStart\":).*?(?=,)' 
$maxValueRegex = '(?<=filterMax\":).*?(?=,)'


#Function implementation to update token file
function UpdateTokenFile
{     
    $accessToken = Get-PowerBIAccessToken -AsString | % {$_.replace("Bearer ","").Trim()}
    $tokenJSONFile = Get-Content $(Join-Path $workingDir 'PBIToken.JSON') -raw
    $new_TokenJSONFile = ($tokenJSONFile -replace $token_regex,$accessToken)
    $new_TokenJSONFile | set-content $(Join-Path $destinationDir 'PBIToken.JSON')
}

#Function implementation to update report parameters file
function UpdateReportParameters
{ $Args[0], $Args[1]
    $reportJSONFile = Get-Content $(Join-Path $workingDir 'PBIReport.JSON') -raw
    $new_ReportJSONFile = ($reportJSONFile -replace $reportUrlRegex,$args[0][0])
    $new_ReportJSONFile = ($new_ReportJSONFile -replace $filterTableRegex,$args[0][1][0])
    $new_ReportJSONFile = ($new_ReportJSONFile -replace $filterColumnRegex,$args[0][1][1])  
    $new_ReportJSONFile = ($new_ReportJSONFile -replace $minValueRegex,$args[0][1][2])
    $new_ReportJSONFile = ($new_ReportJSONFile -replace $maxValueRegex,$args[0][1][3])
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
    
    # Get required inputs from user if the user in china ,use Connect-PowerBIServiceAccount -Environment China . remember to install this in powershell first: Install-Module -Name MicrosoftPowerBIMgmt
    Write-Host "Select Id to authenticate to Power BI" -ForegroundColor Yellow
	$response = Read-Host "Are you using chinese Azure?[y/n]"
	if ( $response -eq 'y' ) 
	{     
		Connect-PowerBIServiceAccount -Environment China
	}
	if ( $response -eq 'n' ) 
	{     
		Login-PowerBI
	}

    #Accessing list of workspaces
    $workSpaceList = Get-PowerBIWorkspace

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
    Write-Host "Filters require FilterTable, FilterColumn,MinimumValue and MaximumValue in FilterColumn" -ForegroundColor Yellow

    # loop to prompt user for filter conditions until inputs are in the required format
    $filterInputValidation = $true
    while($filterInputValidation)
    {     
        $filters = Read-Host -Prompt 'Enter Filter values separated by comma(,). Ex:TableName,ColumnName,100,1000' 
        $filterParameters = $filters.Split(',')
        if($filterParameters.count -lt 4)
        {        
            Write-Host "Filters values entered incorrectly. Try entering again in the specified format." -ForegroundColor Red
        }
        else
        {
            $filterInputValidation = $false
        }
    }
    $instances = [int] $(Read-Host -Prompt 'Enter number of instances to initiate for this report')

    #Creating sub-folder to create a report set
    $destinationDir = new-item -Path $workingDir -Name $(get-date -f MM-dd-yyyy_HH_mm_ss) -ItemType directory

    #Copy master html file into the new directory
    Copy-Item $(Join-Path $workingDir $htmlFileName) -Destination $destinationDir

    #Function call to update Token file
    UpdateTokenFile

    #Function call to update report parameters file
    UpdateReportParameters($reportUrl,$filterParameters)
    
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

#Opening instances as required
$response = Read-Host "Do you want to launch configured reports?[y/n]"
if ( $response -eq 'y' ) 
{     
    foreach( $item in $reports)
    {        
        $loopCounter = [int]$item.SessionsToRun
        while($loopCounter -gt 0)
        {       
            start chrome "--new-window $($item.ConfiguredReportPath)"            
            --$loopCounter
        }
    }
}


