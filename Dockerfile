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

# Copy startup script first and ensure it has correct permissions
COPY start.sh /app/
# Make sure the script has unix line endings and is executable
RUN sed -i 's/\r$//' /app/start.sh && \
    chmod +x /app/start.sh

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs and backups
VOLUME /app/logs
VOLUME /app/db_backups

# Create a directory for database backups
RUN mkdir -p /app/db_backups

# Verify the script is executable (extra safety)
RUN ls -la /app/start.sh && \
    chmod 755 /app/start.sh

# Expose port 80
EXPOSE 80

# Set the script as the command to run
CMD ["/bin/bash", "/app/start.sh"]