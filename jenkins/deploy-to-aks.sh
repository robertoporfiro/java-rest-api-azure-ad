#/bin/bash

CONTAINERNAME=$1
CONTAINERVERSION=$2
# The env vars in this script should be set by the Jenkinsfile

echo "Deploying : ResourceGroup=$AZRGNAME, ACR=$AZACRNAME, AKS=$AZAKSNAME, Location=$AZLOCATION"

# login to ACR/AKS
az acr login --name $AZACRNAME
az aks get-credentials --resource-group $AZRGNAME --name $AZAKSNAME

# get the server name of the ACR
ACRLOGINSERVER=$(az acr show --resource-group $AZRGNAME --name $AZACRNAME --query "loginServer" --output tsv)

# tag the container for ACR and push it
docker tag $CONTAINERNAME:$CONTAINERVERSION $ACRLOGINSERVER/$CONTAINERNAME:$CONTAINERVERSION
docker tag $CONTAINERNAME:$CONTAINERVERSION $ACRLOGINSERVER/$CONTAINERNAME:latest
docker push $ACRLOGINSERVER/$CONTAINERNAME:latest

# modify the deployment yaml
cp ./jenkins/deploy-aks-generic.yaml ./jenkins/deploy-aks.yaml
sed -i -e "s/xxx-CONTAINERNAME-xxx/$CONTAINERNAME/g" ./jenkins/deploy-aks.yaml
sed -i -e "s/xxx-replace-me-ACRLOGINSERVER-xxx/$ACRLOGINSERVER/g" ./jenkins/deploy-aks.yaml
sed -i -e "s/xxx-replace-me-DNSZONE-xxx/$DNSZONE/g" ./jenkins/deploy-aks.yaml

# deploy
kubectl apply -f ./jenkins/deploy-aks.yaml

rm ./jenkins/deploy-aks.yaml

# az aks browse --resource-group $AZRGNAME --name $AZAKSNAME
