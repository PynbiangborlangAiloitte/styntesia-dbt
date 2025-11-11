{{ config(materialized='table') }}

with patient_counts as (
  select count(*) as total_patients
  from {{ ref('stg_fhir_patients') }}
),
inpatient_encounters as (
  select
    encounter_id,
    patient_id,
    start_datetime,
    end_datetime,
    lag(end_datetime) over (partition by patient_id order by start_datetime) as previous_end_datetime
  from {{ ref('stg_fhir_encounters') }}
  where encounter_type = 'Inpatient'
),
readmissions as (
  select
    encounter_id,
    patient_id
  from inpatient_encounters
  where previous_end_datetime is not null
    and start_datetime <= previous_end_datetime + interval '30 day'
),
encounter_flags as (
  select
    e.patient_id,
    e.encounter_id,
    e.encounter_type,
    case
      when r.encounter_id is not null then true
      else false
    end as is_readmission
  from {{ ref('stg_fhir_encounters') }} e
  left join readmissions r on e.encounter_id = r.encounter_id
),
aggregated as (
  select
    (count(distinct case when encounter_type = 'Inpatient' then patient_id end)::numeric / nullif(pc.total_patients, 0)) * 100 as admission_rate,
    (count(distinct case when is_readmission then patient_id end)::numeric / nullif(pc.total_patients, 0)) * 100 as readmission_rate
  from encounter_flags
  cross join patient_counts pc
)

select
  coalesce(admission_rate, 0)::numeric(10,2) as admission_rate,
  coalesce(readmission_rate, 0)::numeric(10,2) as readmission_rate
from aggregated
