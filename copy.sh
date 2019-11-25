#!/bin/bash
Namespace=$NAMESPACE
Pod=$POD
DesNode=$DESNODE
RootPath=$ROOTPATH
[ -z "$Pod" ] && echo "POD is empty" && exit 1
[ -z "$Namespace" ] && echo "NAMESPACE is empty" && exit 1
[ -z "$DesNode" ] && echo "DESNODE is empty" && exit 1
[ -z "$RootPath" ] && echo "ROOTPATH is empty" && exit 1

retry -f "echo 'get pod fail';exit 1" "kubectl get pod -n $Namespace $Pod -o json > pod.json"
PVCS=$(cat pod.json | tr '\r\n' ' '|   jq -r '[.spec.volumes[] | .persistentVolumeClaim.claimName ]| del( .[]| nulls) | .[]')
Mounts=$(cat pod.json | tr '\r\n' ' '| jq -r ".
| [(.spec.containers[]) | .volumeMounts[]]
")
echo "PVCS:$PVCS"
echo "Mounts:$Mounts"
for Pvc in "$PVCS"
do
	#TODO: COPY TAR to container
	retry -f "echo 'get pvc fail'; exit 1"  "kubectl get pvc -n $Namespace $Pvc -o json > old-${Pvc}-pvc.json"
	retry -f "echo 'get pv fail'; exit 1"   "kubectl get pv $Pv -o json > old-${Pvc}-pv.json"
	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	echo "Pvc:$Pvc"
	VolumName=$( cat pod.json | tr '\r\n' ' '|   jq -r ".
	| .spec.volumes[] 
	| select(.persistentVolumeClaim.claimName == \"$Pvc\") 
	| .name "
	)
	echo "VolumName:$VolumName"
	PodPath=$(echo $Mounts | jq -r ".[]
	| select(.name==\"$VolumName\" ) 
	| .mountPath")
	echo "PodPath:$PodPath"
	HOSTPATH=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	| (.spec.hostPath.path)
	")
	echo "ToPath:$RootPath/$HOSTPATH"
	mkdir -p $ROOTPATH/$HOSTPATH
	retry -f "echo 'cp is fail,Maybe tar not in container'; exit 2" "kubectl cp $Namespace/$Pod:$PodPath $ROOTPATH/$HOSTPATH"
done
