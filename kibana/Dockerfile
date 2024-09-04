FROM docker.elastic.co/kibana/kibana:8.9.0

# Set environment variables
ENV ELASTICSEARCH_HOSTS=http://elasticsearcg-svc:9200
ENV cluster.name=docker-cluster
ENV XPACK_SECURITY_ENABLED=false
ENV xpack.security.enrollment.enabled=false

# Expose the default Kibana port
EXPOSE 5601

# Add any custom configuration if needed
# COPY kibana.yml /usr/share/kibana/config/kibana.yml

# Run Kibana
CMD ["kibana"]