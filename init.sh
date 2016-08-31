#!/usr/bin/env bash
set -xe
# Create directories and download Kubernetes Components
mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests /etc/kubernetes/ssl /opt/bin
if [[ -x /opt/bin/kubelet ]]; then
    echo "Kubelet already installed"
else
    curl -o /opt/bin/kubelet http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubelet
    chmod +x /opt/bin/kubelet
fi
if [[ -x /opt/bin/kubectl ]]; then
    echo "Kubectl already installed"
else
    curl -o /opt/bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl
    chmod +x /opt/bin/kubectl
fi
if [[ -x /opt/bin/etcd2-bootstrapper ]]; then
    echo "Etcd2 Bootstrapper already installed"
else
    curl -o /opt/bin/etcd2-bootstrapper https://github.com/glerchundi/etcd2-bootstrapper/releases/download/v0.3.0/etcd2-bootstrapper-linux-amd64
    chmod +x /opt/bin/etcd2-bootstrapper
fi
source /etc/pidalio.env
# Configure ETCD
if cat /etc/etcd.env | grep ETCD_NAME; then exit 0; fi
ETCD_PEERS=""
for server in ${PEERS}
do
  ETCD_PEERS=${server}=${server},${ETCD_PEERS}
done
ETCD_PEERS=$(echo ${ETCD_PEERS}|sed -rn 's/^(.*),$/\1/p')
echo "EtcD peers: $ETCD_PEERS"
until etcd2-bootstrapper --me ${NODE_IP}=${NODE_IP} --members ${ETCD_PEERS} --out /etc/etcd.env
do
    echo "Trying to register Etcd node"
    sleep 10
done
cat <<EOF >> /etc/etcd.env
ETCD_ADVERTISE_CLIENT_URLS=http://${NODE_IP}:2379,http://${NODE_PUBLIC_IP}:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${NODE_IP}:2380,http://${NODE_PUBLIC_IP}:2380
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
EOF
