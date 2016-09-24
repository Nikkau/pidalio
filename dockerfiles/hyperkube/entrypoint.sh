#!/usr/bin/env bash
until [[ "$(dig pidalio-apiserver.weave.local | grep -v ";.*" | grep pidalio-apiserver.weave.local | wc -l)" == "1" ]]
do
    echo "Waiting for master"
    sleep 10
done
MASTER_IP=$(dig pidalio-apiserver.weave.local | grep -v ";.*" | awk '{print $5}' | xargs)
if [[ "${MASTER}" == "true" ]]
then
  curl -s http://pidalio:3000/certs/server\?token\=${PIDALIO_TOKEN}\&ip=${MASTER_IP} > server.json
  cat server.json | jq -r .privateKey > /etc/kubernetes/ssl/server-key.pem
  cat server.json | jq -r .cert > /etc/kubernetes/ssl/server.pem
fi
if [[ "$2" != "apiserver" ]]
then
(
    sleep 30
    for i in {1..3}
    do
        while [[ "$(curl -s -m 10 -k --cert /etc/kubernetes/ssl/node.pem --key /etc/kubernetes/ssl/node-key.pem https://$MASTER_IP/healthz)" == "ok" ]]
        do
            sleep 10
        done
        echo "APIServer not healthy, try $i/3"
    done
    echo "APIServer not healthy, exiting"
    pkill hyperkube
) &
exec "$@"
else
exec "$@" --advertise-address=${MASTER_IP}
fi
