# Use official Python image
FROM python:3.12.4-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies for Python
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy entrypoint script
COPY docker-entrypoint.sh /app/
COPY wait-for-it.sh /app/
RUN chmod +x /app/docker-entrypoint.sh /app/wait-for-it.sh

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs
VOLUME /app/logs

# Expose port 80
EXPOSE 80

# Use the entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]