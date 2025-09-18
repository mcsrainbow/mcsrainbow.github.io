---
title: "Quickstart Debezium MySQL to Kafka CDC in Minutes"
slug: "quickstart-debezium-mysql-to-kafka-cdc-in-minutes"
date: 2025-09-18T16:55:00+08:00
author: "Damon"
description: "Set up a minimal Debezium MySQL-to-Kafka CDC stack using Docker, KRaft, and Kafdrop."
categories: ["Skills"]
tags: ["CDC"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: false
lightgallery: true
---

Set up a minimal Debezium MySQL-to-Kafka CDC (Change Data Capture) stack using Docker, KRaft, and Kafdrop.

<!--more-->

---

1. Create docker-compose files
   
    ```bash
    mkdir debezium-amd64
    cd debezium-amd64
    ```

    ```bash
    vim docker-compose.yml
    ```

    ```yaml
    services:
      kafka:
        image: bitnami/kafka:3.7
        platform: linux/amd64
        ports:
          - "9092:9092"
        environment:
          # enable KRaft (no Zookeeper)
          - KAFKA_ENABLE_KRAFT=yes
          - KAFKA_CFG_NODE_ID=1
          - KAFKA_CFG_PROCESS_ROLES=broker,controller
          - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
          - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
          - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
          - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9093
          - KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true
          - ALLOW_PLAINTEXT_LISTENER=yes

      connect:
        image: quay.io/debezium/connect:3.2
        platform: linux/amd64
        ports:
          - "8083:8083"
        environment:
          - BOOTSTRAP_SERVERS=kafka:9092
          - GROUP_ID=1
          - CONFIG_STORAGE_TOPIC=connect_configs
          - OFFSET_STORAGE_TOPIC=connect_offsets
          - STATUS_STORAGE_TOPIC=connect_statuses
          - KEY_CONVERTER=org.apache.kafka.connect.json.JsonConverter
          - VALUE_CONVERTER=org.apache.kafka.connect.json.JsonConverter
          - KEY_CONVERTER_SCHEMAS_ENABLE=false
          - VALUE_CONVERTER_SCHEMAS_ENABLE=false
        depends_on:
          - kafka

      kafdrop:
        image: obsidiandynamics/kafdrop:latest
        platform: linux/amd64
        ports:
          - "9000:9000"
        environment:
          - KAFKA_BROKERCONNECT=kafka:9092
        depends_on:
          - kafka

      mysql:
        image: mysql:8.0
        platform: linux/amd64
        ports:
          - "3306:3306"
        environment:
          - MYSQL_ROOT_PASSWORD=debezium
          - MYSQL_USER=debezium
          - MYSQL_PASSWORD=dbz
          - MYSQL_DATABASE=inventory
        command: >
          --server-id=857
          --log-bin=binlog
          --binlog_format=ROW
          --binlog_row_image=FULL
          --gtid_mode=ON
          --enforce-gtid-consistency=ON
          --binlog_expire_logs_seconds=600
        volumes:
          - ./mysql-init.sql:/docker-entrypoint-initdb.d/mysql-init.sql
    ```

    ```bash
    vim mysql-init.sql
    ```

    ```sql
    -- ensure the database exists and is selected
    CREATE DATABASE IF NOT EXISTS inventory;
    USE inventory;

    -- minimal demo table (keep it simple for CDC)
    CREATE TABLE IF NOT EXISTS customers (
      id INT PRIMARY KEY AUTO_INCREMENT,
      first_name VARCHAR(50),
      last_name  VARCHAR(50),
      email      VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- seed data for snapshot
    INSERT INTO customers (first_name, last_name, email) VALUES
    ('Alice', 'Smith', 'alice@example.com'),
    ('Bob',   'Johnson', 'bob@example.com');
    ```

    ```bash
    vim register-mysql.json
    ```

    ```json
    {
      "name": "mysql-inventory-connector",
      "config": {
        "connector.class": "io.debezium.connector.mysql.MySqlConnector",
        "tasks.max": "1",

        "database.hostname": "mysql",
        "database.port": "3306",
        "database.user": "debezium",
        "database.password": "dbz",

        "database.server.id": "857",

        "topic.prefix": "mysql_server",
        "database.include.list": "inventory",
        "table.include.list": "inventory.customers",

        "snapshot.mode": "initial",
        "snapshot.locking.mode": "none",
        "include.schema.changes": "false",
        "tombstones.on.delete": "false",

        "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
        "schema.history.internal.kafka.topic": "schema-changes.inventory"
      }
    }
    ```

    ```bash
    ls -1
    ```

    ```plain
    docker-compose.yml
    mysql-init.sql
    register-mysql.json
    ```

2. Start services

    ```bash
    docker-compose up -d
    ```

    ```plain
    [+] Running 5/5
    ✔ Network debezium-amd64_default      Created
    ✔ Container debezium-amd64-mysql-1    Started
    ✔ Container debezium-amd64-kafka-1    Started
    ✔ Container debezium-amd64-kafdrop-1  Started
    ✔ Container debezium-amd64-connect-1  Started
    ```

3. Grant MySQL access to Debezium connector

    ```bash
    docker-compose exec -T mysql mysql -uroot -pdebezium -e "
    GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
    FLUSH PRIVILEGES;"
    ```

4. Register Debezium connector

    ```bash
    curl -s -X POST http://localhost:8083/connectors \
      -H "Content-Type: application/json" \
      -d @register-mysql.json
    ```

5. Update Debezium connector config (optional)

    ```bash
    jq '.config' register-mysql.json | \
    curl -s -X PUT http://localhost:8083/connectors/mysql-inventory-connector/config \
      -H "Content-Type: application/json" \
      -d @- | jq .
    ```

6. Check Debezium connector status

    ```bash
    curl -s localhost:8083/connectors/mysql-inventory-connector/status | jq .
    ```

    ```json
    {
      "name": "mysql-inventory-connector",
      "connector": {
        "state": "RUNNING",
        "worker_id": "192.168.107.5:8083"
      },
      "tasks": [
        {
          "id": 0,
          "state": "RUNNING",
          "worker_id": "192.168.107.5:8083"
        }
      ],
      "type": "source"
    }
    ```

7. Trigger CDC events

    `INSERT` / `UPDATE` / `DELETE` some rows to see `c` / `u` / `d` events

    ```bash
    docker-compose exec -T mysql mysql -udebezium -pdbz -e "USE inventory;
    INSERT INTO customers (first_name,last_name,email) VALUES ('Charlie','Wang','charlie@example.com');
    UPDATE customers SET email='alice_new@example.com' WHERE first_name='Alice';
    DELETE FROM customers WHERE first_name='Bob';"
    ```

8. Check the topic on Kafdrop

    Visit `http://localhost:9000`

    Check the topic `mysql_server.inventory.customers`

    See new events `"op":"c"` / `"op":"u"` / `"op":"d"`

    ![kafdrop_topic_msg_c_u_d](kafdrop_topic_msg_c_u_d.png)