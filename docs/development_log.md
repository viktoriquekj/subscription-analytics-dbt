# Development log — subscription-analytics

This file documents every significant decision, finding, and change made during
the development of this project. It exists because real analytical work involves
dead ends, surprises, and deliberate trade-offs — not just clean final outputs.

---

## v0.1 — seed-based prototype
**Tag:** `v0.1-seed-prototype`

Built the initial dbt project structure to validate the model DAG before
committing to a real dataset. Used synthetic CSV seeds with 10 subscription
rows and 6 event rows — small enough to reason about manually.

**What this version proved:**
- The three-layer architecture works: staging → marts → custom tests
- dbt runs cleanly in a local DuckDB environment
- The `stg_subscriptions → dim_customers → fct_mrr → fct_churn` lineage
  materialises without errors
- Custom SQL tests (`assert_mrr_is_not_negative.sql`) integrate correctly
  alongside generic schema tests

**Why seeds were not kept for the real project:**
dbt seeds are designed for small, static reference data — country codes,
plan-name mappings, lookup tables. Using them for ML training data is an
anti-pattern: seeds are version-controlled CSVs committed to git, which is
inappropriate for datasets of any meaningful size, and they offer no path
to the real ingestion patterns (API connectors, ETL tools, scheduled loads)
that a production pipeline would use. The prototype served its purpose;
the real project needed a proper source.

---

## v1.0 — migration to real data source
**Branch:** `feat/real-data-source`
**Merged to:** `main`

### Dataset selected: IBM Telco Customer Churn

Chose the IBM Telco dataset after evaluating it against the project goal of
producing a churn ML feature table. Key reasons:

- 7,043 customers — sufficient for a real classification model
- 20 meaningful columns covering demographics, contract type, service usage,
  and billing
- Clean binary churn target (`has_churned`)
- Realistic class imbalance (~26.5% churn) matching real subscription products
- No licence restrictions on portfolio use

Rejected alternatives considered:
- Synthetic seed data (too small, no real signal)
- Online Retail / UCI transaction dataset (better for LTV, not churn — wrong
  problem framing)
- Kaggle e-commerce churn (weaker feature set)

---

### Data loading — load_sources.py

Wrote `load_sources.py` to load the raw CSV into DuckDB as a proper source
table (`raw_telco_customers`), replacing the seed approach entirely. Script
output on first run:

```
Customers with null TotalCharges (new, no charges yet): 11
Loaded 7043 rows into raw_telco_customers
Overall churn rate: 26.5%
```

**Finding: 11 customers have null `TotalCharges`.**
The raw CSV stores blank strings (not nulls) for customers with zero tenure
who have not yet been billed. `pd.to_numeric(..., errors='coerce')` in the
loader converts these to proper nulls before the table is created. This is
handled at ingestion rather than in dbt to keep the staging model clean.

**Implication for the ML project:** These 11 rows will need imputation in the
`churn-prediction` pipeline — most likely filling `total_charges` with 0 or
with `monthly_charges × tenure_months`. Since `total_charges` is excluded from
ML features entirely (see below), this finding has no impact on model training.
It is documented here for completeness.

---

### Deletions: stg_events.sql and fct_churn.sql

**`stg_events.sql` — deleted.**
The original project included a staging model for subscription events
(upgrades, downgrades, cancellations) sourced from a synthetic `raw_events.csv`
seed. The Telco dataset has no events table — it is a single customer snapshot,
not a transaction log. There is no source to stage. The model was deleted rather
than left empty to avoid confusion about the DAG structure.

**`fct_churn.sql` — deleted.**
The original churn mart produced one row per churned subscription with timing
columns (`days_active_before_churn`, `cancelled_at`) derived by joining
subscriptions to cancellation events. Both inputs are gone — there is no events
table and no per-subscription date history in the Telco source. The churn signal
(`has_churned`) is now a direct column in `stg_customers` and flows through to
`fct_churn_features` as the ML target variable. No separate churn mart is needed.

---

### Feature engineering decision: total_charges excluded from fct_churn_features

The Telco source includes a `total_charges` column representing the customer's
cumulative spend. This column was deliberately excluded from `fct_churn_features`
and is not passed to the ML project.

**Reason:** `total_charges` is approximately equal to `tenure_months ×
monthly_charges`. Including it as a feature alongside both of those columns
introduces near-perfect multicollinearity and, more critically, creates a proxy
for the target: customers with very low `total_charges` are almost always either
new (low tenure) or about to churn. A model trained with this feature would show
inflated performance metrics that do not generalise to new customers.

`monthly_charges` is retained. It reflects the customer's plan tier — a
business-meaningful signal — and is known at prediction time without depending
on accumulated history.

This decision is also documented in `models/marts/schema.yml` against the
`fct_churn_features` model description.

---

### marts/schema.yml updated

Rewrote the marts schema to reflect the new model set:

- `dim_customers` — updated columns to match Telco fields; added
  `accepted_values` tests on `contract_type` and `has_churned`
- `fct_mrr` — changed primary grouping from `month + plan` (seed-era logic)
  to `contract_type`; added `unique` test on `contract_type` to enforce exactly
  three output rows
- `fct_churn` — removed entirely (see deletion above)
- `fct_churn_features` — added as new model with full column documentation,
  including explicit note on `total_charges` exclusion

---

### ML handoff: export_features.py

Added `export_features.py` to write `fct_churn_features` to
`exports/churn_features.csv`. This CSV is the interface between this dbt project
and the `churn-prediction` ML repository. The `exports/` folder is gitignored —
it is a generated artefact, not source code. The `churn-prediction` README
instructs users to run this script to produce their model input.