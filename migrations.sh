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
for Pvc in "${PVCS}"
do
	retry -f "echo 'get pvc fail'; exit 1"  "kubectl get pvc -n $Namespace $Pvc -o json > old-${Pvc}-pvc.json"
	retry -f "echo 'get pv  fail'; exit 1"  "kubectl get pv $Pv -o json > old-${Pvc}-pv.json"

	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	#PvcOldPolicy=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	#| (.spec.persistentVolumeReclaimPolicy)
	#")
	PvNewJson=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
	| del(.metadata.creationTimestamp ) 
	| del (.metadata.resourceVersion)
	| del (.metadata.selfLink) 
	| del(.metadata.uid)
	| del(.status)
	| (.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] |= \"$DesNode\" )
	")
	#retry -f  "kubectl patch pv $Pv -p '{\"spec\":{\"persistentVolumeReclaimPolicy\":\"Retain\"}}'"
	#| (.spec.persistentVolumeReclaimPolicy |= \"Retain\")
	#| del(.spec.claimRef.uid)
	PvcNewJson=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r ".
	| del(.metadata.creationTimestamp ) 
	| del(.status)
	| del (.metadata.selfLink) 
	| del(.metadata.uid)
	| del (.metadata.resourceVersion)
	#| (.metadata.annotations[\"volume.kubernetes.io/selected-node\"] |= \"$DesNode\")
	")
	echo $PvcNewJson > ${Pvc}-pvc.json
	echo $PvNewJson  > ${Pvc}-pv.json
done

for Pvc in "${PVCS}"
do
	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	retry -t 3 "timeout 3 kubectl delete -n $Namespace pvc $Pvc"
	retry -t 3 "timeout 3 kubectl delete pv $Pv"
done

retry -t 3 "timeout 3 kubectl delete -n $Namespace pod $Pod"

for Pvc in "${PVCS}"
do 
	retry -f  "echo 'apply pvc fail';exit 3" "kubectl apply -f $Pvc-pvc.json"
	sleep 5
	PvcJson=$(kubectl get pvc -n $Namespace $Pvc -o json)
	PvcUID=$(echo "$PvcJson" | tr '\r\n' ' '| jq -r ".metadata.uid")
	cat $Pvc-pv.json | tr '\r\n' ' '| jq -r ".spec.claimRef.uid |= \"$PvcUID\"" > $pvc-pv.json
	retry -f "echo 'apply pv fail';exit 3" "kubectl apply -f $PvC-pv.json"
done

#./remove.sh
## if exit 3 hold on call
