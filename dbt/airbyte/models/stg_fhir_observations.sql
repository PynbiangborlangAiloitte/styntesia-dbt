{{ config(materialized='table') }}

{% set raw_relation = fhir_raw_relation() %}

with observations as (
  select
    data ->> 'id' as observation_id,
    regexp_replace(data -> 'subject' ->> 'reference', '^Patient/', '') as patient_id,
    data ->> 'effectiveDateTime' as effective_datetime_raw,
    data -> 'valueQuantity' ->> 'value' as value_raw,
    data -> 'valueQuantity' ->> 'unit' as unit,
    jsonb_array_elements(coalesce(data -> 'code' -> 'coding', '[]'::jsonb)) as coding
  from {{ raw_relation }}
  where data ->> 'resourceType' = 'Observation'
    and data ? 'valueQuantity'
),
mapped as (
  select
    observation_id,
    patient_id,
    coding ->> 'system' as code_system,
    coding ->> 'code' as code,
    coding ->> 'display' as code_display,
    value_raw::float as value,
    unit,
    nullif(effective_datetime_raw, '')::timestamp as effective_datetime,
    case
      when coding ->> 'code' in ('39156-5') then 'BMI'
      when coding ->> 'code' in ('4548-4') then 'HbA1c'
      when coding ->> 'code' in ('8480-6') then 'Systolic Blood Pressure'
      when coding ->> 'code' in ('8462-4') then 'Diastolic Blood Pressure'
      when coding ->> 'code' in ('2085-9') then 'HDL Cholesterol'
      when coding ->> 'code' in ('2089-1') then 'LDL Cholesterol'
      else coalesce(coding ->> 'display', 'Other')
    end as observation_type
  from observations
)

select
  observation_id,
  patient_id,
  observation_type,
  code_system,
  code,
  code_display,
  value,
  unit,
  effective_datetime
from mapped
where patient_id is not null
