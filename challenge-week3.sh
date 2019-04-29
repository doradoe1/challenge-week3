#!bin/bash

##Script to create a brand new VM##

##Parameters.##
read -p "Enter the resource group: " resourcegroup
read -p "Enter a location for resource group: " location
read -p "Enter a name for the VM: " vmname
read -p "Enter the image (UbuntuLTS commonly used): " image
read -p "Enter the size (Standard_B2s commonly used): " size
read -p "Enter the disk name: " diskname
read -p "Enter the os type (Linux or Windows): " os
read -p "Enter the size (read in gb) for the disk: "  sizegb

##Create a resource group. Check if resource group already exists. If so, skip.##
verifyrg=$(az group exists \
--name $resourcegroup \
| grep -E true)

if [ $verifyvrg=true ]; then
echo "Resource group Valid." 0>&2
else
echo "Creating new resource group. Please wait."
az group create --name $resourcegroup --location $location
exit 0
fi

##Create a VM.##
##Verify that there are no duplicates for the VM.##
##ssh keys are stored in /.ssh directory.##
##Since no location is asked for, it defaults to the location given in the resource group.##
verifyvm=$(az vm list \
--resource-group $resourcegroup \
-d \
--query [].name \
| grep -E $vmname)

if [ -z $verifyvm ]; then
az vm create \
--resource-group $resourcegroup \
--name $vmname \
--image $image \
--size $size \
--generate-ssh-keys \
--admin-username celeste \
--custom-data ./vminit.txt
echo "VM created. Thank you for using Azure."
sleep 15s
az vm show \
--resource-group $resourcegroup \
--name $vmname \
--show-details \
--output table
else
echo "VM name already in use. Proceding" \
0>&2
az vm show \
--resource-group $resourcegroup \
--name $vmname \
--show-details \
--output table
fi

##Creating the Disk:##
az disk create \
--name $diskname \
--resource-group $resourcegroup \         
--os-type $os \
--size-gb $sizegb

##Attaching the Disk to the VM:##
az vm disk attach \
--resource-group $resourcegroup \
--vm-name $vmname \
--name $diskname

##Making the disk visible to the VM's OS and mounting the Disk:##
sudo mkfs - ext4 /dev/sdc

sudo mkdir /media/$diskname
sudo mount /dev/sdc/ /media/$diskname

cp index.html /media/$diskname
cp index.js /media/$diskname
cp vminit.txt /media/$diskname
cp -r node_modules /media/$diskname

pip=$(az vm show \
--resource-group $resourcegroup \
--name $vmname \
--show-details \
--output table \
--query [].name
| grep -E $vmname)
ssh celeste@

