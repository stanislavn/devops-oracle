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
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Waiting for database..."' >> /app/start.sh && \
    echo '# Check if the database is ready' >> /app/start.sh && \
    echo 'until nc -z -v -w30 db 5432; do' >> /app/start.sh && \
    echo '  echo "Waiting for database connection..."' >> /app/start.sh && \
    echo '  sleep 5' >> /app/start.sh && \
    echo 'done' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'cd /app/project' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Listing available migrations before running..."' >> /app/start.sh && \
    echo 'python manage.py showmigrations' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Making migrations for all apps..."' >> /app/start.sh && \
    echo 'python manage.py makemigrations --noinput' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Running migrations with verbosity..."' >> /app/start.sh && \
    echo 'python manage.py migrate --noinput -v 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Verifying migrations were applied..."' >> /app/start.sh && \
    echo 'python manage.py showmigrations' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Registering management commands..."' >> /app/start.sh && \
    echo 'python manage.py register_commands' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Ensuring admin user exists..."' >> /app/start.sh && \
    echo 'python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser(\"admin\", \"admin@example.com\", \"adminpassword\") if not User.objects.filter(username=\"admin\").exists() else print(\"Admin user already exists\")"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Collecting static files..."' >> /app/start.sh && \
    echo 'python manage.py collectstatic --noinput' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Starting gunicorn..."' >> /app/start.sh && \
    echo 'gunicorn project.wsgi:application --bind 0.0.0.0:80 --timeout 120' >> /app/start.sh && \
    chmod +x /app/start.sh

# Expose port 80
EXPOSE 80

# Set the script as the command to run
CMD ["/app/start.sh"]