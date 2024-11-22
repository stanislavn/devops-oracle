# Dockerfile

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

# Copy entire repository into the container
COPY . /app/

# Change directory to the correct location of manage.py before running commands
WORKDIR /app/project

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose port 80 (required for Gunicorn to listen on this port)
EXPOSE 80

# Start the application using Gunicorn
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:80"]