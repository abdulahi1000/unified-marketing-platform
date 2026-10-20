# Unified Marketing Analytics

A dbt project that standardizes paid-social advertising data from Facebook Ads and Snapchat Ads into reusable marketing dimensions and performance facts on Databricks.

The project follows a layered warehouse pattern:

```text
Bronze source tables
        ↓
Staging: source-specific cleanup and naming
        ↓
Intermediate: latest ad attributes and normalized performance metrics
        ↓
Marts: cross-platform dimensions and facts
```

## What this project provides

- A conformed ad dimension in `dim_marketing_ads`.
- A daily marketing-spend fact table in `fct_marketing_spend`.
- Consistent identifiers, channel labels, source labels, and calculated metrics across platforms.
- Source freshness configuration and column-level data tests.
- `dbt_utils.union_relations` for cross-platform unions, so schema differences are handled centrally.

## Data model

| Layer | Model | Purpose | Grain |
| --- | --- | --- | --- |
| Staging | `stg_facebook_ads*` | Facebook descriptive entities and daily performance | Source-defined entity or ad/date row |
| Staging | `stg_snapchat_ads*` | Snapchat descriptive entities and daily performance | Source-defined entity or ad/date row |
| Intermediate | `int_facebook_ads_details` | Latest Facebook ad attributes enriched with group, campaign, and account names | One row per Facebook ad |
| Intermediate | `int_facebook_ads_stats` | Facebook metrics and derived CTR, CPC, and CPM | One row per Facebook ad/date |
| Intermediate | `int_snapchat_ads_details` | Latest Snapchat ad attributes enriched with group and campaign names | One row per Snapchat ad |
| Intermediate | `int_snapchat_ads_stats` | Snapchat metrics joined to ad account details | One row per Snapchat ad/date |
| Mart | `dim_marketing_ads` | Unified descriptive ad dimension | One row per source platform and ad |
| Mart | `fct_marketing_spend` | Unified daily paid-social performance | One row per source, ad, country, and date |

## Key modeling decisions

`int_facebook_ads_details` uses left joins because the ad is the driving entity and descriptive records may arrive independently. Each descriptive source is deduplicated with the most recently updated record before enrichment.

The marts combine Facebook and Snapchat rows with `dbt_utils.union_relations`. This is intentionally separate from the enrichment joins: a union appends comparable records from different platforms, while a join adds attributes to the same record. Missing platform-specific columns are represented as typed nulls by the macro-generated SQL.

Marketing metrics are calculated as:

- CTR = clicks / impressions
- CPC = spend / clicks
- CPM = spend / impressions × 1,000

Each metric uses `NULLIF` to avoid division-by-zero errors. `ad_key` is generated from `data_src` and `ad_id`, preventing collisions between platforms that may reuse natural ad identifiers.

## Source systems

Both source groups are configured for the `bronze_production.unified_marketing_staging` catalog and schema:

- `facebook_ads`: account, campaign, ad, ad group, and daily ad-stat tables.
- `snapchat_ads`: campaign, ad, ad group, and daily ad-stat tables.

Source freshness is configured to warn when data is more than two days old. Source and model ownership metadata currently identifies the `data_team`.

## Project configuration

The project is named `unified_marketing_analytics` and uses the Databricks adapter. Models are materialized as tables:

- Staging models use the `staging` schema.
- Intermediate models use the `preparation` schema.
- Mart models use the `marketing_spend` schema.
- Staging and production targets use `silver_<target>` and `gold_<target>` catalogs respectively; development uses the configured catalog.

The project depends on `dbt-labs/dbt_utils`, `elementary-data/elementary`, and `metaplane/dbt_expectations`.

## Prerequisites

- Python 3.12.
- A Databricks workspace and SQL warehouse or cluster.
- Databricks credentials with access to the configured catalogs and schemas.
- `uv` and dbt packages installed.

## Local setup

From the repository root:

```powershell
uv sync
Set-Location unified_marketing_analytics
dbt deps
```

Configure the environment variables consumed by `profiles.yml`:

| Variable | Purpose |
| --- | --- |
| `DBT_TARGET` | Target output name; defaults to `dev` |
| `DATABRICKS_HOST` | Databricks workspace host |
| `HTTP_PATH` | SQL warehouse or cluster HTTP path |
| `DEV_CATALOG` | Development catalog |
| `DEV_SCHEMA` | Development schema |
| `DATABRICKS_PAT_TOKEN` | Token for the development target |
| `DATABRICKS_CLIENT_ID` | OAuth client ID for CI, staging, and production |
| `DATABRICKS_CLIENT_SECRET` | OAuth client secret for CI, staging, and production |

The `dev` profile uses a personal access token. The `ci`, `staging`, and `production` profiles use OAuth client credentials.

## Common commands

Run these commands from `unified_marketing_analytics`:

```powershell
# Install or refresh package dependencies
dbt deps

# Parse and validate project configuration
dbt parse

# Build all models and execute data tests
dbt build

# Build the marts and their upstream dependencies
dbt build --select +dim_marketing_ads +fct_marketing_spend

# Run tests without rebuilding models
dbt test

# Check source freshness
dbt source freshness

# Generate documentation artifacts
dbt docs generate
```

For a focused development cycle:

```powershell
dbt build --select +int_facebook_ads_details
```

## Testing and quality checks

The repository tests primary keys, required fields, accepted source and channel values, and uniqueness at the documented grain. Before opening a pull request, run:

```powershell
dbt parse
dbt build
dbt source freshness
```

The uniqueness tests on `dim_marketing_ads` and `fct_marketing_spend` protect against duplicate platform/ad keys and duplicate daily performance rows.

## Repository structure

```text
unified_marketing_analytics/
├── analyses/       # Ad hoc analytical SQL
├── macros/         # Project-specific dbt macros
├── models/
│   ├── staging/    # Source-specific models and source definitions
│   ├── intermediate/
│   └── marts/      # Business-facing dimensions and facts
├── packages.yml    # dbt package dependencies
├── profiles.yml    # Databricks targets and credential references
└── dbt_project.yml
```

## Adding another advertising platform

1. Add source definitions and staging models.
2. Create an intermediate details model with conformed ad attributes.
3. Create an intermediate stats model with conformed performance fields and metrics.
4. Add the intermediate relations to the `union_relations` calls in the two marts.
5. Add or update tests for the new source identifier and grain.
6. Run `dbt build` and `dbt source freshness` against the intended target.

When adding fields, preserve shared column names and types where possible. Platform-specific fields are valid, but downstream nullability and source availability should be documented.

## Security and operations

Credentials are referenced through environment variables and should not be committed. Review catalog, schema, and warehouse permissions before running against staging or production. Generated `target/`, `logs/`, and local environment files are development artifacts and should remain excluded from commits.

## Contents

- [Repository layout](#repository-layout)
- [What the project contains](#what-the-project-contains)
- [Data sources](#data-sources)
- [Model layers](#model-layers)
- [Lineage](#lineage)
- [Environments](#environments)
- [Local development](#local-development)
- [Development workflow](#development-workflow)
- [Testing and observability](#testing-and-observability)
- [Conventions](#conventions)
- [Troubleshooting](#troubleshooting)

## Repository layout

```text
.
├── README.md
├── pyproject.toml          # Python and dbt adapter dependencies
├── uv.lock                 # Reproducible Python dependency lockfile
├── .python-version         # Project Python version
└── unified_marketing_analytics/
    ├── dbt_project.yml     # dbt project configuration and model routing
    ├── profiles.yml        # Databricks targets and credential references
    ├── packages.yml        # dbt package dependencies
    ├── package-lock.yml    # Resolved dbt package versions
    ├── macros/             # Project-specific database and schema macros
    ├── models/
    │   ├── staging/        # Source declarations and source-specific models
    │   ├── intermediate/   # Deduplication, enrichment, and metric preparation
    │   └── marts/          # Cross-platform dimensions and facts
    ├── analyses/           # Ad hoc analytical SQL
    ├── seeds/              # Seed data, when required
    ├── snapshots/          # Snapshot definitions, when required
    ├── tests/              # Singular tests, when required
    └── .env                # Local-only environment variables; never commit
```

The dbt project lives in `unified_marketing_analytics/`; commands that need dbt should be run from that directory so dbt discovers the project and profile correctly.

## What the project contains

### Packages

| Package | Role |
| --- | --- |
| `dbt-labs/dbt_utils` | Reusable SQL macros, including `union_relations` and `generate_surrogate_key` |
| `elementary-data/elementary` | Data observability artifacts and reporting models |
| `metaplane/dbt_expectations` | Expectation-based data tests |

### Project macros

The project defines custom `generate_database_name` and `generate_schema_name` macros. Together with the model configuration in `dbt_project.yml`, these route staging, intermediate, and mart models to the expected Databricks catalog and schema for each target.

## Data sources

Sources are declared in the platform-specific files under `unified_marketing_analytics/models/staging/` and currently point to the `bronze_production.unified_marketing_staging` catalog and schema.

### Facebook Ads

| Source table | Business entity | Freshness event time |
| --- | --- | --- |
| `facebook_new_acccount` | Facebook ad account | `account_updated_at` |
| `facebook_campaign` | Facebook campaign | `campaign_updated_at` |
| `facebook_ads` | Facebook ad | `ad_updated_at` |
| `facebook_adgroup` | Facebook ad group | `ad_group_updated_at` |
| `facebook_ads_stats` | Daily Facebook ad performance | `ad_date` |

### Snapchat Ads

| Source table | Business entity | Freshness event time |
| --- | --- | --- |
| `snapchat_ads_campaign_names` | Snapchat campaign | Not configured |
| `snapchat_ad_names` | Snapchat ad | `ad_detail_updated_at` |
| `snapchat_ads_group_names` | Snapchat ad group | `ad_group_updated_at` |
| `snapchat_ads_stats` | Daily Snapchat ad performance | `ad_date` |

Both source groups warn when data is more than two days old. Source definitions also include ownership metadata for the `data_team`.

## Model layers

### Staging

Staging models provide source-specific names and shapes for downstream transformations:

| Platform | Models |
| --- | --- |
| Facebook | `stg_facebook_ads`, `stg_facebook_ads_group`, `stg_facebook_ads_campaign`, `stg_facebook_ads_account`, `stg_facebook_ads_stats` |
| Snapchat | `stg_snapchat_ads`, `stg_snapchat_ads_group`, `stg_snapchat_ads_campaign`, `stg_snapchat_ads_stats` |

### Intermediate

`int_facebook_ads_details` and `int_snapchat_ads_details` create the latest descriptive record for each ad. The Facebook model deduplicates ads, ad groups, campaigns, and accounts with `ROW_NUMBER()` ordered by the relevant update timestamp, then enriches the ad with descriptive attributes using left joins.

The stats models standardize performance fields and calculate:

```text
CTR = clicks / impressions
CPC = spend / clicks
CPM = spend / impressions * 1,000
```

Each calculation uses `NULLIF` to avoid division-by-zero errors.

### Marts

| Model | Materialization | Grain | Purpose |
| --- | --- | --- | --- |
| `dim_marketing_ads` | Table | One row per source platform and ad | Unified descriptive ad dimension |
| `fct_marketing_spend` | Table | One row per source, ad, country, and date | Unified daily performance fact |

The marts use `dbt_utils.union_relations` to append Facebook and Snapchat relations. This is deliberately different from the joins in the intermediate details models: joins enrich an existing platform record, while unions combine equivalent records across platforms. The macro supplies nulls for columns that are not available from every source and keeps the union logic maintainable as schemas evolve.

## Lineage

```text
Facebook sources
    -> Facebook staging models
        -> int_facebook_ads_details  -> dim_marketing_ads
        -> int_facebook_ads_stats    -> fct_marketing_spend

Snapchat sources
    -> Snapchat staging models
        -> int_snapchat_ads_details  -> dim_marketing_ads
        -> int_snapchat_ads_stats    -> fct_marketing_spend
```

The marts generate `ad_key` with `data_src` and `ad_id`, ensuring that identical natural identifiers from different advertising platforms remain distinct.

## Environments

The active target is selected with `DBT_TARGET` and defaults to `dev`.

| Target | Typical use | Authentication | Model destination |
| --- | --- | --- | --- |
| `dev` | Local development | Databricks personal access token | Configured `DEV_CATALOG.DEV_SCHEMA` with layer schemas |
| `ci` | Continuous integration or isolated validation | Databricks OAuth service principal | Configured development catalog and schema |
| `staging` | Pre-production validation | Databricks OAuth service principal | `silver_staging` and `gold_staging` layer catalogs |
| `production` | Production workloads | Databricks OAuth service principal | `silver_production` and `gold_production` layer catalogs |

On `staging` and `production`, model routing is:

| Layer | Schema | Catalog pattern |
| --- | --- | --- |
| Staging | `staging` | `silver_<target>` |
| Intermediate | `preparation` | `silver_<target>` |
| Marts | `marketing_spend` | `gold_<target>` |

Elementary uses the same target names and is configured to write its observability models through the Elementary profile in `profiles.yml`.

## Local development

### 1. Install Python dependencies

From the repository root:

```powershell
uv sync
Set-Location unified_marketing_analytics
```

The project requires Python 3.12 and installs `dbt-databricks` plus the Databricks-enabled Elementary package.

### 2. Configure credentials

Set the following variables in a local, git-ignored `.env` or in the shell environment:

```powershell
$env:DBT_TARGET = "dev"
$env:DATABRICKS_HOST = "https://<workspace-host>"
$env:HTTP_PATH = "/sql/1.0/warehouses/<warehouse-id>"
$env:DEV_CATALOG = "<development-catalog>"
$env:DEV_SCHEMA = "<development-schema>"
$env:DATABRICKS_PAT_TOKEN = "<personal-access-token>"
```

For `ci`, `staging`, or `production`, configure `DATABRICKS_CLIENT_ID` and `DATABRICKS_CLIENT_SECRET` instead of relying on the development PAT.

Never commit credentials, `.env` files, or generated target artifacts.

### 3. Install dbt packages and verify the connection

```powershell
uv run dbt deps
uv run dbt debug
```

`dbt debug` requires a reachable Databricks workspace and valid credentials. `dbt parse` can validate project structure without building warehouse relations.

### 4. Build the project

```powershell
uv run dbt build
```

Useful focused commands:

```powershell
# Build a model and all upstream dependencies
uv run dbt build --select +int_facebook_ads_details

# Build both business-facing marts and their parents
uv run dbt build --select +dim_marketing_ads +fct_marketing_spend

# Run only tests
uv run dbt test

# Check source freshness
uv run dbt source freshness

# Generate and serve dbt documentation
uv run dbt docs generate
uv run dbt docs serve
```

## Development workflow

1. Create a branch from the project’s main development branch.
2. Make model, test, macro, or documentation changes inside `unified_marketing_analytics/`.
3. Run `uv run dbt parse` to catch project and Jinja configuration errors.
4. Run focused builds and tests against a development schema.
5. Run the full `uv run dbt build` when upstream or shared mart logic changes.
6. Review generated documentation and test results before committing.
7. Keep credentials and generated artifacts out of source control.

This repository currently contains the dbt project and local tooling configuration. No GitHub Actions workflow is present in the repository, so CI/CD deployment behavior should be added and documented separately when an automated pipeline is introduced.

## Testing and observability

The model YAML files define tests for:

- Required identifiers and dates with `not_null`.
- Natural-key uniqueness for ads, ad groups, campaigns, and accounts.
- Accepted platform values in `data_src`.
- Accepted `Paid Social` channel values.
- Composite uniqueness at the documented grain using `dbt_utils.unique_combination_of_columns`.

The most important mart-level protections are:

| Model | Uniqueness contract |
| --- | --- |
| `dim_marketing_ads` | `data_src` + `ad_id` identifies one ad |
| `fct_marketing_spend` | `data_src` + `ad_id` + `ad_country` + `ad_date` identifies one daily performance row |

Run tests after changing source mappings, deduplication rules, joins, union columns, or metric calculations.

## Conventions

- Model names follow `stg_<source>_<entity>`, `int_<source>_<entity>`, `dim_<business_entity>`, and `fct_<business_process>` patterns.
- Every documented model has a neighboring YAML file containing descriptions and data tests.
- Platform-specific intermediate models retain source-specific logic; cross-platform harmonization happens in the marts.
- Use `dbt_utils.union_relations` when appending relations with compatible business meaning and potentially different columns.
- Use joins when enriching a row with attributes from a related entity.
- Use `dbt_utils.generate_surrogate_key` for keys that must remain unique across source systems.
- Preserve the documented grain of every model and update its YAML description and tests when the grain changes.
- Keep source names, `data_src` values, and accepted test values synchronized.

## Troubleshooting

### dbt cannot find the project

Run dbt from the project directory:

```powershell
Set-Location unified_marketing_analytics
uv run dbt debug
```

### Authentication or connection failures

Verify `DATABRICKS_HOST`, `HTTP_PATH`, the selected `DBT_TARGET`, and the credentials required by that target. Confirm that the identity can read the bronze source catalog and write to the target catalog and schema.

### Package or macro errors

Refresh packages and inspect the resolved lock file:

```powershell
uv run dbt deps
uv run dbt parse --no-partial-parse
```

### Duplicate rows in a details model

Check the source update timestamps and the `ROW_NUMBER()` partition key. The details models expect one latest descriptive record per entity key before the enrichment joins are applied.

### Missing columns after a platform union

Confirm that the intermediate relation exposes the shared field under the expected name and type. `dbt_utils.union_relations` creates null values for source-specific fields, so downstream models should document fields that are unavailable on a platform.
