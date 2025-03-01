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
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs and backups
VOLUME /app/logs
VOLUME /app/db_backups

# Create a directory for database backups
RUN mkdir -p /app/db_backups

# Create startup script with proper migration handling
RUN cat > /app/start.sh << 'EOF'
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
python manage.py register_commands

echo "Ensuring admin user exists..."
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword') if not User.objects.filter(username='admin').exists() else print('Admin user already exists')"

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting gunicorn..."
gunicorn project.wsgi:application --bind 0.0.0.0:80 --timeout 120
EOF

# Make the startup script executable
RUN chmod +x /app/start.sh

# Expose port 80
EXPOSE 80

# Set the script as the command to run
CMD ["/app/start.sh"]