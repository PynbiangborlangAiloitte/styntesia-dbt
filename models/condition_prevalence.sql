{{ config(materialized='table') }}

with patient_counts as (
  select count(*) as total_patients
  from {{ ref('stg_fhir_patients') }}
),
active_conditions as (
  select
    patient_id,
    coalesce(icd10_code, code) as icd10_code,
    condition_name
  from {{ ref('stg_fhir_conditions') }}
  where coalesce(clinical_status, 'active') = 'active'
),
aggregated as (
  select
    icd10_code,
    max(condition_name) as condition_name,
    count(distinct patient_id) as patient_count
  from active_conditions
  where icd10_code is not null
  group by icd10_code
)

select
  icd10_code,
  condition_name,
  patient_count,
  (patient_count::numeric / nullif(pc.total_patients, 0)) * 100 as prevalence_percent
from aggregated
cross join patient_counts pc
order by patient_count desc
