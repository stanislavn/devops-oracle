#!/bin/bash

# This script ensures your Postgres volume is properly created and configured

# Ensure the script exists if there are any errors
set -e

# Create named volume if it doesn't exist
if ! docker volume inspect django_postgres_data >/dev/null 2>&1; then
    echo "Creating postgres data volume 'django_postgres_data'..."
    docker volume create django_postgres_data
    echo "Volume created successfully."
else
    echo "Volume 'django_postgres_data' already exists."
fi

# Create a docker-compose file that ensures the database is initialized properly
cat > docker-compose.init.yml <<EOF
version: '3.8'

services:
  db:
    image: postgres:15
    env_file:
      - .env.prod
    volumes:
      - django_postgres_data:/var/lib/postgresql/data
    restart: "no"
    command: ["postgres", "-c", "max_connections=100"]

volumes:
  django_postgres_data:
    external: true
EOF

# Start the database to ensure it's properly initialized
echo "Initializing database..."
docker-compose -f docker-compose.init.yml up -d db

# Wait for the database to be ready
echo "Waiting for database to be ready..."
sleep 5

# Check if the database is running
if docker-compose -f docker-compose.init.yml ps db | grep -q "Up"; then
    echo "Database is running. Volume is properly initialized."
    # Stop the temporary container
    docker-compose -f docker-compose.init.yml down
    # Remove temporary file
    rm docker-compose.init.yml
    echo "Success! The volume 'django_postgres_data' is ready for use."
else
    echo "Error: Database failed to start. Check your environment variables and permissions."
    docker-compose -f docker-compose.init.yml logs db
    docker-compose -f docker-compose.init.yml down
    rm docker-compose.init.yml
    exit 1
fi
