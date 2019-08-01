################################################################################################################################################################################
# Script to update the token file in all subfolders since tokens expire after 60 minutes
#------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Expected Result:
# ----------------
# The first run in the current PowerShell session will prompt you to login to Power BI. Subsequent runs will not prompt.
# The script obtains a new token then updates the PBIToken.JSON file in each subfolder of the current working directory.
#
################################################################################################################################################################################

#Variables declaration
$destinationDir = ''
$workingDir = $pwd.Path

# Regular expressions to match and update JSON files
$token_regex = '(?<=PBIToken\":\").*?(?=\")'
$accessToken = $null;

#Function implementation to update token file
function UpdateTokenFile
{     
    $tokenJSONFile = Get-Content $(Join-Path $workingDir 'PBIToken.JSON') -raw -ErrorAction SilentlyContinue #gg edited this
    $new_TokenJSONFile = ($tokenJSONFile -replace $token_regex,$accessToken)
    $new_TokenJSONFile | set-content $(Join-Path $destinationDir 'PBIToken.JSON')
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


# Get required inputs from user
try
{
    $accessToken = Get-PowerBIAccessToken -AsString | % {$_.replace("Bearer ","").Trim()}
	if ($user.UserName -ne $null)
	{
	    Write-Host "Already signed in as $($user.UserName)"
	}
	else
	{
		Write-Host "Already signed in" #must have signed in with a different window
	}
}
catch
{
    Write-Host "Select Id to authenticate to Power BI" -ForegroundColor Yellow
    $user = Login-PowerBI
    $user
}

foreach ($destinationDir in Get-ChildItem -Path $workingDir -Directory)
{
    if (Test-Path -path $(Join-Path $destinationDir 'PBIToken.JSON'))
    {
        #Function call to update Token file
        UpdateTokenFile
    }
}
