clickhouse-client --stream_like_engine_allow_direct_select 1 -u default -h 10.1.21.38 --password nti56.com

默认目录：
    /var/lib/clickhouse
    /var/log/clickhouse-server

mv /var/lib/clickhouse /data/
mv /var/log/clickhouse-server /data/clickhouse/log/

ln -s /data/clickhouse /var/lib/clickhouse
ln -s /data/clickhouse/log/clickhouse-server /var/log/clickhouse-server

chown -Rc clickhouse:clickhouse /data/clickhouse
chown -Rc clickhouse:clickhouse /data/clickhouse/log/clickhouse-server
