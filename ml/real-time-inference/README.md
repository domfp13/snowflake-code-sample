# Fraud Detection - Real-Time Inference

Node.js app that sends single-transaction inference requests to a Snowflake ML model service (`FRAUD_DETECTION_XGBOOST`) running on SPCS.

## Prerequisites

- Docker and Docker Compose
- A Snowflake Programmatic Access Token (PAT) with access to the inference service endpoint
- The inference service created and endpoint enabled:
  ```sql
  SHOW ENDPOINTS IN SERVICE INSURANCE_CLAIMS_DEMO.COCO_ML_DEMO_4.FRAUD_DETECTION_SERVICE;
  ```

## Setup

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```
SNOWFLAKE_PAT=eyJ...your_token_here
INFERENCE_URL=https://at3d3i-sfseeurope-eplatauswest.snowflakecomputing.app
```

## Run

```bash
# Build and start
docker compose up --build

# Start in the background
docker compose up -d --build

# View logs when running in background
docker compose logs -f
```

Open http://localhost:3000

## Stop

```bash
# Stop and remove containers
docker compose down
```

## Rebuild

```bash
# Rebuild image and restart
docker compose up --build -d

# Force full rebuild (no cache)
docker compose build --no-cache && docker compose up -d
```

## Notes

- If the inference service is suspended, the first request triggers an auto-resume. Expect a cold-start delay (1-3 minutes) while SPCS provisions the containers.
- Check service status:
  ```sql
  SELECT SYSTEM$GET_SERVICE_STATUS('INSURANCE_CLAIMS_DEMO.COCO_ML_DEMO_4.FRAUD_DETECTION_SERVICE');
  ```
- The app computes 9 derived features locally (matching the SQL feature engineering) and sends them as a single-row `dataframe_records` POST to the `/predict-proba` endpoint.
