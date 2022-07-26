CSRF_TOKEN=$(curl http://localhost:7750/pulsar-manager/csrf-token)

curl \
-H 'X-XSRF-TOKEN: $CSRF_TOKEN' \
-H 'Cookie: XSRF-TOKEN=$CSRF_TOKEN;' \
-H "Content-Type: application/json" \
-X PUT http://localhost:7750/pulsar-manager/users/superuser \
-d '{"name": "admin", "password": "apachepulsar", "description": "test", "email": "liaohaibin@nti56.com"}'




bin/pulsar-admin sinks create \
--archive ./conf/connectors/pulsar-io-jdbc-clickhouse-2.8.1.nar \
--inputs test3 \
--name test3-sink \
--sink-config-file ./conf/connectors/pulsar-clickhouse-jdbc-sink.yaml \
--parallelism 1

