# Django Project Deployment Guide

This Django application is deployed using a modern DevOps pipeline with Docker, GitHub Actions, and a VPS (Virtual Private Server). The deployment is designed to be reliable, maintainable, and secure with automated migrations and database persistence.

## Deployment Architecture

### Key Components

1. **Docker Containers**:
   - **Web**: Django application running with Gunicorn
   - **DB**: PostgreSQL database with persistent volume
   - **Cron**: Container for scheduled tasks (backups, maintenance)

2. **Persistence**:
   - PostgreSQL data stored in an external Docker volume (`postgres_data`)
   - Media files stored in mounted directories

3. **Automation**:
   - GitHub Actions workflow for CI/CD
   - Automatic migrations during deployment

## Deployment Workflow

### 1. Initial Server Setup

```bash
# SSH into your VPS
ssh username@your_server_ip

# Create project directory
mkdir -p /home/ubuntu/django-app
cd /home/ubuntu/django-app

# Clone repository
git clone https://github.com/your-repo/devops-oracle.git
cd devops-oracle

# Set up the database volume
chmod +x init-volume.sh
./init-volume.sh
```

### 2. Environment Configuration

Create an `.env.prod` file with:

```
# Set environment to PRODUCTION to use PostgreSQL
ENV=PRODUCTION

# Database settings
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_HOST=db
POSTGRES_PORT=5432

DEBUG=False
SECRET_KEY=your_secure_secret_key
```

### 3. GitHub Actions Workflow

The CI/CD pipeline in `.github/workflows/deploy.yml` handles:

1. **Code Updates**: Pull the latest code from GitHub
2. **Volume Management**: Ensure PostgreSQL volume exists and is correctly configured
3. **Database Backup**: Create a backup before any changes
4. **Container Rebuild**: Stop, rebuild, and restart containers
5. **Migration Management**: Automatically create and apply migrations
6. **Admin Setup**: Create admin user if it doesn't exist
7. **Monitoring**: Check logs to verify successful deployment

### 4. Database Persistence Logic

The most critical component is database persistence, which is achieved by:

1. **Named External Volume**: Using a consistent, named external volume for PostgreSQL:
   ```yaml
   volumes:
     postgres_data:
       name: postgres_data
       external: true
   ```

2. **Environment Variable**: Setting `ENV=PRODUCTION` in `.env.prod` to ensure PostgreSQL is used.

3. **Settings Configuration**: Django's `settings.py` has conditional logic:
   ```python
   if os.getenv("ENV") == "PRODUCTION":
       # PostgreSQL configuration for production
   else:
       # SQLite for local development
   ```

### 5. Migration Management

Migrations are handled automatically in the `Dockerfile` start script, which:

1. Waits for the database to be ready
2. Lists existing migrations
3. Creates new migrations if needed (`makemigrations`)
4. Applies all migrations (`migrate`)
5. Verifies all migrations were applied
6. Registers management commands
7. Creates an admin user if it doesn't exist

### 6. Backup Strategy

Regular backups are performed via:

1. **Scheduled Backups**: The cron container runs `backup.sh` daily
2. **Pre-Deployment Backups**: The GitHub Actions workflow backs up the database before each deployment
3. **Remote Storage**: Backups are sent to Nextcloud via rclone
4. **Retention Policy**: Automatic cleanup of backups older than 7 days

## Troubleshooting & Maintenance

### Checking Logs

```bash
docker-compose logs web
```

### Manual Database Management

```bash
# Access PostgreSQL CLI
docker-compose exec db psql -U myuser -d mydb

# Create superuser
docker-compose exec web bash -c "cd /app/project && python manage.py createsuperuser"
```

### Volume Management

```bash
# Check volumes
docker volume ls | grep postgres

# Inspect volume
docker inspect postgres_data
```

### Manual Rebuild

```bash
docker-compose build && docker-compose up -d --force-recreate
```

## Important Deployment Considerations

1. **Database Environment**: Always ensure `ENV=PRODUCTION` is set in `.env.prod` to prevent using SQLite in production
2. **Volume Persistence**: Never delete the `postgres_data` volume to avoid data loss
3. **Secrets Management**: Keep credentials secure and never expose them in code
4. **Backup Verification**: Regularly test backup and restore procedures
5. **Migration Testing**: Test migrations locally before deploying to production

## Deployment Checklist

- ✅ Database is configured to use PostgreSQL in production
- ✅ External volume is created and properly referenced
- ✅ Environment variables are correctly set
- ✅ Migrations are automatically created and applied
- ✅ Backup system is functioning
- ✅ Admin user is created automatically

## Backup and Restore

### Setting Up Backups

1. Install required tools:
   ```bash
   apt-get install postgresql-client tar gzip rclone
   ```

2. Configure rclone for Nextcloud:
   ```bash
   rclone config
   ```

3. Use the provided backup script:
   ```bash
   chmod +x backup.sh
   crontab -e
   # Add the following line to run daily at 2 AM:
   0 2 * * * /path/to/backup.sh >> /path/to/backup.log 2>&1
   ```

### Restoring from Backup

To restore the database:
```bash
gunzip -c /path/to/db_backup_TIMESTAMP.sql.gz | docker exec -i db psql -U myuser -d mydb
```

To restore media files:
```bash
tar -xzf /path/to/media_backup_TIMESTAMP.tar.gz -C /path/to/restore/location
```

## Initial Setup

Before running the application for the first time:

1. Create the named volume for the database:
   ```bash
   # Run the initialize script
   chmod +x init-volume.sh
   ./init-volume.sh
   ```

2. Start the application:
   ```bash
   docker-compose up -d
   ```

3. Create a superuser (first time only):
   ```bash
   docker-compose exec web bash -c "cd /app/project && python manage.py createsuperuser"
   ```

## After Deployment

After each deployment:

1. Check logs for successful migrations:
   ```bash
   docker-compose logs web
   ```

2. If needed, manually create a superuser:
   ```bash
   docker-compose exec web bash -c "cd /app/project && python manage.py createsuperuser"
   ```

By following this deployment guide, your Django application will maintain data persistence, apply migrations automatically, and provide a reliable user experience.