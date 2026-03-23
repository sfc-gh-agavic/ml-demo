# Snowflake ML Hands-On Lab

An instructor-led workshop covering end-to-end machine learning on Snowflake. Uses the classic diamonds dataset to walk through data ingestion, feature engineering, model training, and deployment — all running natively in Snowflake Notebooks on Container Runtime with Snowpark ML.

## Workshop Structure

| Part | File | Description |
|------|------|-------------|
| Setup | `hol-setup.sql` | Admin setup script — creates users, roles, warehouses, compute pools, network rules, and external stages |
| 1 | `SNOW-ML-HOL-1.ipynb` | **Data Ingestion** — Load diamonds CSV from S3 into a Snowflake table via Snowpark |
| 2 | `SNOW-ML-HOL-2.ipynb` | **Feature Store** — Profile, cleanse, and register features using Snowflake Feature Store (backed by Dynamic Tables) |
| 3 | `SNOW-ML-HOL-3.ipynb` | **Model Training & Deployment** — Train an XGBoost regressor with Ray-distributed GridSearchCV on the compute pool, log models to the Snowflake Model Registry, run batch inference, and generate SHAP explanations |

## Tech Stack

- **Snowflake Notebooks on Container Runtime** — Python kernel runs on Snowpark Container Services compute pools; SQL and Snowpark queries are pushed down to a virtual warehouse
- **Ray** — Pre-installed in Container Runtime; used for distributed hyperparameter tuning via `scale_cluster()` and Ray's joblib backend
- **Snowpark ML** (`snowflake-ml-python`) for preprocessing, feature store, and model registry
- **OSS scikit-learn / XGBoost** — GridSearchCV and XGBRegressor run in-memory on the compute pool, distributed across Ray workers
- **Snowflake Feature Store** for feature management via Dynamic Tables
- **Snowflake Model Registry** for model versioning and deployment
- **SHAP** for model explainability
- **matplotlib / seaborn** for visualization

## Prerequisites

- A Snowflake account with `ACCOUNTADMIN` access (for initial setup)
- Snowflake Notebooks enabled with Container Runtime support
- Compute pools provisioned (the setup script creates CPU and GPU pools)
- An admin runs `hol-setup.sql` to provision users, warehouses, compute pools, and PyPI external access before the workshop

## Compute Model

Notebooks on Container Runtime use **two compute resources**:

- **Compute pool** — runs the Python kernel, in-memory operations, and Ray-distributed hyperparameter tuning (each user requires one node; `scale_cluster()` adds worker nodes for HPO)
- **Virtual warehouse** — executes SQL queries, Snowpark pushdown operations, and Snowpark ML stored-procedure-based training (e.g., the simple `model.fit()`)

This means participants may incur both warehouse and SPCS compute pool costs during the workshop.

## Beyond Batch Inference

This workshop demonstrates **batch inference** via a stored procedure, but the notebook also covers:

- **Real-time inference** — Deploy any registered model as a managed REST API endpoint on SPCS using `model_version.create_service()`, with autoscaling and a public HTTP endpoint
- **Model observability** — Monitor prediction drift (PSI, KL Divergence) and performance metrics over time using `CREATE MODEL MONITOR`, with results surfaced in the Snowsight UI

## Getting Started

1. An admin executes `hol-setup.sql` in a Snowflake worksheet to create the lab environment (supports up to 20 concurrent users).
2. Each participant creates a new notebook, selecting **Run on container** for the Runtime, a **CPU compute pool**, and their assigned warehouse.
3. Participants work through the notebooks in order (Parts 1, 2, 3). All required packages (`snowflake-ml-python`, `seaborn`, `shap`, etc.) are pre-installed in the Container Runtime image — no manual package installation is needed.
4. If additional packages are required, they can be installed via `!pip install` (requires the PyPI External Access Integration provisioned by the setup script).
