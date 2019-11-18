FROM nicolaka/netshoot
WORKDIR /work
COPY config /root/.kube/config
COPY ./kubectl /bin
COPY ./retry /bin
COPY ./jq /bin
COPY ./migrations.sh /work

