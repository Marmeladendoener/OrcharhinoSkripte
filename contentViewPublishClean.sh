#!/bin/bash



ORG="org AG"
LCENV="Library,Development,Testing,Production"
PIDARRAY=()
CVARRAY=()

for i in $(hammer --no-headers --csv content-view list --fields "Content view id")
do
        dummy=$(hammer content-view publish --is-force-promote true --organization "$ORG" --lifecycle-environments "$LCENV" --description "$(date)" --id "$i" 2>&1 ) &

PIDARRAY+=($!)
CVARRAY+=($i)


done

INDEX=0
for p in "${PIDARRAY[@]}"
do
        echo "=====[ CONTENT VIEW: $(hammer --no-headers --csv content-view info --id ${CVARRAY[$INDEX]} --fields 'Name') ]====="
        echo " Warte auf Prozess mit der PID $p"
        if wait $p; then
                echo "Neue Version erfolgreich veröffentlicht und promoted! "
        else
                echo "Es ist ein Problem aufgetreten "
        fi

        echo ""
INDEX=$(($INDEX + 1))
done
####

keepVersions=9

for i in $(hammer --no-headers --csv content-view list --fields "Content view id")
do
        echo ""
        echo "=====[ CONTENT VIEW: $(hammer --no-headers --csv content-view info --id $i --fields 'Name') ]===== "
        echo "Content view ID: $i"
        contentVersionsID=( $(hammer --no-headers --csv content-view version list --fields "Id" --content-view-id $i ) )
        len=${#contentVersionsID[@]}
        aLen=$(($len - 1))

        while [ $aLen -gt $(($keepVersions - 1)) ]
        do
                if [ $(hammer --no-headers --csv content-view version info --id ${contentVersionsID[$aLen]}  --fields "Lifecycle environments/label" | wc -c) -lt 2 ]; then
                        echo "Version $(hammer --no-headers --csv content-view version info --id ${contentVersionsID[$aLen]} --fields "Version") (ID: ${contentVersionsID[$aLen]} ) In keinem Lifecycle Environment, wird entfernt"
                        hammer content-view version delete --id ${contentVersionsID[$aLen]} --content-view-id $i
                else
                        echo "Version $(hammer --no-headers --csv content-view version info --id ${contentVersionsID[$aLen]} --fields "Version") (ID: ${contentVersionsID[$aLen]} )  Wird nicht entfernt, da in einem Lifecycle Environment"
                fi

                aLen=$(($aLen - 1))
        done
done

