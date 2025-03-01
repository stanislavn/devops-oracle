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

# Collect static files
WORKDIR /app/project
RUN python manage.py collectstatic --noinput

# Expose port 80
EXPOSE 80

# Create a directory for database backups
RUN mkdir -p /app/db_backups

# Create more robust start script with migration verification
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Waiting for database..."' >> /app/start.sh && \
    echo '/wait-for-it.sh db:5432 -t 60' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'cd /app/project' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Listing available migrations before running..."' >> /app/start.sh && \
    echo 'python manage.py showmigrations' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Apply migrations with verbose output' >> /app/start.sh && \
    echo 'echo "Running migrations with verbosity..."' >> /app/start.sh && \
    echo 'python manage.py migrate --noinput -v 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "Verifying migrations were applied..."' >> /app/start.sh && \
    echo 'python manage.py showmigrations' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Create admin user if none exists' >> /app/start.sh && \
    echo 'echo "Ensuring admin user exists..."' >> /app/start.sh && \
    echo 'python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser(\"admin\", \"admin@example.com\", \"adminpassword\") if not User.objects.filter(username=\"admin\").exists() else print(\"Admin user already exists\")"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start gunicorn with longer timeout' >> /app/start.sh && \
    echo 'echo "Starting gunicorn..."' >> /app/start.sh && \
    echo 'gunicorn project.wsgi:application --bind 0.0.0.0:80 --timeout 120' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set the script as the command to run
CMD ["/app/start.sh"]