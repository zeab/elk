### Elk Setup Script

    Run this script to set up a local ELK environment with filebeats for docker logs. 
    Or split this script apart and replace with correct IP's to set up on different nodes.
    
#### General Info
    Filebeats will get the logs from docker and publish them.
    Everything is running inside a docker container.
    Good example of how to do something without docker-compose when your just getting started.

#### Environments Variables:
| Service                     | Port       
| --------------------------- |:----------:
| Elasticsearch               | 9200       
| Elasticsearch               | 9300       
| Logstash: Beats             | 5044       
| Logstash: Http              | 8900
| Kibana                      | 5061       

#### Docker log grepping:
  * Output logs's from docker container in single line json format
  * logTimestamp <- in the json body will override the given logstash time for your time
  * Filebeat is configured to get the logs and send them off too logstash
