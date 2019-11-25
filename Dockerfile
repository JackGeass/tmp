FROM nicolaka/netshoot
WORKDIR /work
COPY ./tar /bin
COPY ./kubectl /bin
COPY ./retry /bin
COPY ./jq /bin
COPY ./migrations.sh /work
COPY ./copy.sh /work

#git
#COPY config /root/.kube/config
#COPY ./krew.tar.gz /work
#COPY ./krew.yaml /work
#COPY ./krew-linux_amd64 /work
