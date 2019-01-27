#!/bin/bash

###Script Settings
#Define the version to be used for all elastic products
ELKB_VERSION=${ELKB_VERSION:-6.5.4}
###Script Settings


###Readme
#Write the readme to the local file
readMe="$(cat <<EOF
Setting up basic Elasicsearch + Logstash + Kibana + Filebeat w/ Docker Json + Metricbeat + Packetbeat

The key points with this is that is mostly development and production ready for monitoring systems and the docker conatiner metrics as well
Just single line json your docker logs and this will be able to pick them up and read them and its already pointed to the local docker logs file so docker logs still works

You can also post an http call to the localhost:8900 endpoint wiht a json body and that will also get index

-Command Alias
elkb_start_all <- start all elkb services and run the docker images 
elkb_stop_all <- stop all elkb services and run the docker images
#TODO add some more here for easier starting and stopping

-Here is just some starter info
Elasticsearch:9200/9300
Kibana:5601
Logstash:5400 <- Beats; 8900 <- Http
Filebeat + Docker Prospector W/ Sub-Json Decoder + Dashboards
Metricbeat + Docker + Dashboards
Packetbet <- TODO

EOF
)"
echo "$readMe" > ~/elkb_readme
echo "Readme created locally"
###Readme


#Grabs the local external ip
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)
#Grabs the local external ip


###Elasticsearch
echo "Create docker data volume for es data"
docker volume create --name esdata
echo "Run Elasticsearch"
docker run --name=elasticsearch -d --restart unless-stopped --log-opt max-size=100m -p 9200:9200 -p 9300:9300 -e LOG_LEVEL=warn -e "discovery.type=single-node" -v esdata:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch:${ELKB_VERSION}
###Elasticsearch


###Kibana
echo "Run Kibana"
docker run --name=kibana -d --restart unless-stopped --log-opt max-size=100m -p 5601:5601 -e LOG_LEVEL=warn -e ELASTICSEARCH_URL=http://$IP:9200 docker.elastic.co/kibana/kibana:${ELKB_VERSION}
###Kibana


###Logstash
echo "Make logstash.conf"
logstashConf="$(cat <<EOF
input {
  beats {
    port => 5044
  }
  http {
    port => 8900
    type => http
    threads => 12
  }
}

filter{
  date{
    match => ["[json][logTimestamp]", "yyyy-MM-dd-HH.mm.ss.SSS"]
    target => "@timestamp"
    remove_field => [ "[json][logTimestamp]" ]
  }
}

output {
  if [type] == "http" {
    elasticsearch {
      hosts => ["$IP:9200"]
      index => "http-%{+YYYY.MM.dd}"
    }
  } else {
    elasticsearch {
      hosts => ["$IP:9200"]
      index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
    }
  }
}
EOF
)"
echo "$logstashConf" > /home/$USER/logstash.conf
#Run Logstash
echo "Run Logstash"
docker run --name=logstash -d --restart unless-stopped --log-opt max-size=100m -p 5044:5044 -p 8900:8900 -e LOG_LEVEL=warn -e XPACK.MONITORING.ELASTICSEARCH.URL=http://$IP:9200 -v /home/$USER/logstash.conf:/usr/share/logstash/pipeline/logstash.conf docker.elastic.co/logstash/logstash:${ELKB_VERSION}
###Logstash


###Filebeat###
echo "Configure Filebeat"
filebeatYml="$(cat <<EOF
filebeat.inputs:
- type: docker
  json.message_key: log
  json.ignore_decoding_error: true
  containers:
    path: "/var/lib/docker/containers"
    ids:
      - "*"
  processors:
  - add_docker_metadata: ~

output.logstash:
  hosts: ["$IP:5044"]
EOF
)"
echo "$filebeatYml" > /home/$USER/filebeat.yml
sudo chown root /home/$USER/filebeat.yml
sudo chmod go-w /home/$USER/filebeat.yml
echo "Run Filebeat"
docker run --name filebeat -d -u root --restart unless-stopped --log-opt max-size=100m --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" --volume="/var/run/docker.sock:/var/run/docker.sock:ro" -v /home/$USER/filebeat.yml:/usr/share/filebeat/filebeat.yml docker.elastic.co/beats/filebeat:${ELKB_VERSION}
###Filebeat###

echo "Complete"
