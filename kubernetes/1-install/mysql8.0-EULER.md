### 数据库安装（宿主机版）--- 欧拉操作系统
##### 1. 升级系统
```
yum -y update 
```
##### 2. 安装依赖和常用工具
```
yum -y install vim net-tools wget gcc make lrzsz
```

##### 3. 将MySQL Yum 存储库添加到系统的存储列表中
```
sudo yum -y install https://repo.mysql.com/mysql80-community-release-el8-4.noarch.rpm
```

##### 4. 通过运行以下命令并检查其输出来验证是否已启用和禁用正确的子存储库
```
sudo yum repolist enabled | grep mysql
```
##### 5. 通过以下命令安装MySQL
```
sudo yum -y install mysql-community-server
```
##### 6. 启动MySQL服务器,
- 使用以下命令启动MySQL服务器：
```
    sudo systemctl start mysqld
```
- 使用以下命令检查MySQL服务器的状态：
```
    sudo systemctl status mysqld
```
- 使用以下命令开启自启动MySQL服务器：
```
    sudo systemctl enabled mysqld
```
##### 7. 在服务器初始启动时，假设服务器的数目录为空，会发生以下情况：
    - 服务器已初始化。
    - SSL 证书和密钥文件在数据目录中生成。
    - validate_password 已安装并启用。
    - 创建了一个超级用户账户'root'@localhost.超级用户的密码设置并存储在错误日志文件中。要显示它，请使用以下命令：
    ```
        sudo grep 'temporary password' /var/log/mysqld.log
    ```
        通过使用生成的临时密码登录并为超级用户账户设置自定义密码，尽快更改root密码：
        ```
        mysql -uroot -p
        ```
- 修改密码：
```
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'Liaohb@123';
    FLUSH PRIVILEGES;
```
##### note:
        validate_password 默认安装。
        实现的默认密码策略validate_password要求密码至少包含1个大写字母、1个小写字母、1个数字和1个特殊字符，密码总长度至少为8个字符。
    
    validate_password检查语句中的明文密码。在要求密码长度至少为8个字符的默认密码策略下，密码很脆弱并且语句会产生错误：
    ```
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'Liaohb@123';
    ```
    - 不检查指定为散列值的密码，因为原始密码值不可用于检查：
    ```
        ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Liaohb@123';
        FLUSH PRIVILEGES;
    
        update mysql.user set host = '%', plugin='mysql_native_password' where user='root';
        FLUSH PRIVILEGES;

        exit;

    sudo systemctl restart mysqld
    ```

##### 根据需要创建 /data, /data/mysql, /data/logs
```
mkdir -p /data/mysql
mkdir -p /data/logs
chown -R /data/logs
chown -R /data/mysql
```
##### mysql配置文件/etc/my.cnf
```
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.0/en/server-configuration-defaults.html

[mysqld]
# --------------------------------------
# 自定义                               |

datadir=/data/mysql
socket=/data/mysql/mysql.sock

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid


# binlog日志文件存储路径。
log_bin=/data/logs/binlog
# binlog失效日期单位秒
binlog_expire_logs_seconds=1296000
# binlog模式（ROW行模式，Level默认，mixed自动模式）
binlog_format=ROW
# 为每个session分配的内存，在事务过程中用来存储二进制日志的缓存。
binlog_cache_size=4M


#server-id=1
#log-bin=mysql-bin
#relay-log=mysql-relay-bin
#replicate-wild-ignore-table=mysql.%
#replicate-wild-ignore-table=test.%
#replicate-wild-ignore-table=information_schema.%

# 大小写不敏感
lower_case_table_names=1

# 开启慢查询日志
slow_query_log=ON
# 定义慢查询时间，超过5秒的sql才会被记录到slow.log
long_query_time=5
# 慢查询存放路径
slow_query_log_file=/data/logs/slow.log

# 缓冲池字节大小，单位kb，如果不设置，默认为128M
innodb_buffer_pool_size=225G

# 该参数控制着二进制日志写入磁盘的过程：有效值为0、1、N
# 0: 默认值，事务提交后，将二进制日志从缓冲写入磁盘，但是不进行刷新操作（fsync()），此时只是写入了操作系统缓冲，若操作系统宕机则会丢失部分二进制日志。
# 1: 事务提交后，将二进制文件写入磁盘并立即执行刷新操作，相当于是同步写入磁盘，不经过操作系统的缓存。
# N: 每写N次操作系统缓冲就执行一次刷新操作。
# 将这个参数设为1以上的数值会提高数据库的性能，但同时会伴随数据丢失的风险。
# 二进制日志文件涉及到数据的恢复，以及想在主从之间获得最大的一致性，那么应该将该参数设置为1，但同时也会造成一定的性能损耗。
sync_binlog=100

# 它控制是否可以信任存储函数创建者，不会创建写入二进制日志引起不安全事件的存储函数。如果设置为0（默认值），用户不得创建或修改存储函数，除非它们具有除CREATE ROUTINE或ALTER ROUTINE特权之外的SUPER权限。 设置为0还强制使用DETERMINISTIC特性或READS SQL DATA或NO SQL特性声明函数的限制。 如果变量设置为1，MySQL不会对创建存储函数实施这些限制。 此变量也适用于触发器的创建
log_bin_trust_function_creators=1

# 阻止过多尝试失败的客户端以防止暴力破解密码
max_connect_errors=10000

# 部内存临时表的最大值
tmp_table_size=64M
# 指定索引缓冲区的大小，它决定索引处理的速度，尤其是索引读的速度。
key_buffer_size=256M


port=3306
max_connections=1500
max_allowed_packet=2000M
#table_cache=2048
# MySQL读入缓冲区大小
#read_buffer_size=2M
# 读取MyISAM表
#read_rnd_buffer_size=2M
#myisam_sort_buffer_size=64M
#thread_concurrency=16

#max_heap_table_size=500M


# 服务器关闭非交互连接之前等待活动的秒数。
#wait_timeout=28800
# 服务器关闭交互式连接前等待活动的秒数。
#interactive_timeout=28800
# 两者生效取决于：客户端是交互或者非交互的连接。
# 在交互模式下，interactive_timeout才生效，非交互模式下，wait_timeout生效。

# 控制了general log、error log、slow query log日志中时间戳的显示，默认使用的UTC
log_timestamps=system


sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'


#skip-name-reslove
#default-authentication-plugin=mysql_native_password
#max_allowd_packet = 500M
#net_read_timeout = 120
#net_write_timeout = 900


[client]
socket=/data/mysql/mysql.sock

```