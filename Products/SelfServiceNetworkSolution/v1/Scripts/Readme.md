[[_TOC_]]

# Readme.md

This Readme.md consists of a comprehensive description of the files that are located within the DeveloperScripts folder. It a script states otherwise within the description of that script, please follow the scripts description.

## Create-UDRFiles.ps1

## Create-VirtualNetworkStage.ps1

This script is used to create a Stage within the Release Pipeline and orders the Stages.

## Create-VNetPeeringFilesAndEnvironment.ps1

## Get-NetworkInterfaceTags.ps1

## Parse-ReadmeMd.ps1

Pre-requisites:

- Path to the readme file
- Readme formatting as defined in `Readme.vnet.md`
- The parent folder of the readme file must be the subscription one (Engineering, Management, VDC1, VDC2S)

### NSG Port conversions

Overview of the port numbers that are converted to well known service names within CBSP Azure.

|From port|To port|Name|Port type|
|-|-|-|-|
|*|22|SSH|TCP|
|*|53|DNS|*|
|*|80|HTTP|TCP|
|*|80, 443|HTTP-S|TCP|
|*|443|HTTPS|TCP|
|*|454, 455, 16001|ASEManagement|TCP|
|*|454-455|ASEManagement|TCP|
|*|1433, 11000-11999|AzureSQL|TCP|
|*|3389|RDP|TCP|
|*|4040, 4050|Spark|TCP|
|*|5000|Portainer|TCP|
|*|8080|HTTPProxy|TCP|
|*|8088|Zeppelin Notebook|TCP|
|*|8161|ActiveMQ|TCP|
|*|9094, 9095, 9096|KAFKA|TCP|
|*|50070|Hadoop|TCP
|*|65503-65534|HealthProbe|TCP|

### NSG settings

It will process each line within the table to create the Network Security Group parameter file with the inbound and outbound rules. The parameter file is completed with the settings from `Settings.json`.

## Set-ReleasePipelineStageOrder.ps1

This script is used to sort the Stages within a Network Release Pipeline. The implementation of this script is used/moved to the `Create-VirtualNetworkStage.ps1` script.
