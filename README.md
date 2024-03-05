# Sentinel Bulk Threat Intelligence-Management
Currently when you delete a TI feed in Sentinel, the indicator from that feed are not automatically deleted until the indicators expire. This becomes an issue if the indicators do not have an expiration data. 
This script can help you  bulk delete sentinel threat intelligence based on specific sources

Proceed with caution, this script can delete millions of indicators at a time.

## Usage
Run TIManagement.ps1
Enter the details of your Sentinel workspace
Select the source (provider) you want to delete TI from
Enter y/n to continue or exit
