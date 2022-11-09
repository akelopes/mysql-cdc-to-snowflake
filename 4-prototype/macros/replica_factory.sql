{# 
    This abstracts the query required to build a replica table from the CDC source
    table. 

    1. First it creates a CTE called prequery to read the metadata and content of the source table,
    creating a filter of only the load_timestamp later than the previous run (record_content:payload.ts_ms). 
    2. It then creates a CTE called ranked_query to partition the prequery by load_timestamp, 
    sourcedb_binlog_file and sourcedb_binlog_pos.    
    3. from the ranked_query, only the latest snapshot is selected and two CTEs 
    are built on top of it: one for existing id's that need to be updated, and 
    one for non existing id's that need to be inserted.
        3.a If the latest snapshot is a delete, then the column is_active will be
        updated to '0' and payload.before valeus will be used to keep the latest version 
        of the row.
#}
{% macro replica_factory(source_table) %}
WITH prequery AS (
    SELECT
        record_metadata :key.payload.id id,
        COALESCE(
            record_content :payload.source.gtid,
            ''
        ) AS sourcedb_binlog_gtid,
        COALESCE(
            record_content :payload.source.file,
            ''
        ) AS sourcedb_binlog_file,
        TO_NUMBER(
            record_content :payload.source.pos
        ) AS sourcedb_binlog_pos,
        record_content :payload AS payload,
        record_content :payload.op AS cdc_operation,
        record_content :payload.ts_ms AS load_timestamp
    FROM
        {{ source_table }}

{% if is_incremental() %}
WHERE
    record_content :payload.ts_ms > (
        SELECT
            MAX(load_timestamp)
        FROM
            {{ this }}
    )
{% endif %}
),
ranked_query AS (
    SELECT
        *,
        ROW_NUMBER() over (
            PARTITION BY id
            ORDER BY
                load_timestamp DESC,
                sourcedb_binlog_file DESC,
                sourcedb_binlog_pos DESC
        ) AS row_num
    FROM
        prequery
),
updates AS (
    SELECT
        {% if execute %}
            {% for item in get_columns(source_table) %}
                CASE
                    WHEN cdc_operation = 'd' THEN payload: before.{{ item }}
                    ELSE payload: after.{{ item }}
                END AS {{ item }},
            {% endfor %}
        {% endif %}

        CASE
            WHEN cdc_operation = 'd' THEN 0
            ELSE 1
        END AS is_active,
        load_timestamp
    FROM
        ranked_query
    WHERE
        row_num = 1

{% if is_incremental() %}
AND id IN (
    SELECT
        id
    FROM
        {{ this }}
)
{% endif %}
),
inserts AS (
    SELECT
        {% if execute %}
            {% for item in get_columns(source_table) %}
                payload: after.{{ item }} AS {{ item }},
            {% endfor %}
        {% endif %}

        CASE
            WHEN cdc_operation = 'd' THEN 0
            ELSE 1
        END AS is_active,
        load_timestamp
    FROM
        ranked_query
    WHERE
        row_num = 1
        AND cdc_operation <> 'd'
        AND id NOT IN (
            SELECT
                id
            FROM
                updates
        )
)
SELECT
    *
FROM
    updates
UNION
SELECT
    *
FROM
    inserts
{% endmacro %}