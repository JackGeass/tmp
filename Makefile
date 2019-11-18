t:
	curl -O https://raw.githubusercontent.com/kadwanev/retry/master/retry 
	chmod u+x retry
	wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
	mv jq-linux64 jq
	chmod u+x jq
all:
	docker build . -t onething/pod-migrate
run: all
	docker run -it --rm -e NAMESPACE=default -e POD=mai-0 -e DESNODE=c32010s7 onething/pod-migrate  #/work/migrations.sh
