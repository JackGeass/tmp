#kubectl version
Namespace=$1
Pod=$2
DesNode=$3
Namespace=default
Pod=mai-0
DesNode=c32010s8
#PVCS=$(kubectl get pod -n $Namespace $Pod -o json | jq -r '[.spec.volumes[] | .persistentVolumeClaim.claimName ]| del( .[]| nulls) | .[]')
retry -f "exit 1" "kubectl get pod -n $Namespace $Pod -o json > pod.json"
PVCS=$(cat pod.json | tr '\r\n' ' '|   jq -r '[.spec.volumes[] | .persistentVolumeClaim.claimName ]| del( .[]| nulls) | .[]')
echo $PVCS
for Pvc in "${PVCS}"
do
	retry -f "exit 1" "kubectl get pvc -n $Namespace $Pvc -o json > old-$Pvc-pvc.json"
	Pv=$(cat old-$Pvc-pvc.json | tr '\r\n' ' '| jq -r '.spec.volumeName')
	retry -f "exit 1" "kubectl get pv $Pv -o json > old-$Pvc-pv.json"

	PvcOldPolicy=$(cat old-$Pvc-pv.json | tr '\r\n' ' '| jq -r ".
	| (.spec.persistentVolumeReclaimPolicy)
	")
	PvNewJson=$(cat old-$Pvc-pv.json | tr '\r\n' ' '| jq -r ".
	| del(.metadata.creationTimestamp ) 
	| del (.metadata.resourceVersion)
	| del (.metadata.selfLink) 
	| del(.metadata.uid)
	| del(.status)
	| (.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] |= \"$DesNode\" )
	")
	retry kubectl patch pv $Pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
	#| (.spec.persistentVolumeReclaimPolicy |= \"Retain\")
	#| del(.spec.claimRef.uid)
	PvcNewJson=$(cat old-$Pvc-pvc.json | tr '\r\n' ' '| jq -r ".
	| del(.metadata.creationTimestamp ) 
	| del(.status)
	| del (.metadata.selfLink) 
	| del(.metadata.uid)
	| del (.metadata.resourceVersion)
	#| (.metadata.annotations[\"volume.kubernetes.io/selected-node\"] |= \"$DesNode\")
	")
	echo $PvcNewJson > $Pvc-pvc.json
	echo $PvNewJson > $Pvc-pv.json
	retry -f "exit 2" "kubectl delete pvc $Pvc"
	retry -f "exit 2" "kubectl delete pv $Pv"
done
retry -f "exit 3" "kubectl delete pod $Pod"


for Pvc in "${PVCS}"
do 
	retry -f  "exit 3" "kubectl apply -f $Pvc-pvc.json"
	sleep 10
	PvcJson=$(kubectl get pvc -n $Namespace $Pvc -o json)
	PvcUID=$(echo "$PvcJson" | tr '\r\n' ' '| jq -r ".metadata.uid")
	cat $Pvc-pv.json | tr '\r\n' ' '| jq -r ".spec.claimRef.uid |= \"$PvcUID\"" > $pvc-pv.json
	retry -f "exit 3" "kubectl apply -f $PvC-pv.json"
done

