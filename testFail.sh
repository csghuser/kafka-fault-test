#!/bin/bash

while true; do

  docker-compose up -d

  sleep 20

  docker exec -ti kafka-fault-test_app_2_1  /bin/bash -c \
  "
  unset KAFKA_OPTS
  unset JMX_PORT
  export KAFKA_OPTS=\"-Djava.security.auth.login.config=/etc/kafka/secrets/kafka_server.jaas \"

  for i in {1..2}
  do
     kafka-topics --bootstrap-server localhost:9094 --topic test\$i --create --replication-factor 3 --partitions 100 --command-config /etc/kafka/client.properties
  done
  "

  docker exec -ti kafka-fault-test_app_2_1  /bin/bash -c \
  "
  unset KAFKA_OPTS
  unset JMX_PORT
  export KAFKA_OPTS=\"-Djava.security.auth.login.config=/etc/kafka/secrets/kafka_server.jaas \"
  for x in {1..5}; do echo \$x; sleep 1; done| kafka-console-producer --broker-list localhost:9094 --topic test1 --producer.config /etc/kafka/client.properties && echo 'Produced 5 messages.'
  "


  docker kill kafka-fault-test_zookeeper_3_1 &
  sleep 5
  docker stop kafka-fault-test_app_3_1
  docker start kafka-fault-test_zookeeper_3_1
  docker start kafka-fault-test_app_3_1

  docker exec -ti kafka-fault-test_app_3_1  /bin/bash -c \
  "
  unset KAFKA_OPTS
  unset JMX_PORT
  export KAFKA_OPTS=\"-Djava.security.auth.login.config=/etc/kafka/secrets/kafka_server.jaas \"
  kafka-console-consumer --bootstrap-server localhost:9094 --topic test1 --consumer.config /etc/kafka/client.properties \
  --formatter kafka.tools.DefaultMessageFormatter  \
  --property print.value=true \
  --from-beginning \
  --max-messages 5
  "

  docker-compose down -v

done
