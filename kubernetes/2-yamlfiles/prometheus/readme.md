##### 2. 安装部署
- 2.1 环境清单
###### 系统环境
```
uname -a

kubectl get nodes -o wide

kubectl get pods --all-namespaces -o wide

showmount -e
```
###### 创建namespace
```
kubectl apply -f namespace.yml
```

