FROM confluentinc/cp-zookeeper:6.2.0

COPY run /etc/confluent/docker/run2

USER root
RUN chmod +x /etc/confluent/docker/run2
RUN chmod +x /etc/confluent/docker/launch

USER appuser

# Do not use exec
# pid 1 will not be replaced by zookeeper process
# result is zookeeper is shutdown uncleanly
CMD ["/etc/confluent/docker/run2"]
