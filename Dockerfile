# Use official Python image
FROM python:3.12.4-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    python3-dev \
    musl-dev \
    libpq-dev \
    netcat-traditional \
    wait-for-it \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy startup script
COPY start.sh /app/
RUN chmod +x /app/start.sh

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs and backups
VOLUME /app/logs
VOLUME /app/db_backups

# Create a directory for database backups
RUN mkdir -p /app/db_backups

# Expose port 80
EXPOSE 80

# Set the script as the command to run
CMD ["/app/start.sh"]