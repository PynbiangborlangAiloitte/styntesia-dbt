{{ config(materialized='table') }}

with patient_kpis as (
  select * from {{ ref('patient_kpis') }}
),
observation_metrics as (
  select
    max(case when observation_type = 'BMI' then average_value end) as avg_bmi,
    max(case when observation_type = 'HbA1c' then average_value end) as avg_hba1c
  from {{ ref('observation_metrics') }}
),
encounter_metrics as (
  select * from {{ ref('encounter_metrics') }}
)

select
  pk.total_patients,
  pk.average_age,
  pk.female_count,
  pk.male_count,
  pk.other_count,
  om.avg_bmi,
  om.avg_hba1c,
  em.admission_rate,
  em.readmission_rate
from patient_kpis pk
cross join observation_metrics om
cross join encounter_metrics em
