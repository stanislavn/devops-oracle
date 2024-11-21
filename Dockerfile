# Dockerfile
FROM python:3.12.4-slim

# Set working directory
WORKDIR /app

# Install system/build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app code into the container
COPY . .

# Collect static files (if necessary for production)
RUN python manage.py collectstatic --noinput

# Command to start the app
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:8000"]