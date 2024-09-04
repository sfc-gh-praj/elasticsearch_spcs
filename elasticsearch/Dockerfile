
# Use the official Elasticsearch image from Docker Hub
FROM docker.elastic.co/elasticsearch/elasticsearch:sha256-ef56a84e6c128a809a2236e00a7b777ac5fdcecf234ef0330b27198bcf97a1eb


# Expose  ports
EXPOSE 9200 9300

# Set env variables 
ENV discovery.type=single-node
ENV cluster.name=docker-cluster
ENV xpack.security.enabled=false
ENV xpack.security.enrollment.enabled=false

USER elasticsearch

# Start Elasticsearch
CMD ["bin/elasticsearch"]