---
title: "快速实践 Flink SQL 流批一体"
slug: "quickstart-flink-sql-unified-batch-and-streaming"
date: 2025-09-22T10:47:19+08:00
author: "郭冬"
description: "使用 Docker、MySQL 和 Flink 快速实践最小化的实时数据采集与流批一体分析。"
categories: ["技能矩阵"]
tags: ["Flink","CDC"]
resources:
- name: "featured-image"
  src: "featured-image.png"

toc: true
lightgallery: true
---

使用 Docker、MySQL 和 Flink 快速实践最小化的实时数据采集与流批一体分析。

<!--more-->

---

本文演示如何使用 Docker、MySQL 和 Flink 快速实践最小化的实时数据采集与流批一体分析，具有以下特点：

- 整个过程无需 Java / Scala 代码，仅用 Flink SQL 完成
- Flink CDC 捕获 MySQL 数据变更
- Flink 流处理写入 Kafka + Paimon (湖仓存储引擎)
- Flink 批处理统计写入 CSV
- 配套可视化工具 Adminer (MySQL) 和 Kafdrop (Kafka)

适合运维开发与数据分析人员快速上手体验 Flink 从 `数据源 → CDC 捕获 → 流批分析 → 下游结果` 的全链路实践。

## 搭建服务

### 目录结构

```plain
.
├── flink
│   ├── conf
│   │   └── sql-client-defaults.yaml
│   └── lib
│       ├── flink-connector-jdbc-3.2.0-1.19.jar
│       ├── flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
│       ├── flink-sql-connector-kafka-3.2.0-1.19.jar
│       ├── flink-sql-connector-mysql-cdc-3.2.0.jar
│       ├── mysql-connector-j-8.4.0.jar
│       ├── paimon-flink-1.19-1.2.0.jar
│       └── paimon-format-1.2.0.jar
├── output
│   └── checkpoints
├── sql
│   ├── 01_kafka_cdc.sql
│   ├── 02_paimon_cdc.sql
│   ├── 03_topn_batch.sql
│   └── 04_paimon_read.sql
├── docker-compose.yml
└── mysql-init.sql
```

### 下载 JAR 包

```bash
mkdir flink-amd64
cd flink-amd64
mkdir -p output/checkpoints
```

```bash
mkdir -p flink/lib
cd flink/lib

wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.2.0-1.19/flink-connector-jdbc-3.2.0-1.19.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.2.0-1.19/flink-sql-connector-kafka-3.2.0-1.19.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-mysql-cdc/3.2.0/flink-sql-connector-mysql-cdc-3.2.0.jar
wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar
wget https://repo1.maven.org/maven2/org/apache/paimon/paimon-flink-1.19/1.2.0/paimon-flink-1.19-1.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/paimon/paimon-format/1.2.0/paimon-format-1.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
```

### 创建 docker-compose.yml

```bash
cd ../../
vim docker-compose.yml
```

```yaml
services:
  mysql:
    image: mysql:8.0
    platform: linux/amd64
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=rootpw
      - MYSQL_DATABASE=sales
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

  kafka:
    image: bitnami/kafka:3.7
    platform: linux/amd64
    ports:
      - "9092:9092"
    environment:
      - KAFKA_ENABLE_KRAFT=yes
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9093
      - KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true
      - ALLOW_PLAINTEXT_LISTENER=yes

  kafdrop:
    image: obsidiandynamics/kafdrop:4.2.0
    platform: linux/amd64
    ports:
      - "9000:9000"
    environment:
      - KAFKA_BROKERCONNECT=kafka:9092
    depends_on:
      - kafka

  adminer:
    image: adminer:5.4.0
    platform: linux/amd64
    ports:
      - "8080:8080"

  jobmanager:
    image: flink:1.19.1-scala_2.12-java11
    platform: linux/amd64
    command: jobmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
    ports:
      - "8081:8081"
    volumes:
      - ./flink/conf/sql-client-defaults.yaml:/opt/flink/conf/sql-client-defaults.yaml:ro
      - ./flink/lib/flink-sql-connector-mysql-cdc-3.2.0.jar:/opt/flink/lib/flink-sql-connector-mysql-cdc-3.2.0.jar:ro
      - ./flink/lib/flink-sql-connector-kafka-3.2.0-1.19.jar:/opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.19.jar:ro
      - ./flink/lib/flink-connector-jdbc-3.2.0-1.19.jar:/opt/flink/lib/flink-connector-jdbc-3.2.0-1.19.jar:ro
      - ./flink/lib/mysql-connector-j-8.4.0.jar:/opt/flink/lib/mysql-connector-j-8.4.0.jar:ro
      - ./flink/lib/paimon-flink-1.19-1.2.0.jar:/opt/flink/lib/paimon-flink-1.19-1.2.0.jar:ro
      - ./flink/lib/paimon-format-1.2.0.jar:/opt/flink/lib/paimon-format-1.2.0.jar:ro
      # self-contained and isolated set of Hadoop client libraries
      - ./flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar:/opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar:ro
      - ./sql:/opt/sql:ro
      - ./output:/opt/flink/output

  taskmanager:
    image: flink:1.19.1-scala_2.12-java11
    platform: linux/amd64
    command: taskmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
    depends_on:
      - jobmanager
    volumes:
      - ./flink/conf/sql-client-defaults.yaml:/opt/flink/conf/sql-client-defaults.yaml:ro
      - ./flink/lib/flink-sql-connector-mysql-cdc-3.2.0.jar:/opt/flink/lib/flink-sql-connector-mysql-cdc-3.2.0.jar:ro
      - ./flink/lib/flink-sql-connector-kafka-3.2.0-1.19.jar:/opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.19.jar:ro
      - ./flink/lib/flink-connector-jdbc-3.2.0-1.19.jar:/opt/flink/lib/flink-connector-jdbc-3.2.0-1.19.jar:ro
      - ./flink/lib/mysql-connector-j-8.4.0.jar:/opt/flink/lib/mysql-connector-j-8.4.0.jar:ro
      - ./flink/lib/paimon-flink-1.19-1.2.0.jar:/opt/flink/lib/paimon-flink-1.19-1.2.0.jar:ro
      - ./flink/lib/paimon-format-1.2.0.jar:/opt/flink/lib/paimon-format-1.2.0.jar:ro
      # self-contained and isolated set of Hadoop client libraries
      - ./flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar:/opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar:ro
      - ./sql:/opt/sql:ro
      - ./output:/opt/flink/output
```

### 创建 mysql-init.sql

```bash
vim mysql-init.sql
```

```sql
CREATE DATABASE IF NOT EXISTS sales;
USE sales;

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  region VARCHAR(10),
  amount DOUBLE,
  status VARCHAR(10),
  order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders VALUES
  (1001, 1, 'US', 20.5, 'NEW', NOW()),
  (1002, 2, 'EU', 35.2, 'NEW', NOW()),
  (1003, 3, 'CN', 66.6, 'NEW', NOW()),
  (1004, 4, 'UK', 38.9, 'NEW', NOW()),
  (1005, 5, 'AU', 25.3, 'NEW', NOW()),
  (1006, 6, 'JP', 33.8, 'NEW', NOW());

CREATE USER 'flink'@'%' IDENTIFIED BY 'flinkpw';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'flink'@'%';
FLUSH PRIVILEGES;
```

### 创建 Flink 配置文件

```bash
mkdir -p flink/conf
vim flink/conf/sql-client-defaults.yaml
```

```yaml
execution:
  type: streaming
  result-mode: table
  parallelism: 1

configuration:
  execution.checkpointing.interval: 5 s
  execution.checkpointing.mode: EXACTLY_ONCE
  execution.checkpointing.min-pause: 1 s
  execution.checkpointing.timeout: 5 min

  state.checkpoints.dir: file:///opt/flink/output/checkpoints

  restart-strategy: fixed-delay
  restart-strategy.fixed-delay.attempts: 10
  restart-strategy.fixed-delay.delay: 5 s

  table.exec.sink.not-null-enforcer: drop
  table.exec.sink.upsert-materialize: none
  table.exec.source.idle-timeout: 5 s

deployment:
  response-timeout: 10000
```

### 创建 01_kafka_cdc.sql

```bash
mkdir -p sql
vim sql/01_kafka_cdc.sql
```

```sql
-- 01_kafka_cdc.sql

CREATE TABLE orders_cdc (
  order_id INT,
  customer_id INT,
  region STRING,
  amount DOUBLE,
  status STRING,
  order_time TIMESTAMP(3),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc',
  'hostname' = 'mysql',
  'port' = '3306',
  'username' = 'flink',
  'password' = 'flinkpw',
  'database-name' = 'sales',
  'table-name' = 'orders',
  'server-id' = '985',
  'scan.startup.mode' = 'initial'
);

CREATE TABLE orders_kafka (
  order_id INT,
  customer_id INT,
  region STRING,
  amount DOUBLE,
  status STRING,
  order_time TIMESTAMP(3),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'orders_topic',
  'properties.bootstrap.servers' = 'kafka:9092',
  'key.format' = 'json',
  'value.format' = 'json'
);

INSERT INTO orders_kafka
SELECT * FROM orders_cdc;
```

### 创建 02_paimon_cdc.sql

```bash
vim sql/02_paimon_cdc.sql
```

```sql
-- 02_paimon_cdc.sql

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '5 s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'execution.checkpointing.min-pause' = '1 s';
SET 'execution.checkpointing.timeout' = '5 min';

CREATE TABLE orders_cdc (
  order_id INT,
  customer_id INT,
  region STRING,
  amount DOUBLE,
  status STRING,
  order_time TIMESTAMP(3),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc',
  'hostname' = 'mysql',
  'port' = '3306',
  'username' = 'flink',
  'password' = 'flinkpw',
  'database-name' = 'sales',
  'table-name' = 'orders',
  'server-id' = '996',
  'scan.startup.mode' = 'initial'
);

CREATE CATALOG paimon_catalog WITH (
  'type' = 'paimon',
  'warehouse' = 'file:///opt/flink/output/warehouse'
);

USE CATALOG paimon_catalog;
CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

CREATE TABLE IF NOT EXISTS orders_paimon (
  order_id INT,
  customer_id INT,
  region STRING,
  amount DOUBLE,
  status STRING,
  order_time TIMESTAMP(3),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'paimon',
  'changelog-producer' = 'input',
  'bucket' = '1'
);

USE CATALOG default_catalog;

INSERT INTO paimon_catalog.dwd.orders_paimon SELECT * FROM orders_cdc;
```

### 创建 03_topn_batch.sql

```bash
vim sql/03_topn_batch.sql
```

```sql
-- 03_topn_batch.sql

SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'TABLEAU';
SET 'table.dml-sync' = 'true';

CREATE TABLE orders_jdbc (
  order_id INT,
  customer_id INT,
  region STRING,
  amount DOUBLE,
  status STRING,
  order_time TIMESTAMP(3),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:mysql://mysql:3306/sales',
  'table-name' = 'orders',
  'username' = 'flink',
  'password' = 'flinkpw'
);

CREATE TABLE top_customers (
  customer_id INT,
  total_amount DOUBLE
) WITH (
  'connector' = 'filesystem',
  'path' = '/opt/flink/output/top_customers',
  'format' = 'csv'
);

INSERT OVERWRITE top_customers
SELECT customer_id,
       CAST(SUM(amount) AS DOUBLE) AS total_amount
FROM orders_jdbc
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 5;

SELECT * FROM top_customers;
```

### 创建 04_paimon_read.sql

```bash
vim sql/04_paimon_read.sql
```

```sql
-- 04_paimon_read.sql

SET 'sql-client.execution.result-mode' = 'TABLEAU';
SET 'execution.runtime-mode' = 'batch';
SET 'table.dml-sync' = 'true';

CREATE CATALOG paimon_catalog WITH (
  'type' = 'paimon',
  'warehouse' = 'file:///opt/flink/output/warehouse'
);

USE CATALOG paimon_catalog;
USE dwd;

SELECT COUNT(*) AS cnt FROM orders_paimon;
SELECT * FROM orders_paimon;
```

## 流批一体分析

### 运行 docker-compose

```bash
docker-compose pull
docker-compose up -d --scale taskmanager=4
```

```plain
[+] Running 7/7
 ✔ Network flink-amd64_default          Created
 ✔ Container flink-amd64-jobmanager-1   Started
 ✔ Container flink-amd64-kafka-1        Started
 ✔ Container flink-amd64-adminer-1      Started
 ✔ Container flink-amd64-mysql-1        Started
 ✔ Container flink-amd64-kafdrop-1      Started
 ✔ Container flink-amd64-taskmanager-1  Started
 ✔ Container flink-amd64-taskmanager-2  Started
 ✔ Container flink-amd64-taskmanager-3  Started
 ✔ Container flink-amd64-taskmanager-4  Started
```

```bash
docker-compose ps --format "table {{.Name}}\t{{.Service}}\t{{.Status}}"
```

```plain
NAME                        SERVICE       STATUS
flink-amd64-adminer-1       adminer       Up 3 minutes
flink-amd64-jobmanager-1    jobmanager    Up 3 minutes
flink-amd64-kafdrop-1       kafdrop       Up 3 minutes
flink-amd64-kafka-1         kafka         Up 3 minutes
flink-amd64-mysql-1         mysql         Up 3 minutes
flink-amd64-taskmanager-1   taskmanager   Up 3 minutes
flink-amd64-taskmanager-2   taskmanager   Up 3 minutes
flink-amd64-taskmanager-3   taskmanager   Up 3 minutes
flink-amd64-taskmanager-4   taskmanager   Up 3 minutes
```

### 运行 01_kafka_cdc.sql

```bash
docker-compose exec -T jobmanager /opt/flink/bin/sql-client.sh -f /opt/sql/01_kafka_cdc.sql
```

```plain
...

Flink SQL>
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: 7537135a66b3ead1213fcdbc334fa192

Flink SQL>
Shutting down the session...
done.
```

### 运行 02_paimon_cdc.sql

```bash
docker-compose exec -T jobmanager /opt/flink/bin/sql-client.sh -f /opt/sql/02_paimon_cdc.sql
```

```plain
...

Flink SQL>
[INFO] Execute statement succeed.

Flink SQL>
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: 852a7286763bdf109cdf36aa1b9c3627

Flink SQL>
Shutting down the session...
done.
```

### 验证 Streaming CDC

1. 插入新数据

    ```bash
    docker-compose exec -T mysql mysql -uroot -prootpw -e \
    "USE sales; INSERT INTO orders VALUES (3001, 31, 'US', 12.3, 'PAID', NOW());"
    ```

2. 检查 Flink jobs

    访问 `http://localhost:8081`

    查看 Flink running jobs

    {{< image src="flink_running_jobs.jpg" alt="flink_running_jobs" >}}

3. 检查 MySQL table

    访问 `http://localhost:8080`

    登录:

    ```yaml
    Server: mysql
    Username: root
    Password: rootpw
    Database: sales
    ```

    {{< image src="flink_mysql_adminer_login.jpg" alt="flink_mysql_adminer_login" width=600 >}}

    检查 table `sales.orders`

    {{< image src="flink_mysql_adminer_sales_orders.jpg" alt="flink_mysql_adminer_sales_orders" width=800 >}}

4. 检查 Kafka events

    访问 `http://localhost:9000`

    查看 topic `orders_topic`

    {{< image src="flink_kafdrop_cdc_orders_topic.jpg" alt="flink_kafdrop_cdc_orders_topic" width=1000 >}}

### 验证 Batch Job

```bash
docker-compose exec -T jobmanager /opt/flink/bin/sql-client.sh -f /opt/sql/03_topn_batch.sql
```

```plain
...

Flink SQL>
> INSERT OVERWRITE top_customers
> SELECT customer_id,
>        CAST(SUM(amount) AS DOUBLE)
[INFO] Complete execution of the SQL update statement.

Flink SQL>
+-------------+--------------+
| customer_id | total_amount |
+-------------+--------------+
|           3 |         66.6 |
|           4 |         38.9 |
|           2 |         35.2 |
|           6 |         33.8 |
|           5 |         25.3 |
+-------------+--------------+
5 rows in set (0.94 seconds)

Flink SQL>
Shutting down the session...
done.
```

### 验证 Paimon Table

```bash
docker-compose exec -T mysql mysql -uroot -prootpw -e "
INSERT INTO sales.orders
  (order_id, customer_id, region, amount, status, order_time)
VALUES
  (6001, 61, 'US',  18.5, 'NEW',  NOW()),
  (6002, 62, 'EU',  27.0, 'PAID', NOW()),
  (6003, 63, 'APAC',33.3, 'NEW',  NOW());
UPDATE sales.orders SET amount = amount + 5, status='PAID' WHERE order_id IN (6001, 6002);
DELETE FROM sales.orders WHERE order_id = 6003;
"
```

```bash
docker-compose exec -T jobmanager /opt/flink/bin/sql-client.sh -f /opt/sql/04_paimon_read.sql
```

```plain
...

Flink SQL>
[INFO] Execute statement succeed.

Flink SQL>
> SELECT COUNT(*)
+-----+
| cnt |
+-----+
|   9 |
+-----+
1 row in set (7.52 seconds)

Flink SQL>
+----------+-------------+--------+--------+--------+-------------------------+
| order_id | customer_id | region | amount | status |              order_time |
+----------+-------------+--------+--------+--------+-------------------------+
|     1001 |           1 |     US |   20.5 |    NEW | 2025-09-23 02:23:53.000 |
|     1002 |           2 |     EU |   35.2 |    NEW | 2025-09-23 02:23:53.000 |
|     1003 |           3 |     CN |   66.6 |    NEW | 2025-09-23 02:23:53.000 |
|     1004 |           4 |     UK |   38.9 |    NEW | 2025-09-23 02:23:53.000 |
|     1005 |           5 |     AU |   25.3 |    NEW | 2025-09-23 02:23:53.000 |
|     1006 |           6 |     JP |   33.8 |    NEW | 2025-09-23 02:23:53.000 |
|     3001 |          31 |     US |   12.3 |   PAID | 2025-09-23 02:27:03.000 |
|     6001 |          61 |     US |   23.5 |   PAID | 2025-09-23 02:30:49.000 |
|     6002 |          62 |     EU |   32.0 |   PAID | 2025-09-23 02:30:49.000 |
+----------+-------------+--------+--------+--------+-------------------------+
9 rows in set (0.92 seconds)

Flink SQL>
Shutting down the session...
done.
```

检查 Flink finished jobs

{{< image src="flink_finished_jobs.jpg" alt="flink_finished_jobs" >}}

查看 Output 产物

```bash
tree output
```

```plain
output
├── checkpoints
├── top_customers
│   └── part-b36f808b-b393-4359-bfb0-05eaf732ee2f-task-0-file-0
└── warehouse
    ├── default.db
    └── dwd.db
        └── orders_paimon
            ├── bucket-0
            │   ├── changelog-1e5892ad-7d3b-4dbb-8801-deb523e8bb9c-0.parquet
            │   ├── changelog-49f7184f-cbd9-4ecb-bc93-6479fe5dd88d-0.parquet
            │   ├── changelog-7a66b3ac-64bf-454a-8ca8-3185e281d5d0-0.parquet
            │   ├── data-1e5892ad-7d3b-4dbb-8801-deb523e8bb9c-1.parquet
            │   ├── data-49f7184f-cbd9-4ecb-bc93-6479fe5dd88d-1.parquet
            │   └── data-7a66b3ac-64bf-454a-8ca8-3185e281d5d0-1.parquet
            ├── manifest
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-0
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-1
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-2
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-3
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-4
            │   ├── manifest-18b7fa7b-7b72-48cf-93e9-3bc50d57dd3b-5
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-0
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-1
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-10
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-11
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-12
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-13
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-14
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-15
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-16
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-17
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-18
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-19
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-2
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-20
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-3
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-4
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-5
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-6
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-7
            │   ├── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-8
            │   └── manifest-list-770c3f24-9fbe-48b4-b29f-c3eabe5c8d35-9
            ├── schema
            │   └── schema-0
            └── snapshot
                ├── EARLIEST
                ├── LATEST
                ├── snapshot-1
                ├── snapshot-2
                ├── snapshot-3
                ├── snapshot-4
                ├── snapshot-5
                ├── snapshot-6
                ├── snapshot-7
                ├── snapshot-8
                └── snapshot-9
```
