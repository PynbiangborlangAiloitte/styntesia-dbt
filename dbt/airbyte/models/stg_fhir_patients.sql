{{ config(materialized='table') }}

{% set raw_relation = fhir_raw_relation() %}

with patients as (
  select
    data ->> 'id' as patient_id,
    nullif(data ->> 'birthDate', '')::date as birth_date,
    lower(nullif(data ->> 'gender', '')) as gender_raw,
    data -> 'address' -> 0 ->> 'state' as state,
    data -> 'address' -> 0 ->> 'city' as city,
    data -> 'address' -> 0 ->> 'postalCode' as postal_code
  from {{ raw_relation }}
  where data ->> 'resourceType' = 'Patient'
)

select
  patient_id,
  birth_date,
  case
    when gender_raw in ('male', 'female', 'other') then initcap(gender_raw)
    when gender_raw = 'unknown' then 'Unknown'
    else 'Unknown'
  end as gender,
  state,
  city,
  postal_code,
  case
    when birth_date is not null then floor(extract(year from age(current_date, birth_date)))
    else null
  end::integer as age
from patients
