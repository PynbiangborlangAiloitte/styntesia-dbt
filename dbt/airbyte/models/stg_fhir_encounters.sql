{{ config(materialized='table') }}

{% set raw_relation = fhir_raw_relation() %}

with encounters as (
  select
    data ->> 'id' as encounter_id,
    regexp_replace(data -> 'subject' ->> 'reference', '^Patient/', '') as patient_id,
    lower(data -> 'class' ->> 'code') as class_code,
    data -> 'class' ->> 'display' as class_display,
    nullif(data -> 'period' ->> 'start', '')::timestamp as start_datetime,
    nullif(data -> 'period' ->> 'end', '')::timestamp as end_datetime
  from {{ raw_relation }}
  where data ->> 'resourceType' = 'Encounter'
)

select
  encounter_id,
  patient_id,
  class_code,
  case
    when class_code in ('imp', 'inpatient') then 'Inpatient'
    when class_code in ('out', 'ambulatory', 'outpatient') then 'Outpatient'
    when class_code in ('emergency') then 'Emergency'
    when class_code in ('virtual') then 'Virtual'
    else coalesce(class_display, 'Other')
  end as encounter_type,
  start_datetime,
  end_datetime,
  end_datetime - start_datetime as duration
from encounters
where patient_id is not null
  and start_datetime is not null
