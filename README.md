# Apache Kafka 2.8 fault test

Replicates issue seen when zookeeper leader is uncleanly stopped, followed by the stopping of a Kafka broker

Run ./testFail.sh

Will loop until failure occurs. You will then see the following in the console:

```
[2021-08-13 10:20:15,022] WARN [Consumer clientId=consumer-console-consumer-91781-1, groupId=console-consumer-91781] Error while fetching metadata with correlation id 2 : {test1=INVALID_REPLICATION_FACTOR} (org.apache.kafka.clients.NetworkClient)
[2021-08-13 10:20:15,119] WARN [Consumer clientId=consumer-console-consumer-91781-1, groupId=console-consumer-91781] Error while fetching metadata with correlation id 3 : {test1=INVALID_REPLICATION_FACTOR} (org.apache.kafka.clients.NetworkClient)
```

The cluster never appears to recover from this.

The logs of the broker which was restarted will show:

```
docker logs kafka-fault-test_app_3_1
[2021-08-13 10:32:09,109] INFO [Admin Manager on Broker 3]: Error processing create topic request CreatableTopic(name='test1', numPartitions=1, replicationFactor=1, assignments=[], configs=[]) (kafka.server.ZkAdminManager)
org.apache.kafka.common.errors.InvalidReplicationFactorException: Replication factor: 1 larger than available brokers: 0.
[2021-08-13 10:32:09,211] INFO [Admin Manager on Broker 3]: Error processing create topic request CreatableTopic(name='test1', numPartitions=1, replicationFactor=1, assignments=[], configs=[]) (kafka.server.ZkAdminManager)
org.apache.kafka.common.errors.InvalidReplicationFactorException: Replication factor: 1 larger than available brokers: 0.
```

You can then stop the loop from running:

(caution here, it will pickup any "docker exec" command running)

```
pid=$(ps -efl|grep "docker exec"| grep -v "grep" | awk '{ print $2}') && parent=$(ps -o ppid= -p $pid) && kill -9 $parent
```

We can then demonstrate that stopping the apparently failed broker, kafka-3, and bringing it backup does not fix the issue:

```
docker stop kafka-fault-test_app_3_1
docker start kafka-fault-test_app_3_1
docker logs kafka-fault-test_app_3_1 --follow
```

This will show:

```
[2021-08-13 10:40:24,784] INFO Kafka version: 6.2.0-ccs (org.apache.kafka.common.utils.AppInfoParser)
[2021-08-13 10:40:24,784] INFO Kafka commitId: 1a5755cf9401c84f (org.apache.kafka.common.utils.AppInfoParser)
[2021-08-13 10:40:24,784] INFO Kafka startTimeMs: 1628851224775 (org.apache.kafka.common.utils.AppInfoParser)
[2021-08-13 10:40:24,787] INFO [KafkaServer id=3] started (kafka.server.KafkaServer)
```

Nothing more is printed. When looking at the logs for kafka-0 or kafka-1 you will see:

```
[2021-08-13 10:41:37,154] WARN [ReplicaFetcher replicaId=2, leaderId=3, fetcherId=0] Received UNKNOWN_TOPIC_OR_PARTITION from the leader for partition test2-56. This error may be returned transiently when the partition is being created or deleted, but it is not expected to persist. (kafka.server.ReplicaFetcherThread)
```

The cluster does not appear to recover from this state, only by restarting the other nodes in the cluster one by one. Everything then appears fine.
