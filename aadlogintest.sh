#!/usr/bin/env bash

#######################################################################################################################
# Title:  	AADLoginExtension Install on Linux VMs
# Author: 	Marin Nedea 
# Usage:  	Change the variables to your own. 
#		        Make sure the script has executable permissions:
#		        chmod +x aadlogintest.sh
#		        execute the script by typing:  ./aadlogintest.sh
# Requires:	AzCli 2.0 to run: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
#
# Supported Azure regions and Linux distributions:
#
# The following Linux distributions are currently supported during the preview of this feature:
# -CentOS 6.9, and CentOS 7.4
# -Debian 9
# -RHEL 6, RHEL 7
# -Ubuntu 14.04 LTS, Ubuntu Server 16.04, Ubuntu Server 17.10, and Ubuntu Server 18.04
#
# The following Azure regions are currently supported during the preview of this feature:
# - All global Azure regions
#######################################################################################################################

# Login into Azure 
# az login
#
# If multiple subscription, set the one where VM and KeyVault are.
# az account set -s "<YourSubscriptionID>"

# Decide on a region for the resources to be created
region="westus"

# Set a resource group name 
rgName="aadlogintest"

# Create the Resource Group
az group create --name $rgName --location $region

# Use a specific admin username
adminusername="azureuser"

# Get the AAD account
username=$(az account show --query user.name --output tsv)

# Simulate a multidimensional array for the VMs we need to create, 
# each subarray containing the VM name, Linux Image URN, and a counter
declare -a vms

#Ubuntu (latest image for each version)
vms[0]='AADU1404;Canonical:UbuntuServer:14.04.5-LTS:14.04.201809130;1'
vms[1]='AADU1604;UbuntuLTS;2'
vms[2]='AADU11710;Canonical:UbuntuServer:17.10:17.10.201807060;3'
vms[3]='AADU1804;Canonical:UbuntuServer:18.04-LTS:18.04.201809110;4'

#CentOS (latest image for each version)
vms[4]='AADCentOS69;OpenLogic:CentOS:6.9:6.9.20180530;5'
vms[5]='AADCentOS74;OpenLogic:CentOS:7.4:7.4.20180704;6'

# RHEL (latest image for each version)
vms[6]='AADRHEL67;RedHat:RHEL:6.7:6.7.2017090815;7'
vms[7]='AADRHEL68;RedHat:RHEL:6.8:6.8.2017090906;8'
vms[8]='AADRHEL69;RedHat:RHEL:6.9:6.9.2018010506;9'
vms[9]='AADRHEL610;RedHat:RHEL:6.10:6.10.2018071006;10'
vms[10]='AADRHEL72;RedHat:RHEL:7.2:7.2.2017090716;11'
vms[11]='AADRHEL73;RedHat:RHEL:7.3:latest;12'
vms[12]='AADRHEL74;RedHat:RHEL:7.4:7.4.2018010506;13'
vms[13]='AADRHEL75;RedHat:RHEL:7-RAW:7.5.2018081518;14'
vms[14]='AADRHEL76Beta;RedHat:RHEL:7.6-BETA:7.6.2018091307;15'

# Debian (latest image for each version)
vms[15]='AADDebian9;credativ:Debian:9:9.0.201808270;16'

# Let's get the variables from the fake multidimensional array
for i in "${vms[@]}"
do
        arr=(${i//;/ })
        vmName=${arr[0]}		#VM Name
        vmImage=${arr[1]}		#VM Image
		c=${arr[2]}				#Entry Counter

# Create the VMs
# NOTE: I'm limited to 100vCPUs/region, so I decided to have the VMs 
# size set to Standard_DS2_v2 (2vCPUs/7GB Ram), meaning I will have a total 
# quota usage  of 32 vCPUs for the above test VMs

az vm create \
	--resource-group $rgName \
	--name $vmName \
	--image $vmImage \
	--size Standard_DS2_v2 \
	--admin-username $adminusername \
	--generate-ssh-keys

#Install the Azure AD login VM extension on the newly created VM
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory.LinuxSSH \
    --name AADLoginForLinux \
    --resource-group $rgName \
    --vm-name $vmName

# Configure role assignments for the newly created VM	
vm=$(az vm show --resource-group $rgName --name $vmName --query id -o tsv)
az role assignment create \
    --role "Virtual Machine Administrator Login" \
    --assignee $username \
    --scope $vm

# Retrieve the public IPs and add them to an external file,
# so we can later use them and test the aadlogin:
az vm show \
	--resource-group $rgName \
	--name $vmName \
	-d --query publicIps \
	-o tsv >> /tmp/PublicIpList.txt

done
exit 0
