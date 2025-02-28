# Dockerfile.cron
FROM python:3.12.4-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Working directory
WORKDIR /app

# Install necessary tools for backup tasks
RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    postgresql-client \
    tar \
    gzip \
    rclone \
    gettext-base \  # For envsubst command
    && rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Copy application code and install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy backup script and make it executable
COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

# Copy rclone configuration template
COPY rclone.conf.template /root/.config/rclone/rclone.conf.template

# Copy rclone setup script
COPY setup-rclone.sh /setup-rclone.sh
RUN chmod +x /setup-rclone.sh

# Create crontab file
RUN echo "0 2 * * * /app/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron
RUN crontab /etc/cron.d/backup-cron

# Create log file
RUN touch /var/log/cron.log

# Copy the entire codebase (if needed for Django management commands)
COPY . /app/

# Run setup-rclone script to configure rclone, then start cron in foreground
CMD ["/bin/bash", "-c", "/setup-rclone.sh && cron -f"]