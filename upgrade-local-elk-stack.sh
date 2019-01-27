#!/bin/bash

###Script Settings
#Define the version to be used for all elastic products
ELKB_VERSION=${ELKB_VERSION:-6.5.4}
###Script Settings


#Grabs the local external ip
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)
#Grabs the local external ip


###Stop everything
docker stop elasticsearch
docker stop kibana
docker stop logstash
docker stop filebeat
###Stop everything


###Remove Images
docker rmi elasticsearch logstash logstash filebeat
###Remove Images


###Elasticsearch
echo "Run Elasticsearch"
docker run --name=elasticsearch -d --restart unless-stopped --log-opt max-size=100m -p 9200:9200 -p 9300:9300 -e LOG_LEVEL=warn -e "discovery.type=single-node" -v esdata:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch:${ELKB_VERSION}
###Elasticsearch


###Kibana
echo "Run Kibana"
docker run --name=kibana -d --restart unless-stopped --log-opt max-size=100m -p 5601:5601 -e LOG_LEVEL=warn -e ELASTICSEARCH_URL=http://$IP:9200 docker.elastic.co/kibana/kibana:${ELKB_VERSION}
###Kibana


###Logstash
echo "Run Logstash"
docker run --name=logstash -d --restart unless-stopped --log-opt max-size=100m -p 5044:5044 -p 8900:8900 -e LOG_LEVEL=warn -e XPACK.MONITORING.ELASTICSEARCH.URL=http://$IP:9200 -v /home/$USER/logstash.conf:/usr/share/logstash/pipeline/logstash.conf docker.elastic.co/logstash/logstash:${ELKB_VERSION}
###Logstash


###Filebeat###
echo "Run filebeat"
docker run -d -u root --restart unless-stopped --log-opt max-size=100m --name filebeat --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" --volume="/var/run/docker.sock:/var/run/docker.sock:ro" -v /home/$USER/filebeat.yml:/usr/share/filebeat/filebeat.yml docker.elastic.co/beats/filebeat:${ELKB_VERSION}
###Filebeat###


echo "Upgrade complete"