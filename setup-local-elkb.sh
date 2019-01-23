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
docker run -d -u root --restart unless-stopped --log-opt max-size=100m --name filebeat --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" --volume="/var/run/docker.sock:/var/run/docker.sock:ro" -v /home/$USER/filebeat.yml:/usr/share/filebeat/filebeat.yml docker.elastic.co/beats/filebeat:${ELKB_VERSION}
###Filebeat###

##EVERYTHING BELOW THIS POINT HAS BEEN DEPRECATED ALTHOUGH STILL USEFUL!!## 

#Sleep and let everything above come up
# echo "***********************************************"
# echo "DANGER!! This does not actually check if things are up just presumes after 2 min they are"
# echo "***********************************************"
# echo "Sleeping 2 min to let eveything come up"
# sleep 1m
# echo "1 min left"
# sleep 1m
#Sleep and let everything above come up

###Metricbeat
# echo "Download and Install Metricbeat"
# wget -O /tmp/metricbeat.deb https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${ELKB_VERSION}-amd64.deb 
# sudo dpkg -i /tmp/metricbeat.deb
# echo "Configure Metricbeat"
# sudo sed -i 's,output.elasticsearch:,#output.elasticsearch:,g' /etc/metricbeat/metricbeat.yml
# sudo sed -i 's,hosts: \["localhost:9200"\],#hosts: \["localhost:9200"\],g' /etc/metricbeat/metricbeat.yml
# sudo sed -i 's,#output.logstash:,output.logstash:,g' /etc/metricbeat/metricbeat.yml
# sudo sed -i "s,#hosts: \[\"localhost:5044\"\],hosts: \[\"$IP:5044\"\],g" /etc/metricbeat/metricbeat.yml
# sudo sed -i 's,${path.config},/usr/share/metricbeat,g' /etc/metricbeat/metricbeat.yml
# echo "Enable Docker Module"
# sudo mv /usr/share/metricbeat/modules.d/docker.yml.disabled /usr/share/metricbeat/modules.d/docker.yml
# echo "Load the templates and dashboards"
# sudo metricbeat setup --template -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"$IP:9200\"]"
# sudo metricbeat setup --dashboards
# echo "Start Metricbeat Service"
# sudo service metricbeat start
###Metricbeat

###Filebeat
# echo "Download and Install Filebeat"
# wget -O /tmp/filebeat.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${ELKB_VERSION}-amd64.deb 
# sudo dpkg -i /tmp/filebeat.deb
# echo "Configure Filebeat"
# filebeatYml="$(cat <<EOF
# filebeat.inputs:
# - type: docker
#   json.message_key: message
#   combine_partial: true
#   containers:
#     path: "/var/lib/docker/containers"
#     ids:
#       - "*"
#   processors:
#   - add_docker_metadata: ~

# output.logstash:
#   hosts: ["$IP:5044"]
# EOF
# )"
# sudo bash -c "echo '$filebeatYml' > /etc/filebeat/filebeat.yml"
# echo "Load the templates and dashboards"
# sudo filebeat setup --template -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"$IP:9200\"]"
# sudo filebeat setup --dashboards
# echo "Start Filebeat Service"
# sudo service filebeat start
###Filebeat

###Packetbeat
###TODO
###Packetbeat

###Command Alias
#Start all elkb services and dockers
# echo 'alias elkb_start_all="docker start elasticsearch; docker start logstash; docker start kibana; sudo service filebeat start && echo filebeat; sudo service metricbeat start && echo metricbeat; echo elkb stack started"' | sudo tee --append /etc/bash.bashrc
#Stop all elkb services and dockers
# echo 'alias elkb_stop_all="docker stop elasticsearch; docker stop logstash; docker stop kibana; sudo service filebeat stop && echo filebeat; sudo service metricbeat stop && echo metricbeat; echo elkb stack stopped"' | sudo tee --append /etc/bash.bashrc
# exec bash
###Command Alias



# sudo systemctl start docker
# sudo systemctl enable docker
