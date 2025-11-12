{{ config(materialized='table') }}

select
  patient_id,
  count(*) as total_observations,
  avg(value) as avg_value
from {{ ref('stg_fhir_observations') }}
group by patient_id
