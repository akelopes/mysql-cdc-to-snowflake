# MYSQL to Snowflake replication using Debezium CDC with Snowflake's Kafka Connector and DBT

## Overview

This repository demonstrates on small scale how to replicate mysql databases to snowflake using Debezium connector to create a CDC stream to be consumed by Snowflake's Kafka connector to create CDC source tables in Snowflake. DBT is used to build the table replicas using incremental models that dynamically detect the columns and build the models using a couple of macros.

This could be scheduled to run on a regular basis using a scheduler or orchestration system to update the replicas and run tests on the models and sources.

## Requirements

* Docker
* dbt-snowflake
* Scripts were tested on linux, but should be able to run on mac-os.

## How to Run

1. Set up the environment by running `docker compose up -d` inside `0-services/` folder.
2. After the containers are up, execute `1-debezium/init_cdc.sh` to create the debezium connector.
3. Configure `2-snowflake/connect/snowflake-sink-connector.json` to connect to your Snowflake environment.
4. After the containers are up, execute `2-snowflake/init_sink.sh` to create the snowflake connector.
5. Wait for tables to be created on your Snowflake account as per configurations of the snowflake connector.
6. Once done, you can optionally run `3-database/init_db.sh` and `3-database/mysql_crud.sh` to create a new table and run some inserts and updates on the new table.
7. Update `4-prototype/models/schema.yml` sources identifiers to the correct source table in your Snowflake environment.
8. Change directory into `4-prototype` and execute `dbt run` to create a few models.
9. Play around making changes and creating models.

## Details

* Debezium is set to create topics for all tables + schema-changes on the source mysql
* Snowflake's Kafka Connector is using the `topics.regex` parameter to detect all topics that start with 'mysqldb.inventory' and create source tables from it on the `cdc` schema.

## Limitations

* DBT is not meant to be used in micr-batching scenarios, so the performance and possible issues at higher scale are unknown
* the DBT models are set up to rebuild the models dynamically, which limits the flexibility on data types and transformations, which are recommended to be treated on another layer on top of the replicas.
