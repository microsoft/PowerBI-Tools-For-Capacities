# Power BI Dedicated Capacity Load Assessment Tool

## Load Test Tool Options:  
- For "worst case scenario" load testing to simulate every user in the company opening the report at the same exact time, use the tool described on this current page.
- For "realistic user scenario" load testing to simulate a realistic set of user actions such as changing slicers, changing filters, clicking bookmarks, and simulating user "think time" where a user studies the report before clicking again, use the [Realistic Load Test Tool](../RealisticLoadTestTool)


#### Change Log
- 7/23/2019 - Fixed missing JSON issue

## This package includes:  
- **Powershell script** (starting point) - Interactively gets inputs from the user and updates the PBIToken and PBIReport files.
- **PBIToken** (JS Object File) file which stores Aad access token for the connections to work.
- **PBIReport** (JS Object File) file which stores report parameters including report url, filter parameters.
- **HTML + Javascript single pager** - Uses PBIToken and PBIReport files to get access token, report details and initiates the load.

### Prereqs:
- This package requires an elevated PowerShell console to run. (i.e. "Run As Administrator") 
- This package contains an unsigned PowerShell script. You must first use Set-ExecutionPolicy Unrestricted command in order to allow running of unsigned scripts.
- This package requires the "MicrosoftPowerBIMgmt" Power BI PowerShell modules to be installed from [here](https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps).

### Video Walk Through

A video walk through is availble [here](https://www.youtube.com/watch?time_continue=1860&v=C6vk6wk9dcw)

### Description:

- This package is meant for purposeful introduction of report rendering load against a Premium Capacity. 
- The tool should be used to assess how many continuose and simultaneouse render requests of certain reports can a Premium capacity handle.
- The tool is meant to be used in capacity planning and scale evaluation scenarios, when admins of Power BI capacities wish to test the ability of their capacity to serve a certain scale.
- The main purpose of the tool to generate metrics that are visibile in the [Premium Capacity Metrics app](https://docs.microsoft.com/en-us/power-bi/service-admin-premium-monitor-capacity). Users should anlayze the results of the load run in this app.
- The tool will prompt users for Power BI credentials to obtain the reports that need to be ran against the capacity
- Users should pass credentials of workspace admins of the workspace cotaining the report\s to be tested
- The tool will ask the users how many reports they wish to run in parallel
- The tool will prompt the user for the workspace\s and the report\s to be tested.
- For each report, the tool will ask the user how many browser windows should hit that report simultenously.
- Once launched, the tool will open new Chrome windows for each instance. i.e. if report 1 had 4 simultenouse renders requested, the tool will open 4 seperat windows of Chrome (not Tabs). report 2 will have its own windows etc. 
- Users should always keep the Chrome windows open and in the viewport, otherwise the OS managment of the browser client interacting with Power BI will reduce the load the test is generating

##### Notes:
- By default, Aad access token expires in 60 minutes. Reports will run for 60 minutes once initiated and stop with error once access token expires.

###### HTML report file has been designed and implemented by [Sergei Gundorov](https://github.com/sergeig888).
