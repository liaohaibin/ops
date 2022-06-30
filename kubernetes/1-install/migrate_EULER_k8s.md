##### 前置动作
```
yum clean all
yum makecache

yum -y install docker-engine
systemctl daemon-reload

systemctl restart docker
systemctl enable docker
systemctl status docker 

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i '/^SELINUX=/s/enforcing/disabled/' /etc/selinux/config

---
cat <<EOF > /etc/yum.repos.d/kubernetes.repo

[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enable=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
      http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum clean all
yum makecache

---
cat >> /etc/docker/daemon.json << EOF
{ 
  "insecure-registries":["10.1.21.215:5000"],
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn","https://registry.docker-cn.com","http://hub-mirror.c.163.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

journalctl -f -u kubelet
---
swapoff -a
cp -p /etc/fstab /etc/fstab.bak$(date '+%Y%m%d%H%M%S')

sed -i "s/\/dev\/mapper\/openeuler-swap/\#\/dev\/mapper\/openeuler-swap/g" /etc/fstab

sed -i "s/UUID=b32790fa-542c-4991-ab2c-88435384f3c9/\#UUID=b32790fa-542c-4991-ab2c-88435384f3c9/g" /etc/fstab

cat /etc/fstab

reboot
```
---
##### 将各个节点登记到/etc/hosts，每台主机都执行。（例子如下）
```
cat >> /etc/hosts << EOF
10.1.21.201  k8s-master01
10.1.21.202  k8s-master02
10.1.21.203  k8s-master03

10.1.21.204  k8s-nfs01
10.1.21.205  k8s-nfs02
10.1.21.206  k8s-nfs03

10.1.21.212  k8s-node-01
10.1.21.213  k8s-node-02
10.1.21.214  k8s-node-03
10.1.21.215  k8s-node-04

10.1.21.215  harbor.nti56.com
EOF
```
##### 安装kubernetes组件。根据需求选择版本。
```
yum install -y kubelet-1.20.15 kubeadm-1.20.15 kubectl-1.20.15 kubernetes-cni-0.8.7

systemctl enable kubelet

cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF

modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

kubeadm config images list

```
##### 从gcmirrors拉取镜像较快，拉取完打tag成k8s.gcr.io/开头的。
```
docker pull gcmirrors/kube-apiserver-amd64:v1.20.15
docker pull gcmirrors/kube-controller-manager-amd64:v1.20.15
docker pull gcmirrors/kube-scheduler-amd64:v1.20.15
docker pull gcmirrors/kube-proxy-amd64:v1.20.15
docker pull gcmirrors/pause-amd64:3.2
docker pull gcmirrors/etcd:3.4.13-0
docker pull coredns/coredns:1.7.0

docker tag gcmirrors/kube-apiserver-amd64:v1.20.15 k8s.gcr.io/kube-apiserver:v1.20.15
docker tag gcmirrors/kube-controller-manager-amd64:v1.20.15 k8s.gcr.io/kube-controller-manager:v1.20.15
docker tag gcmirrors/kube-scheduler-amd64:v1.20.15 k8s.gcr.io/kube-scheduler:v1.20.15
docker tag gcmirrors/kube-proxy-amd64:v1.20.15 k8s.gcr.io/kube-proxy:v1.20.15
docker tag gcmirrors/pause-amd64:3.2 k8s.gcr.io/pause:3.2
docker tag gcmirrors/etcd:3.4.13-0 k8s.gcr.io/etcd:3.4.13-0
docker tag coredns/coredns:1.7.0 k8s.gcr.io/coredns:1.7.0

docker images | grep k8s

docker rmi gcmirrors/kube-apiserver-amd64:v1.20.15
docker rmi gcmirrors/kube-controller-manager-amd64:v1.20.15
docker rmi gcmirrors/kube-scheduler-amd64:v1.20.15
docker rmi gcmirrors/kube-proxy-amd64:v1.20.15
docker rmi gcmirrors/pause-amd64:3.2
docker rmi gcmirrors/etcd-amd64:3.4.13-0
docker rmi gcmirrors/coredns:1.7.0
docker rmi gcmirrors/etcd:3.4.13-0

```
---
##### Master节点、初始化。同时安装keepalived，通过VIP来初始化，实现master节点的高可用。
```
systemctl daemon-reload
systemctl restart kubelet

yum -y install keepalived
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
  router_id master02
}

vrrp_instance VI_1 {
  state BACKUP 
  interface ens192
  virtual_router_id 48
  priority 100
  advert_int 1
  authentication {
     auth_type PASS
     auth_pass 3333
  }
  virtual_ipaddress {
     10.1.21.198
  }
}

EOF

systemctl start keepalived
systemctl status keepalived

```
##### 初始化时指定虚拟IP
```
kubeadm init --control-plane-endpoint "10.1.21.198:6443" --kubernetes-version v1.20.15 --pod-network-cidr=10.244.0.0/16
```

##### 过期token执行：
```
kubeadm token create --ttl 0 --print-join-command
```

##### 拉取calico镜像（master上apply yaml文件，其他节点拉取镜像同时打tag）
```
docker pull calico/cni:v3.14.2-amd64
docker pull calico/node:v3.14.2-amd64
docker pull calico/kube-controllers:v3.14.2-amd64
docker pull calico/pod2daemon-flexvol:v3.14.2-amd64

docker tag calico/cni:v3.14.2-amd64 calico/cni:v3.14.2
docker tag calico/node:v3.14.2-amd64 calico/node:v3.14.2
docker tag calico/kube-controllers:v3.14.2-amd64 calico/kube-controllers:v3.14.2
docker tag calico/pod2daemon-flexvol:v3.14.2-amd64 calico/pod2daemon-flexvol:v3.14.2

docker images | grep calico

docker rmi calico/cni:v3.14.2-amd64
docker rmi calico/node:v3.14.2-amd64
docker rmi calico/kube-controllers:v3.14.2-amd64
docker rmi calico/pod2daemon-flexvol:v3.14.2-amd64

wget https://docs.projectcalico.org/v3.14/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml --no-check-certificate

kubectl apply -f calico.yaml

kubectl get nodes
```
---
##### 其他master节点加入
```
ssh root@k8s-master02 mkdir -p /etc/kubernetes/pki/etcd
scp /etc/kubernetes/admin.conf root@k8s-master02:/etc/kubernetes
scp /etc/kubernetes/pki/{ca.*,sa.*,front-proxy-ca.*} root@k8s-master02:/etc/kubernetes/pki
scp /etc/kubernetes/pki/etcd/ca.* root@k8s-master02:/etc/kubernetes/pki/etcd

ssh root@k8s-master03 mkdir -p /etc/kubernetes/pki/etcd
scp /etc/kubernetes/admin.conf root@k8s-master03:/etc/kubernetes
scp /etc/kubernetes/pki/{ca.*,sa.*,front-proxy-ca.*} root@k8s-master03:/etc/kubernetes/pki
scp /etc/kubernetes/pki/etcd/ca.* root@k8s-master03:/etc/kubernetes/pki/etcd
```

##### Master初始化后的内容范本
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 10.1.21.198:6443 --token fdbqyk.4a3s4o953ci99wyr \
    --discovery-token-ca-cert-hash sha256:85cae9f5d776511d053fe2a701569cedd38e0b5b2a4707e645b5aa1f2e42ce3d \
    --control-plane 

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.1.21.198:6443 --token fdbqyk.4a3s4o953ci99wyr \
    --discovery-token-ca-cert-hash sha256:85cae9f5d776511d053fe2a701569cedd38e0b5b2a4707e645b5aa1f2e42ce3d
```