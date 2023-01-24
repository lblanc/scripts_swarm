#!/bin/bash
#
#
# Author  : Luc BLANC
# Date    : 23/01/24
# Version : 1.0
#
# Description : This script remove delete marker on all objects inside bucket
 

########
#
# PARAMETERS
#
 

#SWARM User's credentials
USER=''
PASSWD=''

# Var
DOMAIN=''
BUCKET=''

 

 
########
#
# SCRIPT
#
 
clear


echo
if [[ ${USER} == "" ]]; then read -p "User : " USER; fi

echo
if [[ ${PASSWD} == "" ]]; then read -p "Password : " PASSWD; fi


echo
if [[ ${DOMAIN} == "" ]]; then read -p "Enter domain : " DOMAIN; fi

if [[ "${BUCKET}" == "" ]]
then  
echo 
echo "List existing buckets in '${DOMAIN}' :"
echo

while read BUCKET; do
        BUCKETS+=$(echo "$BUCKET" | jq -r .name)
        echo $BUCKET | jq -r .name
done <<EOT
$(curl -fsS -u ${USER}:${PASSWD} --post301 -X GET -L https://${DOMAIN}/?format=json | jq  -c '[.[] | {name: .name } ]' | sed "s/,{/\n{/g"  | sed "s/}]/}/g" | sed "s/\[{/{/g")
EOT

fi 


echo
if [[ ${BUCKET} == "" ]]; then read -p "Enter bucket name where you want to remove delete marker: " BUCKET; fi

result=$(curl -fsS -u ${USER}:${PASSWD} --post301 -X GET -L "https://${DOMAIN}/${BUCKET}?format=json&versions&deletemarker=true")

if [[ $(echo $result) != "[ ]" ]]
then 
  curl -fsS -u ${USER}:${PASSWD} --post301 -X GET -L "https://${DOMAIN}/${BUCKET}?format=json&versions&deletemarker=true"| \
   jq  -c '[.[] | {name: .name, version: .hash} ]' | sed "s/,{/\n{/g"  | sed "s/}]/}/g" | sed "s/\[{/{/g" | \
  while read FILE; do
    if [[ "$FILE" == "" ]]; then break; fi
    if [[ $(echo $FILE | jq -r .name) == "" ]]; then break; else name=$(echo $FILE | jq -r .name); fi
    if [[ $(echo $FILE | jq -r .version) == "" ]]; then break; else version=$(echo $FILE | jq -r .version); fi
    echo $name
    curl -fsS -u ${USER}:${PASSWD} --post301 -X DELETE -L  "https://${DOMAIN}/${BUCKET}/$name?version=$version"
  done
fi




