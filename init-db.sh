#!/bin/bash
set -e

trap 'echo "An error occurred. Exiting..."; exit 1' ERR

cmd="$@"

# Construct DATABASE_URL from environment variables if not already set
if [ -z "$DATABASE_URL" ]; then
  export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
fi

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -d "$DATABASE_URL" -q; do
  echo "PostgreSQL is unavailable - sleeping 2s..."
  sleep 2
done
echo "PostgreSQL is ready!"

# Restore the prepared US Team Fleet database only when the cloud database is
# completely new. The dump contains the organisation, users, password hashes,
# settings, and migration history required for the first production launch.
SEED_DUMP="/app/prisma/seed/us-team-fleet-cloud.dump"
if [ -f "$SEED_DUMP" ]; then
  PUBLIC_TABLE_COUNT="$(psql "$DATABASE_URL" -Atqc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")"
  if [ "$PUBLIC_TABLE_COUNT" = "0" ]; then
    echo "Restoring US Team Fleet seed database..."
    pg_restore --no-owner --no-acl --dbname="$DATABASE_URL" "$SEED_DUMP"
    echo "Seed database restored successfully!"
  fi
fi

echo "Applying database migrations..."
if ! npx prisma migrate deploy 2>/dev/null; then
  # P3005: existing DB without migration history (from db push).
  # Create empty migration table so migrate deploy can run.
  # 0_init is fully idempotent — safe on any DB state.
  echo "Existing database detected. Creating migration table..."
  npx prisma db execute --stdin <<< 'CREATE TABLE IF NOT EXISTS "_prisma_migrations" ("id" VARCHAR(36) PRIMARY KEY NOT NULL, "checksum" VARCHAR(64) NOT NULL, "finished_at" TIMESTAMPTZ, "migration_name" VARCHAR(255) NOT NULL, "logs" TEXT, "rolled_back_at" TIMESTAMPTZ, "started_at" TIMESTAMPTZ NOT NULL DEFAULT now(), "applied_steps_count" INTEGER NOT NULL DEFAULT 0)'
  npx prisma migrate deploy
fi
echo "Migrations applied successfully!"

echo "Starting application..."
exec $cmd
