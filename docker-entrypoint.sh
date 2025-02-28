#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database..."
/wait-for-it.sh db:5432 -t 60

# Navigate to the project directory
cd /app/project

# Create migrations for any model changes
echo "Creating migrations if needed..."
python manage.py makemigrations

# Apply migrations
echo "Applying migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start the application
echo "Starting application server..."
exec gunicorn project.wsgi:application --bind 0.0.0.0:80
