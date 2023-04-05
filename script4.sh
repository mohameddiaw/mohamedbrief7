#!/bin/bash
# Variables
resourceGroupName="mdiawloadbalancer"
location="francecentral"
vmNamePrefix="brief7VM"
adminUsername="mdiaw"
adminPassword="Pa$$w0rd"
publicIPAdressName="brief7IP"
loadBalancerName="brief7loadbalancer"
dbName="brief7MariaDB"
dbUserName="mdiaw"
dbPassword="Passw0rd"
# Créer un groupe de ressources
az group create     --name $resourceGroupName    --location $location
# créer un réseau virtuel et un sous réseau
az network vnet create    --name brief7Vnet    --resource-group $resourceGroupName   --location $location   --address-prefix 10.0.0.0/16   --subnet-name brief7Subnet   --subnet-prefix 10.0.1.0/24
# créer une adresse IP publique
az network public-ip create    --name $publicIPAddressName   --resource-group $resourceGroupName   --location $location   --sku Basic   --allocation-method Static
# créer un load balancer
az network lb create    --name $loadBalancerName   --resource-group $resourceGroupName   --location $location   --frontend-ip-name FrontEndPool   --public-ip-address $publicIPAddressName--backend-pool-name BackEndPool
# créer les règles du load balancer
az network lb rule create   --resource-group $resourceGroupName   --name HTTPRule   --lb-name $loadBalancerName   --protocol tcp   --frontend-port 80    --backend-port 80   --frontend-ip-name FrontEndPool   --Backend-pool-name BackEndPool
# créer 2 vms avec wordpress
for i in 1 2;
do
az vm create \
   --resource-group $resourceGroupName \
   --name "${vmNamePrefix}${i}" \
   --location $location \
   --size Standard_B1s \
   --image UbuntuLTS \
   --admin-username $adminUsername \
   --admin-password $adminPassword \
   --vnet-name brief7Vnet \
   --subnet brief7Subnet \
   --public-ip-address "" \
   --nsg "" \
   --generate-ssh-keys \
   --custom-data cloud-init-wordpress.txt
# ajouter les vms au load balancer
az network nic ip-config update \
   --name "ipconfig1" \

   --nic-name "${vmNamePrefix}${i}VMNic" \
   --resource-group $resourceGroupName \
   --lb-name $loadBalancerName \
   --lb-address-pools BackEndPool
done
# créer la base de donnée MariaDB (SAAS)
az mariadb server create --name $dbName   --resource-group $resourceGroupName   --location $location   --admin-user $dbUsername   --admin-password $dbPassword   --sku-name GP_Gen5_2   --version 10.3   --storage-size 51200

# Afficher l'adresse ip du load balancer
az network public-ip show    --name $publicIPAddressName   --resource-group $resourceGroupName   --query [ipAddress]   --output tsv vbnet
