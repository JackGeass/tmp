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
echo "PVCS:$PVCS"
for Pvc in "$PVCS"
do
	retry -f "echo 'get pvc fail'; exit 1"  "kubectl get pvc -n $Namespace $Pvc -o json > old-${Pvc}-pvc.json"
	echo "Pvc:$Pvc"
	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	retry -f "echo 'get pv fail'; exit 1"   "kubectl get pv $Pv -o json > old-${Pvc}-pv.json"
	HOSTPATH=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	| (.spec.hostPath.path)
	")
	echo "ToPath:$RootPath/$HOSTPATH"
	rm -fr $RootPath/$HOSTPATH
done
