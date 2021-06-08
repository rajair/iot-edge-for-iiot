#!/usr/bin/env bash

function show_help() {
   # Display Help
   echo "Run this script to update MCC manifest"
   echo
   echo "Syntax: sudo bash ./update_deploy_mcc.sh -containerName='containerregistry' -containerUserName=containerregistry -containerPassword=$password -containerImageSubPath='/mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70' -hubName=AduHub"
   echo ""
   echo ""
   echo "-containerName           Name of the registry container that was created"
   echo "-containerUserName       UserName for the RegistryContianer"
   echo "-containerPassword       Password for the Container"
   echo "-containerImageSubPath   Image Subpath for MCC e.g. '/mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70' where full path is containerregistry.azurecr.io/mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70 "
   echo "-hubName                 HubName that is used e.g. DOAduHub"
   echo
}


# Get arguments
while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit;;
        -containerName=?*)
            containerName=${1#*=}
            ;;
        -containerName=)
            echo "Missing containerName Exiting."
            exit;;
        -containerUserName=?*)
            containerUserName=${1#*=}
            ;;
        -containerUserName=)
            echo "Missing containerUserName. Exiting."
            exit;;
        -containerPassword=?*)
            containerPassword=${1#*=}
            ;;
        -containerPassword=)
            echo "Missing containerPassword. Exiting."
            exit;;
        -containerImageSubPath=?*)
            containerImageSubPath=${1#*=}
            ;;
        -containerImageSubPath=)
            echo "Missing containerImageSubPath. Exiting."
            exit;;
        -hubName=?*)
            hubName=${1#*=}
            ;;
        -hubName=)
            echo "Missing hubName. Exiting."
            exit;;
        --)
            shift
            break;;
        *)
            break
    esac
    shift
done

escapedContainerPassword="$(echo "$containerPassword" | sed -e 's/[()&/]/\\&/g')"
escapedContainerImageSubPath="$(echo "$containerImageSubPath" | sed -e 's/[()&/]/\\&/g')"

# ***** L3Edge *****
echo "***** Update L3-Edge *****"
#Copy the Template to the outputFilePath and Update
inputTemplateFile="./L3EdgeModule-Template.json"
outputFile=$(echo $inputTemplateFile | cut -d "-" -f1)".json"
cp $inputTemplateFile $outputFile

#Replace CustomerID, cacheNode_ID, CustomerKey with Guid
#idKey=$(uuidgen)
xcid=`date +"%s"`
idKey="IDKeyL5"$xcid
sed -i "s/#placeholder-guid#/$idKey/" $outputFile

#replace X_CID
xcid=`date +"%s"`
sed -i "s/#placeholder-xcid#/${xcid}/" $outputFile

#replace MCCImagePath $upstream:443#placeholder-mccimagepath# replaced by $upstream:443/mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70
sed -i "s/#placeholder-mccimagepath#/$escapedContainerImageSubPath/" $outputFile



# ***** L4Edge *****
echo "***** Update L4-Edge *****"
#Copy the Template to the outputFilePath and Update
inputTemplateFile="./L4EdgeModule-Template.json"
outputFile=$(echo $inputTemplateFile | cut -d "-" -f1)".json"
cp $inputTemplateFile $outputFile

#Replace Container Name
sed -i "s/#placeholder-containername#/${containerName}/" $outputFile 

#Replace containerUserName
sed -i "s/#placeholder-containerusername#/$containerUserName/" $outputFile 

#Replace containerPassword
sed -i "s/#placeholder-containerpassword#/$escapedContainerPassword/" $outputFile 

#Replace CustomerID, cacheNode_ID, CustomerKey with Guid
#idKey=$(uuidgen)
xcid=`date +"%s"`
idKey="IDKeyL4"$xcid
sed -i "s/#placeholder-guid#/$idKey/" $outputFile

#replace X_CID
xcid=`date +"%s"`
sed -i "s/#placeholder-xcid#/${xcid}/" $outputFile

#replace MCCImagePath $upstream:443#placeholder-mccimagepath# replaced by $upstream:443/mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70
sed -i "s/#placeholder-mccimagepath#/$escapedContainerImageSubPath/" $outputFile



# ***** L5Edge *****
echo "***** Update L5-Edge *****"
#Copy the Template to the outputFilePath and Update
inputTemplateFile="L5EdgeModule-Template.json"
outputFile=$(echo $inputTemplateFile | cut -d "-" -f1)".json"
cp $inputTemplateFile $outputFile

#Replace Container Name
sed -i "s/#placeholder-containername#/${containerName}/" $outputFile 

#Replace containerUserName
sed -i "s/#placeholder-containerusername#/$containerUserName/" $outputFile 

#Replace containerPassword
sed -i "s/#placeholder-containerpassword#/$escapedContainerPassword/" $outputFile 

#Replace CustomerID, cacheNode_ID, CustomerKey with Guid
#idKey=$(uuidgen)
xcid=`date +"%s"`
idKey="IDKeyL5"$xcid
sed -i "s/#placeholder-guid#/$idKey/" $outputFile

#replace X_CID
xcid=`date +"%s"`
sed -i "s/#placeholder-xcid#/${xcid}/" $outputFile

#replace MCCImagePath $containerRegistry*.#placeholder-mccimagepath# replaced by $containerRegistry*./mcc/linux/iot/mcc-ubuntu-iot-amd64:1.2.1.70
sed -i "s/#placeholder-mccimagepath#/$escapedContainerImageSubPath/" $outputFile

echo "Set the Modules for L5, L4 and L3"
az iot edge set-modules --device-id L5-edge --hub-name $hubName --content "L5EdgeModule.json"
az iot edge set-modules --device-id L4-edge --hub-name $hubName --content "L4EdgeModule.json"
az iot edge set-modules --device-id L3-edge --hub-name $hubName --content "L3EdgeModule.json"

echo "Wait for 2 Minutes for Modules to be running"
sleep 2m
az iot hub module-identity list --device-id L5-edge --hub-name $hubName
az iot hub module-identity list --device-id L4-edge --hub-name $hubName
az iot hub module-identity list --device-id L3-edge --hub-name $hubName