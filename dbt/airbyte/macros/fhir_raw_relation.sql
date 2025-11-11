{% macro fhir_raw_relation() %}
  {#-
    Returns the fully-qualified relation for the raw FHIR JSON table produced by Airbyte.
    The schema defaults to the Airbyte destination namespace (`raw`), but can be overridden
    by setting the AIRBYTE_RAW_SCHEMA environment variable.
    The table defaults to `_airbyte_raw_module_<MODULE_ID>` unless AIRBYTE_RAW_TABLE is provided.
  -#}
  {% set schema = env_var('AIRBYTE_RAW_SCHEMA', env_var('AIRBYTE_DESTINATION_NAMESPACE', 'raw')) %}
  {% set table_override = env_var('AIRBYTE_RAW_TABLE') %}
  {% set module_id = env_var('MODULE_ID') %}

  {% if not table_override %}
    {% if not module_id %}
      {{ exceptions.raise_compiler_error("MODULE_ID environment variable must be set for dbt run") }}
    {% endif %}
    {% set table_override = '_airbyte_raw_module_' ~ module_id %}
  {% endif %}

  {{ adapter.quote(schema) }}.{{ adapter.quote(table_override) }}
{% endmacro %}
