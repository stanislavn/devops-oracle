# Use official Python image
FROM python:3.12.4-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies for Python
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev postgresql-client

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

# Start the application with database backup and migrations
CMD /wait-for-it.sh db:5432 -- bash -c "\
    echo 'Creating database backup before migrations...' && \
    PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h db -U $POSTGRES_USER $POSTGRES_DB > /app/db_backups/pre_migration_backup_$(date +%Y%m%d_%H%M%S).sql && \
    cd /app/project && \
    python manage.py makemigrations && \
    python manage.py migrate && \
    gunicorn project.wsgi:application --bind 0.0.0.0:80"