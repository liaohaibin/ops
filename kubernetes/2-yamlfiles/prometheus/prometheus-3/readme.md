#### 直接造 ####

```
kubectl create namespace monitoring
```
##### 服务账户(prometheus-sa.yaml)、集群角色(prometheus-clusterRole.yaml)、服务账户与集群角色绑定，完成授权(prometheus-clusterRoleBinding.yaml)
```
kubectl apply -f 1-prometheus-sa.yaml
kubectl apply -f 2-prometheus-clusterRole.yaml
kubectl apply -f 3-prometheus-clusterRoleBinding.yaml
```


###### 创建prometheus需要用到的配置文件，以configmap形式挂载到pod内
```
kubectl create configmap prometheus-rules --from-file=rules -n monitoring
kubectl create configmap prometheus-config --from-file=prometheus.yml -n monitoring
```

###### 创建pod，如果需要将监控数据持久化存储，需要挂载pv，同时最好使用statefulset类型创建pod，我这边使用deployment创建，将数据远程写入influxdb中，statefuset类型pod创建可以参考canal-server搭建那篇文档，文末我会将地址列出


```
kubectl apply -f 5-prometheus-deployment.yaml
```

###### 创建svc
```
kubectl apply -f 6-prometheus-svc.yaml
```
