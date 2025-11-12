{{ config(materialized='table') }}

with base as (
  select *
  from {{ ref('stg_fhir_patients') }}
)

select
  count(*) as total_patients,
  avg(age)::numeric(10,2) as average_age,
  count(*) filter (where gender = 'Female') as female_count,
  count(*) filter (where gender = 'Male') as male_count,
  count(*) filter (where gender not in ('Female', 'Male') or gender is null) as other_count
from base
