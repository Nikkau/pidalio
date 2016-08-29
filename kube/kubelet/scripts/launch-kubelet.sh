#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=http://127.0.0.1:8080 \
    --register-schedulable=false \
    --register-node=true \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --node-ip=${NODE_IP} \
    --hostname-override=${NODE_NAME} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --cloud-provider=openstack \
    --cloud-config=/etc/kubernetes/cloud.conf \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
else
  PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
  MASTERS_URLS=$(curl -s ${PIDALIO_URL}/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls[] | tr '\n' ',')
  echo Masters: ${MASTERS_URLS}
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=${MASTERS_URLS} \
    --register-node=true \
    --node-labels=mode=SchedulingDisabled \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --node-ip=${NODE_IP} \
    --hostname-override=${NODE_NAME} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --cloud-provider=openstack \
    --cloud-config=/etc/kubernetes/cloud.conf \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
fi
