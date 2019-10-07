################################################################################################################################################################################
# Script executes the load test
# If run with no parameters, it will execute the load test found in each subfolder:
#  .\Run_Load_Test_Only.ps1
# If run with parameters, it will only execute the subfolders specified:
#  .\Run_Load_Test_Only.ps1 "DemoLoadTest1" "DemoLoadTest2"
# It pauses 5 seconds between opening each window so as not to overload the client machine CPU during initiation of the load test.
# Once load test windows are opened, it waits for the user to press enter again at which point it closes *all* open Chrome windows for the current user. Note it does not just close Chrome windows it opens.
# Run this script as administrator
################################################################################################################################################################################

$htmlFileName = 'RealisticLoadTest.html'
$workingDir = $pwd.Path
"This script finds all subdirectories with $htmlFileName files and runs a specifies number of instances of each."
$instances = [int] $(Read-Host -Prompt 'Enter number of instances to initiate for each report')
$numberOfPhysicalCores = (Get-WmiObject –class Win32_processor).NumberOfCores;
if ($numberOfPhysicalCores.Length)
{
    #if computer has multiple sockets, then sum the array
    $numberOfPhysicalCores = ($numberOfPhysicalCores | Measure-Object -Sum).Sum;
}
"Number of chrome processes to create: $numberOfPhysicalCores (# physical cores)";
"Each chrome process requires 1-2GB RAM!"

$registryPath = "HKCU:\Software\Policies\Google\Chrome"
"Setting registry $registryPath to prevent Chrome's software_reporter_tool.exe from running during this test on the new profile directories"
$Name = "ChromeCleanupEnabled"
$Name2 = "ChromeCleanupReportingEnabled"
$value = 0
$backupValue = Get-ItemProperty -Path $registryPath -Name $Name -ErrorAction SilentlyContinue
$backupValue2 = Get-ItemProperty -Path $registryPath -Name $Name2 -ErrorAction SilentlyContinue
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $Name2 -Value $value -PropertyType DWORD -Force | Out-Null


$profile = 0;
$directories = @();
foreach ($destinationDir in $args)
{
    $directories += ,$destinationDir;
}
if ($directories.Length -eq 0)
{
    foreach ($destinationDir in Get-ChildItem -Path $workingDir -Directory)
    {
        $directories += ,$destinationDir.Name;
    }
}


foreach ($destinationDir in $directories)
{
    $reportHtmlFile = $(Join-Path (Join-Path $workingDir $destinationDir) $htmlFileName);
    if (Test-Path -path $reportHtmlFile)
    {
        $loopCounter = [int]$instances
        while($loopCounter -gt 0)
        {
        $reportHtmlFile
            start chrome "--user-data-dir=""ChromeProfiles\Profile$profile"" --disable-default-apps --new-window ""$($reportHtmlFile)"""            
            --$loopCounter
            $profile = ($profile+1) % $numberOfPhysicalCores;
            sleep -Seconds 5
        }
    }
}

"Press enter when load test is complete: "
pause
"closing all chrome windows"
start taskkill "/IM chrome.exe /FI ""USERNAME eq $env:UserName"""
"Setting registry $registryPath back"
Remove-ItemProperty -Path $registryPath -Name $name
Remove-ItemProperty -Path $registryPath -Name $name2