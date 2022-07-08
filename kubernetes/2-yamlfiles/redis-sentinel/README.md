#### 一主二从三哨兵

- 镜像可自己制作上传到服务器私有仓库后，指定。


1. pv创建
    在nfs或者其他类型后端存储创建pv，首先创建共享目录
```
cat >> /etc/exports << EOF
/k8s/redis-sentinel/0 *(rw,sync,no_subtree_check,no_root_squash)
/k8s/redis-sentinel/0 *(rw,sync,no_subtree_check,no_root_squash)
/k8s/redis-sentinel/0 *(rw,sync,no_subtree_check,no_root_squash)
EOF
```

2. pv空间大小按需修改，指定的nfs访问地址和路径根据实际情况修改。
```
kubectl create -f 1-redis-sentinel-pv.yaml
```

3. 创建namespace，默认在public-service中创建Redis哨兵模式
```
kubectl create namespace public-service
或者
kubectl apply -f 2-public-service-ns.yaml
```

- 如果不使用public-service

4. 创建ConfigMap
    默认在public-service中
```
kubectl create -f 3-redis-sentinel-configmap.yaml
```

5. 