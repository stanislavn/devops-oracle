#!/bin/bash
set -e

echo "Waiting for database..."
# Check if the database is ready
until nc -z -v -w30 db 5432; do
  echo "Waiting for database connection..."
  sleep 5
done

cd /app/project

echo "Listing available migrations before running..."
python manage.py showmigrations

echo "Making migrations for all apps..."
python manage.py makemigrations --noinput

echo "Running migrations with verbosity..."
python manage.py migrate --noinput -v 2

echo "Verifying migrations were applied..."
python manage.py showmigrations

echo "Registering management commands..."
python manage.py register_commands || echo "Command not found, continuing anyway"

echo "Ensuring admin user exists..."
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword') if not User.objects.filter(username='admin').exists() else print('Admin user already exists')"

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting gunicorn..."
gunicorn project.wsgi:application --bind 0.0.0.0:80 --timeout 120 