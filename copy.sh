#!/bin/bash
Namespace=$NAMESPACE
Pod=$POD
DesNode=$DESNODE
RootPath=$ROOTPATH
Namespace=default
Pod=mai-0
DesNode=c32010s8
RootPath="/data/"

echo $NAMESPACE $POD $DESNODE
retry -f "exit 1" "kubectl get pod -n $Namespace $Pod -o json > pod.json"
PVCS=$(cat pod.json | tr '\r\n' ' '|   jq -r '[.spec.volumes[] | .persistentVolumeClaim.claimName ]| del( .[]| nulls) | .[]')
Mounts=$(cat pod.json | tr '\r\n' ' '| jq -r ".
| [(.spec.containers[]) | .volumeMounts[]]
")
echo $PVCS 
echo $Mounts
for Pvc in "${PVCS}"
do
	#TODO: COPY TAR to container
	retry -f "exit 1" "kubectl get pvc -n $Namespace $Pvc -o json > old-${Pvc}-pvc.json"
	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	retry -f "exit 1" "kubectl get pv $Pv -o json > old-${Pvc}-pv.json"
	PvcOldPolicy=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	| (.spec.persistentVolumeReclaimPolicy)
	")
	echo $Pvc
	VolumName=$( cat pod.json | tr '\r\n' ' '|   jq -r ".
	| .spec.volumes[] 
	| select(.persistentVolumeClaim.claimName == \"$Pvc\") 
	| .name "
	)
	echo $VolumName
	PodPath=$(echo $Mounts | jq -r ".[]
	| select(.name==\"$VolumName\" ) 
	| .mountPath")
	echo $PodPath
	HOSTPATH=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	| (.spec.hostPath.path)
	")
	echo $RootPath/$HOSTPATH
	#echo $Containers
	#Mounts=""
	#for container in "$Containers":
	#Mounts=
	#PODPATH=$(cat pod.json | tr '\r\n' ' '| jq -r ".
	#| (.spec.containers[0].volumeMounts)
	#")
	#echo $PODPATH
	#echo $(basedir($PodPath))
	echo $(dirname "$PodPath") 
	#mkdir -p $(dirname "$PodPath") 
	#TODO OPEN BELOW IT
	#kubectl cp $Namespace/$Pod:$PodPath $ROOTPATH/$HOSTPATH
done
