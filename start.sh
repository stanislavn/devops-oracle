#!/bin/bash
# This is the startup script for the Django application
set -e

# Wait for the database to be ready
echo "Waiting for database..."
# Use wait-for-it instead of nc for more reliable connection checking
wait-for-it -t 60 db:5432 -- echo "Database is up!"

# As fallback, verify we can actually connect to PostgreSQL
max_retries=10
count=0
until PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1" > /dev/null 2>&1; do
  echo "Verifying PostgreSQL connection..."
  count=$((count+1))
  if [ $count -ge $max_retries ]; then
    echo "Maximum retries reached, proceeding anyway but there might be issues"
    break
  fi
  sleep 5
done

# Navigate to the project directory
cd /app/project

# Database migration steps
echo "Listing available migrations before running..."
python manage.py showmigrations

echo "Making migrations for all apps..."
python manage.py makemigrations --noinput

echo "Running migrations with verbosity..."
python manage.py migrate --noinput -v 2

echo "Verifying migrations were applied..."
python manage.py showmigrations

# Set up management commands
echo "Registering management commands..."
python manage.py register_commands 2>/dev/null || echo "Command not found, continuing anyway"

# Ensure admin user exists
echo "Ensuring admin user exists..."
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword') if not User.objects.filter(username='admin').exists() else print('Admin user already exists')"

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start the application server
echo "Starting gunicorn..."
exec gunicorn project.wsgi:application --bind 0.0.0.0:80 --timeout 120 