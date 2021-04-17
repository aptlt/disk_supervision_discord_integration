#!/bin/bash

####################################################################
#                                                                  #
#   Script permettant la surveillance de l'espace disque des fs    #
#   du serveur                                                     #
#                                                                  #
#   Création :                          13/04/2021                 #
#   Dernière modification :             13/04/2021                 #
#                                                                  #
#   Pré-requis : /                                                 #
#                                                                  #
####################################################################

## Définition des variables principales 

DATE=$(date +%d-%m-%Y_%H\h%M)

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

LOG_DIR=${WORK_DIR}/log
mkdir -p ${LOG_DIR}

IP_ADDR=`hostname -I | awk '{print $1}'`

## Creation du fichier de log envoye a Discord
log_send=${LOG_DIR}/filesystems_${DATE}.log

## Variable couleur OK
couleur=0x67C627

## Variable espace disque utilisé pour notification
space_used_notify=80

## Liste des fs sans les tmpfs
fileSystems=($(df -h | sed 1d | grep -v 'tmpfs' | awk '{print $1}' | xargs -n1 | sort -u | xargs))

## Liste des fs avec les tmpfs
#fileSystems=($(df -h | sed 1d | awk '{print $1}' | xargs -n1 | sort -u | xargs))

for fs in "${fileSystems[@]}"
do

    spaceUsed=`df -h | grep -m 1 ${fs} | awk '{printf $3}'`
    spaceAvailable=`df -h | grep -m 1 ${fs} | awk '{printf $4}'`
    spaceTotal=`df -h | grep -m 1 ${fs} | awk '{printf $2}'`
    spaceUsedPourcent=`df -h | grep -m 1 ${fs} | awk '{printf $5}'`
    spaceUsedPourcentWithout=`df -h | grep -m 1 ${fs} | awk '{printf $5}' | sed 's/.$//'`
    mountedPointOfi=`df -h | grep -m 1 ${fs} | awk '{printf $6}'`

    if [[ "${fs}" = "overlay" ]]
    then
        mountedPointOfi="`df -h | grep -m 1 ${fs} | awk '{printf $6}' | cut -f1,2,3,4,5 -d'/'`/[...]"
    fi

    echo -n "Statistiques pour ${mountedPointOfi} :\n" >> ${log_send}
    echo -n "--> ${fs}\n" >> ${log_send}
    echo -n "Espace total : ${spaceTotal}\n" >> ${log_send}
    echo -n "Espace disponible : ${spaceAvailable}\n" >> ${log_send}
    echo -n "Espace utilisé : ${spaceUsed} (${spaceUsedPourcent})\n\n" >> ${log_send}
    echo "${fs}" 
    if (( "${spaceUsedPourcentWithout}" >= ${space_used_notify} ))
    then
        couleur=0xD21D38
	    notify_owner="<@code_discord_user_to_notify>"
    fi

done

## Declaration de la variable DISCORD_WEBHOOK
DISCORD_WEBHOOK=https://URL_WEBHOOK_DISCORD
export DISCORD_WEBHOOK

## Supprimer les retour a la ligne et les remplacer par le string "\n"
sed -i ':a;N;$!ba;s/\n/\\n/g' ${log_send}

## Envoi 
text_discord=`cat ${log_send}`

${WORK_DIR}/discord.sh \
    --username "RoboDisk.o" \
    --title "[${IP_ADDR}] RECAPITULATIF ESPACE DISQUE ${DATE}" \
    --description "${text_discord}" \
    --text "${notify_owner}" \
    --color ${couleur}
