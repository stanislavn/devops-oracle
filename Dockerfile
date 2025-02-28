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

# Copy wait-for-it script
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

# Copy entire repository into the container
COPY . /app/

# Set up volume for logs
VOLUME /app/logs

# Collect static files
WORKDIR /app/project
RUN python manage.py collectstatic --noinput

# Expose port 80
EXPOSE 80

# Start the application with migrations
CMD /wait-for-it.sh db:5432 -- bash -c "cd /app/project && python manage.py makemigrations && python manage.py migrate && gunicorn project.wsgi:application --bind 0.0.0.0:80"