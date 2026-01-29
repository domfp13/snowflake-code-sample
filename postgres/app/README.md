# Orders Admin App (Postgres)

Small Streamlit app to search, add/update, and delete records from the `public.orders` table.

## Requirements
- Docker
- Access to your Postgres instance

## Configure
Create/update the `.env` file with your Postgres credentials:

```
PGHOST=your-host
PGPORT=5432
PGUSER=your-user
PGPASSWORD=your-password
PGDATABASE=postgres
```

## Build the container
From the `postgres/app` folder:

```
docker build --no-cache -t orders-admin .
```

## Run the container

Run in background:

```
docker run -d --name orders-app -p 8501:8501 --env-file .env orders-admin
```

Open http://localhost:8501

## Stop the container

Stop and remove:

```
docker stop orders-app
docker rm orders-app
```

Or in one command:

```
docker rm -f orders-app
```

All commans:
```
docker rm -f orders-app
docker rmi orders-admin
docker build --no-cache -t orders-admin .
docker run -d --name orders-app -p 8501:8501 --env-file .env orders-admin
```

## Notes
- Search uses `ORDER_ID`.
- Add/Update uses UPSERT on `ORDER_ID`.
- Delete removes a record by `ORDER_ID`.
- The `-d` flag runs the container in the background.
