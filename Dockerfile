# Use official Python image
FROM python:3.12.4-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies for Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy wait-for-it script
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs and backups
VOLUME /app/logs
VOLUME /app/db_backups

# Create a directory for database backups
RUN mkdir -p /app/db_backups

# Expose port 80
EXPOSE 80

# Start script with proper error handling and logging
COPY <<'EOF' /app/start.sh
#!/bin/bash
set -e

# Wait for database
/wait-for-it.sh db:5432 -t 60

# Navigate to project directory
cd /app/project

# Create database backup before applying migrations
echo "$(date): Creating database backup before migrations..."
BACKUP_FILE="/app/db_backups/pre_migration_backup_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h db -U $POSTGRES_USER $POSTGRES_DB > "$BACKUP_FILE" || echo "Warning: Backup failed but continuing..."

# Run migrations with proper error handling
echo "$(date): Running migrations..."

# Only run makemigrations in development, not in production
if [ "$DEBUG" = "True" ]; then
  echo "$(date): Running makemigrations (development mode)..."
  python manage.py makemigrations
else
  echo "$(date): Skipping makemigrations in production mode..."
fi

# Always run migrate
python manage.py migrate --noinput || {
    echo "$(date): Migration failed! Restoring from backup..."
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U $POSTGRES_USER $POSTGRES_DB < "$BACKUP_FILE"
        echo "$(date): Restored from backup"
    else
        echo "$(date): No valid backup found to restore from!"
    fi
    exit 1
}

# Collect static files
echo "$(date): Collecting static files..."
python manage.py collectstatic --noinput

# Start gunicorn
echo "$(date): Starting application server..."
exec gunicorn project.wsgi:application --bind 0.0.0.0:80
EOF

# Make script executable
RUN chmod +x /app/start.sh

# Start the application using our start script
CMD ["/app/start.sh"]