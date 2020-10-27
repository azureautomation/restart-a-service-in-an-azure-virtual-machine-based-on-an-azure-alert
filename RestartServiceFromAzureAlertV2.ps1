
<#PSScriptInfo

.VERSION 1.1

.GUID 078a9f64-9a22-4495-95d9-e9195bbf0689

.AUTHOR evaman

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


.PRIVATEDATA 

#>

<#

.DESCRIPTION 
Start Service

#>

Param()


<#

This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within the Premier Customer Services Description.

.SYNOPSIS 
    This sample automation runbook is based on the Restart-ServiceFromAzureAlert runbook, created by the Automation Team and is designed to take the payload from an Azure Alert based on a Log Analytics query for stopped services.
    
    This runbook parses out the comptuter name and service name so that it could be extended to start the service
    on the machine downloading a script from a storage account and running it.


.DESCRIPTION
    This sample automation runbook is designed to take the payload from an Azure Alert based on a Log Analytics
    query for stopped services.
    
    This runbook parses out the comptuter name and service name so that it could be extended to start the service
    on the machine downloading a script from a storage account and running it.


    The query used from Log Analytics Azure Alert is: 

    Event
    | where ServiceName_CF == "Print Spooler" and ServiceState_CF == "stopped"

    Two custom fields have been created to be used on the previous query to extract the service display name and service state.

.PARAMETER WebhookData
    Optional. The Alert will pass in the json body of the above query when it is activated.

.NOTES
    AUTHOR: Everson Amancio, with Kleber Alves contribution
    RELEASE: April 03rd, 2019
    LASTEDIT: April 03rd, 2019
        - Updated for schema change

#>

Param(
     $WebhookData
 )

$VerbosePreference = "continue"

 # Payload comes in as a json object so convert the body into PowerShell friendly object.
$RequestBody = ConvertFrom-Json $WebhookData.RequestBody

# Get the results from the table object
$Result =  $RequestBody.data.SearchResult.tables

$i = -1
$Computer = -1
$ServiceName = -1

# Find the computer and service sent in by the alert
foreach ($val in $Result.columns) 
{
    $i++
    if ($val.name -eq "Computer")
    {         
        $Computer = $result.rows[$i] 
    }
    if ($val.name -eq "ServiceName_CF")
    {         
        $ServiceName = $Result.rows[$i] 
    }  
}

# Check if computer name was found
if ($Computer -eq -1)
{
    throw ("Computer name was not found in the payload sent over from the alert")
}

# Check if service name was found
if ($ServiceName -eq -1)
{
    throw ("Service name was not found in the payload sent over from the alert")
}

# Add service name to runbook parameters
$RunbookParameters = @{}
$RunbookParameters.Add("ServiceName",$Result.rows[$ServiceName])

$ComputerName = $Result.rows[$Computer]

# Authenticate with Azure.
$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

$Context = Set-AzureRmContext -SubscriptionId $ServicePrincipalConnection.SubscriptionID | Write-Verbose

#get the server name portion of FQDN
$Index = $Computer.IndexOf('.')
$VMName = $Computer.Substring(0,$Index) 
Write-Output $VMName

#get the Resource Group name from VM
$rgname = (Get-AzureRmVM | where {$_.Name -eq $VMName}).ResourceGroupName.ToLower()
Write-Output $rgname

#Donwload the script from the storage account and execute it.
$vmname = $VMName
$localmachineScript = 'Start-PrintSpooler.ps1'
wget "https://contoso.blob.core.windows.net/scripts/$localmachineScript" -outfile $localmachineScript 
Invoke-AzureRmVMRunCommand -ResourceGroupName $rgname -Name $vmname -CommandId 'RunPowerShellScript' -ScriptPath $localmachineScript
