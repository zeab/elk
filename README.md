### Elk Setup Script

Run this script as is to set up a local ELK environment. 
Or split this script apart and replace with correct IP's to set up on different nodes.

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
