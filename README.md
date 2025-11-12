# Airbyte FHIR Analytics (dbt)

This directory contains the dbt project that the backend provisions for every analytics run. Push the contents of `dbt/airbyte` to a Git repository that your Airbyte worker can access (HTTPS or SSH). The backend clones this repository on demand, executes the models inside a Dockerised dbt runtime, and materialises the results into the analytics schema used by the application.

## Project Layout

- `dbt_project.yml` – core dbt configuration.
- `models/` – staging (`stg_fhir_*`) and analytics marts (e.g. `dashboard_metrics`).
- `macros/` – helpers for resolving the Airbyte raw table at runtime.
- `profiles/` – optional custom profiles directory. You can delete this folder if you rely on env vars only.

## Publishing to GitHub

1. Create a new repository, for example `github.com/<org>/airbyte-fhir-dbt`.
2. Copy the contents of this directory into the repo root.
3. Commit and push:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Airbyte dbt project"
   git remote add origin git@github.com:<org>/airbyte-fhir-dbt.git
   git push -u origin main
   ```
4. If the repository is private, generate a deploy token or configure SSH keys for the machine running the backend/worker.

## Backend Environment Variables

Configure the following variables (in `apps/backend/.env`) so the queue worker can clone and run the project:

- `AIRBYTE_DBT_REPO_URL=https://github.com/<org>/airbyte-fhir-dbt.git`
- `AIRBYTE_DBT_REPO_BRANCH=main`
- `AIRBYTE_DBT_MODELS_PATH=` (leave blank because `dbt_project.yml` is at repo root)
- `AIRBYTE_DBT_DOCKER_IMAGE=fishanalytics/dbt:1.0.0`
- `AIRBYTE_DBT_PROFILES_DIR=` (optional, set if you commit a custom `profiles/` directory)
- `AIRBYTE_DBT_ENV={"DBT_USER":"postgres","DBT_PASSWORD":"password"}` (example – adjust for your database)

The backend automatically injects:

- `WORKSPACE_ID` / `MODULE_ID` – used by macros to isolate data per tenant.
- `AIRBYTE_RAW_SCHEMA` / `AIRBYTE_RAW_TABLE` – pointers to the raw Airbyte tables (e.g. `_airbyte_raw_module_<MODULE_ID>`).

## Running Locally

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -e DBT_DATABASE_URL=postgresql://postgres:password@host.docker.internal:5432/synthea_db \
  -e WORKSPACE_ID=<workspace-uuid> \
  -e MODULE_ID=<module-uuid> \
  -e AIRBYTE_DESTINATION_NAMESPACE=raw \
  fishanalytics/dbt:1.0.0 \
  dbt run --project-dir /workspace --profiles-dir /workspace/profiles
```

Make sure the Airbyte raw table (`_airbyte_raw_module_<module-uuid>`) exists before running dbt locally.
