Restart a service in an Azure virtual machine based on an Azure Alert
=====================================================================

            
 

This sample automation runbook is based on the Restart-ServiceFromAzureAlert runbook, created by the Automation Team and is designed to take the payload from an Azure Alert based on a Log Analytics query for stopped services.


This runbook parses out the comptuter name and service name so that it could be extended to start the service on the machine downloading a script from a storage account and running it.


The query used from Log Analytics Azure Alert is: 

 **   Event    | where ServiceName_CF == 'Print Spooler' and ServiceState_CF == 'stopped'**


Two custom fields have been created to be used on the previous query to extract the service display name and service state.


A script to start the service must be created and hosted in a blob storage container, to be downloaded and executed.


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
