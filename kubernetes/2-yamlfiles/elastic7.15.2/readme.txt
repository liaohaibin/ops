---
docker pull docker.elastic.co/eck/eck-operator:2.0.0
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.15.2
docker pull docker.elastic.co/beats/filebeat:7.15.2
docker pull docker.elastic.co/logstash/logstash:7.15.2
docker pull docker.elastic.co/kibana/kibana:7.15.2


docker tag docker.elastic.co/eck/eck-operator:2.0.0 192.168.110.44:5000/elastic/eck-operator:2.0.0
docker tag docker.elastic.co/elasticsearch/elasticsearch:7.15.2 192.168.110.44:5000/elastic/elasticsearch:7.15.2
docker tag docker.elastic.co/beats/filebeat:7.15.2 192.168.110.44:5000/elastic/filebeat:7.15.2
docker tag docker.elastic.co/logstash/logstash:7.15.2 192.168.110.44:5000/elastic/logstash:7.15.2 
docker tag docker.elastic.co/kibana/kibana:7.15.2 192.168.110.44:5000/elastic/kibana:7.15.2


docker save 192.168.110.44:5000/elastic/eck-operator:2.0.0 -o eck-operator.tar
docker save 192.168.110.44:5000/elastic/elasticsearch:7.15.2 -o elasticsearch.tar
docker save 192.168.110.44:5000/elastic/filebeat:7.15.2 -o filebeat.tar
docker save 192.168.110.44:5000/elastic/logstash:7.15.2 -o logstash.tar
docker save 192.168.110.44:5000/elastic/kibana:7.15.2 -o kibana.tar



 kubectl get secret -n elastic-system eck-cluster-es-elastic-user -o yaml | awk '/elastic:/ {print $2}' | base64 --decode
 kubectl get secret -n elastic-system elasticsearchex-es-elastic-user -o go-template='{{.data.elastic | base64decode }}'


 kubectl create secret generic kibanaex-elasticsearchex-credentials --from-literal=elasticsearch.password=q8m05HA7CQp5E093hCV56oCO -n elastic-system