{% if execute %}
{{ replica_factory(source('cdc', 'geom')) }}
{% endif %}