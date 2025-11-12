{{ config(materialized='table') }}

with ranked as (
  select
    patient_id,
    observation_type,
    value,
    effective_datetime,
    row_number() over (partition by patient_id, observation_type order by effective_datetime desc nulls last) as rn
  from {{ ref('stg_fhir_observations') }}
  where observation_type in ('BMI', 'HbA1c')
)

select
  observation_type,
  avg(value)::numeric(10,2) as average_value,
  count(*) as measurement_count
from ranked
where rn = 1
group by observation_type
