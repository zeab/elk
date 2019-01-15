### Elk Setup Script

    Run this script to set up a local ELK environment with filebeats for docker logs. 
    Or split this script apart and replace with correct IP's to set up on different nodes.
    
#### General Info
    Filebeats will get the logs from docker and publish them.
    Everything is running inside a docker container.
    Good example of how to do something without docker-compose when your just getting started.
    Used on ubuntu 16.04/18.04
    Filebeat is run as root to allow it to read the docker logs

#### File Locations:
  * filebeat.yml <- /home/$USER/filebeat.yml
  * logstash.conf <- /home/$USER/logstash.conf

#### Logstash: Docker logs:
  * Output logs's from docker container in single line json format
  * logTimestamp <- in the json body will override the given logstash time for your time
  * Filebeat is configured to get the logs and send them off too logstash

#### Logstash: Http
  * Fire POST Json body's into the logstash:8900 endpoint for http logging endpoint
  * Up the thread count in the logstash.config
  
#### Service and Port Mapping:
| Service                     | Port       
| --------------------------- |:----------:
| Elasticsearch               | 9200       
| Elasticsearch               | 9300       
| Logstash: Beats             | 5044       
| Logstash: Http              | 8900
| Kibana                      | 5061       
