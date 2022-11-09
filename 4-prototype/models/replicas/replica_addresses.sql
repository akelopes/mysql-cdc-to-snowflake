{% if execute %}
{{ replica_factory(source('cdc', 'addresses')) }}
{% endif %}