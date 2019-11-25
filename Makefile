t:
	curl -O https://raw.githubusercontent.com/kadwanev/retry/master/retry 
	chmod u+x retry
	wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
	mv jq-linux64 jq
	chmod u+x jq
	cp $$(which tar) .
all:
	chmod u+x ./copy.sh
	chmod u+x ./migrations.sh
	chmod u+x ./remove.sh
	chmod u+x ./process.sh
	docker build . -t onething/pod-migration



run: all
	#docker run -it --rm -e NAMESPACE=default -e POD=mai-0 -e DESNODE=c32010s8 onething/pod-migrate  /work/migrations.sh
	docker run -it --rm -e NAMESPACE=default -e POD=mai-0 -e DESNODE=c32010s8 onething/pod-migrate  /bin/bash #/work/migrations.sh

del:
	kubectl delete -f job.yaml
test-pod: 
	docker build . -f Dockerfile.token -t onething/pod-test
test:
	-kubectl delete -f copy.yaml
	kubectl apply -f copy.yaml
	sleep 5
	#kubectl describe job migrate
	kubectl get pod
sa:
	kubectl apply -f sa.yaml
	kubectl delete -f testpod.yaml
	kubectl apply -f testpod.yaml
	kubectl exec -it volume-test /bin/ash
