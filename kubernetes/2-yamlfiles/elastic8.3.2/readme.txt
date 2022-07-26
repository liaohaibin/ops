docker pull docker.elastic.co/eck/eck-operator:2.3.0
docker pull docker.elastic.co/beats/filebeat:8.3.2
docker pull docker.elastic.co/logstash/logstash:8.3.2
docker pull docker.elastic.co/kibana/kibana:8.3.2
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.3.2

docker tag docker.elastic.co/eck/eck-operator:2.3.0 192.168.110.44:5000/elastic/eck-operator:2.3.0
docker tag docker.elastic.co/beats/filebeat:8.3.2 192.168.110.44:5000/elastic/filebeat:8.3.2
docker tag docker.elastic.co/logstash/logstash:8.3.2 192.168.110.44:5000/elastic/logstash:8.3.2 
docker tag docker.elastic.co/kibana/kibana:8.3.2 192.168.110.44:5000/elastic/kibana:8.3.2
docker tag docker.elastic.co/elasticsearch/elasticsearch:8.3.2 192.168.110.44:5000/elastic/elasticsearch:8.3.2


docker save 192.168.110.44:5000/elastic/eck-operator:2.3.0 -o eck-operator.tar
docker save 192.168.110.44:5000/elastic/filebeat:8.3.2 -o filebeat.tar
docker save 192.168.110.44:5000/elastic/logstash:8.3.2 -o logstash.tar
docker save 192.168.110.44:5000/elastic/kibana:8.3.2 -o kibana.tar
docker save 192.168.110.44:5000/elastic/elasticsearch:8.3.2 -o elasticsearch.tar



kubectl get secret -n elastic-system eck-cluster-es-elastic-user -o yaml | awk '/elastic:/ {print $2}' | base64 --decode
kubectl get secret -n elastic-system eck-cluster-es-elastic-user -o go-template='{{.data.elastic | base64decode }}'

kubectl get secret -n elastic-system eck-cluster-es-elastic-user -o go-template='{{.data.kibana | base64decode }}'


curl -XGET -u"elastic:3M8DI81n735RMkNf69iwOC6I" http://192.168.110.30:9200

curl -XPOST -u"elastic:3M8DI81n735RMkNf69iwOC6I" http://192.168.110.30:9200/_security/user/elastic/_password -H 'Content-Type: application/json' -d '{"password" : "nti56@com"}'

PASSWORD=$(kubectl get secret eck-cluster-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' -n elastic-system)
curl -u "elastic:$PASSWORD" -k "http://192.168.110.30:9200"


docker run -d --name kibana -p 5601:5601 -v /data/es/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml -v /data/es/kibana/plugins:/usr/share/kibana/plugins:rw 192.168.110.44:5000/elastic/kibana:8.3.2

docker run -d --name kibana -p 5601:5601 -v /data/es/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml 192.168.110.44:5000/elastic/kibana:8.3.2
docker run -d --name kibana2 -p 5602:5601 -v /data/es/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml 192.168.110.44:5000/elastic/kibana:7.15.2

docker run -d --name kibana2 -p 5602:5601 192.168.110.44:5000/elastic/kibana:7.15.2

docker run -d --name kibana -p 5601:5601 -v /data/es/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml -v /data/es/kibana/plugins:/usr/share/kibana/plugins:rw -e ELASTICSEARCH_HOSTS: http://192.168.110.30:9201 192.168.110.44:5000/elastic/kibana:7.15.2


/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
