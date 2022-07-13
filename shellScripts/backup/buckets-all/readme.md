#### MinIO 数据从旧集群迁移到新集群
前提条件
1. 获取MinIO的集群访问地址，通常是http://minio.storage.svc.cluster.local:9000
2. 获取到鉴权信息，通常可以在 Rancher 、Helm 的 Values.yaml 或部署用到的 yaml 文件中查到。
3. 从 MinIO 官网地址 下载 mc —— 用于连接到 MinIO 集群的客户端。 
（https://dl.min.io/server/minio/release/linux-amd64/minio）下载地址

准备迁移
1. 添加集群访问地址，以从 A 集群迁往 B 集群举例
将 mc chmod 775 后复制到 /usr/bin 中用以加载 mc 命令，使用以下命令添加 A 集群访问信息：
```
mc config host add $hostName http://$clusterAddr "$accessKey" "$accessSecret"
```
执行同样的命令添加 B 集群访问信息，注意 $hostName 要更换为 clusterB。
- 很有可能需要为地址特别指明端口，否则会以 80 端口进行连接。
其中的 $hostName、 $clusterAddr、$accessKey、$accessSecret 请根据实际情况替换，这里暂定 $hostNmae 为 clusterA；

2. 获取集群信息
执行命令测试能否连通：
```
mc ls clusterA
```
如有文件或至少存在一个 Bucket，会在回显中列出；
执行命令获取集群数据大小：
```
mc du clusterA
```
如果有文件或存在至少一个 Bucket，会在最后一行打印当前集群所有文件总大小。

3. 对拷（镜像）
使用命令进行 Bucket 对拷：
```
mc mirror $SrcCluster/$srcBucket $DestCluster

mc mirror clusterA/bucketa clusterB
```
mc mirror 命令可以不指定 Dest 的 Bucket，如果 $DestCluster 不存在对应名称 Bucket，对拷过程中会自动创建。

-「实验性」： 若要实现不停机对拷，可以使用以下命令：
```
bash mc mirror -w $srcCluster/Bucket $destCluster
```
-w 参数可以让 mirror 命令持续监控某一目录。由于 mirror 只能对拷单 Bucket，如果使用 Shell 脚本进行 for 轮询实现集群对拷时，一旦 Bucket 过多，此命令可能会造成大量监控线程，增加负载。

mc 无法实现集群全量对拷，单条命令只能逐个 Bucket 进行操作。

4. 检查是否完全结束
使用命令检查是否有未完整传输的文件：
```
mc ls --incomplete $hostName
```
如果有未传输完全的文件，会在回显中列出。
如果有必要，可以删除某个桶中的残缺文件：
```
mc rm --incomplete $hostName/$bucket
```
##### 一些说明
1. 无需担心数据分片等问题，哪怕节点数量不对等。

因为是直接从集群入口访问并获取数据，并不是 “磁盘 to 磁盘” 的迁移方式，某个节点上的某块磁盘究竟存的是纠删码还是分片的数据都没有关系，因为从集群地址中读出来的数据是完整的数据，这就是为什么要求一定要能获取到集群地址的原因。

2. Bucket 在 MinIO 中应被视为 “挂载目录” (mount)，而不是 "磁盘目录" (mkdir)。

3. mc cp 命令需要在目标集群拥有同名 Bucket，mc mirror 不需要，同时 mc mirror 会自动保存目录的层级信息，mc cp 需要额外指定 --recursive 参数，请根据需要酌情选择。

4. mc mirror 的集群 to 集群、集群 to 本地用法并未在 官方文档 中列出，很可能属于 hack 用法，请注意可能存在的风险。

