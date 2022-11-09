# Snowflake table replication from Kafka Connector with DBT

## Overview

* All replica models are set by default:
  * Incremental
  * 'id' column as unique_key
  * 'merge' strategy
  * 'sync_all_columns' on schema changes
* A macro called `replica_factory` has been created to build the models, as they all follow the same query.
* Each model calls upon the replica_factory and uses as input the source table created by Snowflake's Kafka Connector

## Models Details

* Models are incrementally loaded by the load_timestamp, which is based of the cdc load time
* A merge strategy looks up id's that already exist to update, and id's that do not exist to insert to each table on `dbt run`
* cdc operations of type 'd' (delete) are treated as soft deletes and the row is updated to set 'is_active' column to 0
* Columns are dynamically acquired by running the `get_columns` macro, which reads from the cdc table and uses the payload keys as columns.
* Adding or removing columns to the source mysql table will have the same done to the replica tables

## TODO

* Create generic tests for the sources
* Create generic or single tests for the models
* Create script to monitor and create models based on cdc tables dynamically

## Limitations

* Data types are not interpreted dynamically from source tables.
