{#
    This macro will run the function object_keys from Snowflake in order to 
    collect the keys from payload.after of the latest entry in the source cdc
    table that is not of type 'd' (delete). It then processes the result with
    fromjson function from Snowflake to transform the query result into a list.

    Output: list of column names from original table

    Documentation:
    https://docs.snowflake.com/en/sql-reference/functions/object_keys.html
    https://docs.getdbt.com/reference/dbt-jinja-functions/fromjson

#}
{% macro get_columns(table_name) %}
{% set columns_query %}
SELECT
    object_keys(MAX(record_content: payload.after))
FROM
    {{ table_name }}
WHERE
    record_content: payload.op <> 'd';
{% endset %}

{% set query_result = run_query(columns_query) %}
{% set columns_collected = query_result.columns[0].values() %}

{{ return(fromjson(columns_collected[0])) }}

{% endmacro %}