#!/bin/bash
Namespace=$NAMESPACE
Pod=$POD
DesNode=$DESNODE
#DesNode=c32010s7
RootPath=$ROOTPATH
SkipGet=$SKIPGET # NOTE: set to  non-zero for human to fix, reRun the script
[ -z "$Pod" ] && echo "POD is empty" && exit 1
[ -z "$Namespace" ] && echo "NAMESPACE is empty" && exit 1
[ -z "$DesNode" ] && echo "DESNODE is empty" && exit 1
[ -z "$RootPath" ] && echo "ROOTPATH is empty" && exit 1
[ -z "$SkipGet" ] && SkipGet=0

retry -f "echo 'get pod fail';exit 1" "kubectl get pod -n $Namespace $Pod -o json > pod.json"
PVCS=$(cat pod.json | tr '\r\n' ' '|   jq -r '[.spec.volumes[] | .persistentVolumeClaim.claimName ]| del( .[]| nulls) | .[]')
echo ["PVCS:$PVCS"]
if [ $SkipGet -eq 0 ];
then
    echo "Gen the json"
    for Pvc in "${PVCS}"
    do
    	retry -f "echo 'get pvc fail'; exit 1"  "kubectl get pvc -n $Namespace $Pvc -o json > old-${Pvc}-pvc.json"
	# TODO:check pv'type equal local storage
    	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
    	retry -f "echo 'get pv  fail'; exit 1"  "kubectl get pv $Pv -o json > old-${Pvc}-pv.json"
    	PvNewJson=$(cat old-${Pvc}-pv.json | tr '\r\n' ' '| jq -r ".
    	| del(.metadata.deletionTimestamp)
    	| del(.metadata.deletionGracePeriodSeconds)
    	| del(.metadata.creationTimestamp ) 
    	| del(.metadata.resourceVersion)
    	| del(.metadata.selfLink) 
    	| del(.metadata.uid)
    	| del(.status)
    	| (.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] |= \"$DesNode\" )
    	")
    	PvcNewJson=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r ".
    	| del(.metadata.deletionTimestamp)
    	| del(.metadata.deletionGracePeriodSeconds)
    	| del(.metadata.creationTimestamp ) 
    	| del(.status)
    	| del(.metadata.selfLink) 
    	| del(.metadata.uid)
    	| del(.metadata.resourceVersion)
    	#| (.metadata.annotations[\"volume.kubernetes.io/selected-node\"] |= \"$DesNode\")
    	")
	echo [${Pvc}]
    	echo $PvcNewJson > ${Pvc}-pvc.json
    	echo $PvNewJson  > ${Pvc}-pv.json
    done
fi

for Pvc in "${PVCS}"
do
	Pv=$(cat old-${Pvc}-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	#retry -t 3 "timeout 3 bash -c 'kubectl delete -n $Namespace pvc $Pvc 2>&1 | grep deleted'"
	retry -t 3 "timeout 3 kubectl delete -n $Namespace pvc $Pvc"
	is_deleted=$(kubectl get -n $Namespace pvc $Pvc -o json | jq -r ".metadata.deletionTimestamp")
	if [ -z "$is_deleted" ]; 
	then echo "delete pvc $Pvc not success"; exit 3 
	fi
	retry -t 3 "timeout 3 kubectl delete pv $Pv"
	is_deleted=''
	is_deleted=$(kubectl get pv $Pv -o json | jq -r ".metadata.deletionTimestamp")
	if [ -z "$is_deleted" ]; 
	then echo "delete pv $Pv not success"; exit 3 
	fi
done

retry -t 3 "timeout 3 kubectl delete -n $Namespace pod $Pod"


for Pvc in "${PVCS}"
do 
	retry -f  "echo 'apply pvc fail';exit 3" "kubectl apply -f $Pvc-pvc.json"
	sleep 5
	PvcJson=$(kubectl get pvc -n $Namespace $Pvc -o json)
	PvcUID=$(echo "$PvcJson" | tr '\r\n' ' '| jq -r ".metadata.uid")
	cat $Pvc-pv.json | tr '\r\n' ' '| jq -r ".spec.claimRef.uid |= \"$PvcUID\"" > ${Pvc}-pv-link.json
	retry -f "echo 'apply pv fail';exit 3" "kubectl apply -f ${Pvc}-pv-link.json"
done
exit 0
