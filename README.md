Use this script to set up a local copy of 

Elasticsearch:9200/9300
Kibana:5601
Logstash:5400 <- Beats; 8900 <- Http
Filebeat + Docker Prospector W/ Sub-Json Decoder + Dashboards
Metricbeat + Docker + Dashboards
Packetbet <- TODO

localhost:5601 <- Kibana with dashboards

//TODO get a trimmed down version of just docker and system and put them into a proper package
//TODO also need to start saving the custom dashboards i make and load them along with the rest of the files during the above dashboard load

//TODO Figure out how to get filebeats inside a docker conatiner... well more like figure out the correct way to mount the docker log's conatiner to the filebeats contatiner... when i tried i just was not having any lucky with it

Known Issues:
When its not a json body in the message field for logstash it throws errors but still seems log to everything anyways... so not really worrying about it right now I did see something about json.ignore.error for a setting or something somewhere but i have not looked into it more

Im keep metricbeats on the bare system
It feels weird to me to run it inside a docker contatiner but someone is welcome to convince me otherwise 