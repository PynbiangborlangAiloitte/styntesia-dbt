{{ config(materialized='table') }}

{% set raw_relation = fhir_raw_relation() %}

with conditions as (
  select
    data ->> 'id' as condition_id,
    regexp_replace(data -> 'subject' ->> 'reference', '^Patient/', '') as patient_id,
    jsonb_array_elements(coalesce(data -> 'code' -> 'coding', '[]'::jsonb)) as coding,
    data -> 'onsetDateTime' as onset_datetime_raw,
    data -> 'clinicalStatus' -> 'coding' -> 0 ->> 'code' as clinical_status_code
  from {{ raw_relation }}
  where data ->> 'resourceType' = 'Condition'
),
mapped as (
  select
    condition_id,
    patient_id,
    coding ->> 'system' as code_system,
    coding ->> 'code' as code,
    coding ->> 'display' as condition_name,
    nullif(onset_datetime_raw #>> '{}', '')::timestamp as onset_datetime,
    lower(coalesce(clinical_status_code, 'active')) as clinical_status
  from conditions
)

select
  condition_id,
  patient_id,
  case
    when code_system ilike '%icd%' then code
    else null
  end as icd10_code,
  condition_name,
  clinical_status,
  onset_datetime
from mapped
where patient_id is not null
