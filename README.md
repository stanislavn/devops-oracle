# Django template + VPS, Docker, Github actions

Sup bro

## Installation

## Backup
```
apt-get install postgresql-client tar gzip rclone

rclone config
```

backup.sh
```
#!/bin/bash

# Environment Variables (Load from .env.prod)
set -a                             # Auto-export variables
source /home/ubuntu/django-app/devops-oracle/.env.prod  # Update this path to your .env.prod file
set +a                             # Disable auto-export

# Variables
BACKUP_DIR="/home/ubuntu/backups"          # Full path for local backups
DB_CONTAINER="devops-oracle_db_1"         # Correct name of your PostgreSQL container
DATE=$(date +%Y%m%d-%H%M%S)               # Timestamp for unique filenames
MEDIA_DIR="/home/ubuntu/django-app/devops-oracle/media"  # Correct media folder path
REMOTE_NAME="nextcloud"                   # Rclone remote name for Nextcloud
REMOTE_DIR="backups"                      # Remote directory in Nextcloud

# Ensure backup directory exists
echo "Ensuring backup directory exists..."
mkdir -p $BACKUP_DIR
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Unable to create backup directory: $BACKUP_DIR"
    exit 1
fi

# Step 1: Backup Database
echo "Backing up database..."
docker exec $DB_CONTAINER sh -c "PGPASSWORD=$POSTGRES_PASSWORD pg_dump -U $POSTGRES_USER $POSTGRES_DB" | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

if [ $? -eq 0 ]; then
    echo "Database backup successful: $BACKUP_DIR/db_backup_$DATE.sql.gz"
else
    echo "Database backup failed!"
    exit 1
fi

# Step 2: Backup Media Files
echo "Backing up media files..."
tar -czf $BACKUP_DIR/media_backup_$DATE.tar.gz -C $(dirname $MEDIA_DIR) $(basename $MEDIA_DIR)

if [ $? -eq 0 ]; then
    echo "Media backup successful: $BACKUP_DIR/media_backup_$DATE.tar.gz"
else
    echo "Media backup failed!"
    exit 1
fi

# Step 3: Upload to Nextcloud
echo "Uploading backups to Nextcloud..."
rclone copy $BACKUP_DIR $REMOTE_NAME:$REMOTE_DIR

if [ $? -eq 0 ]; then
    echo "Upload to Nextcloud successful!"
else
    echo "Upload to Nextcloud failed!"
    exit 1
fi

# Step 4: Cleanup old local backups (retain only the last 7 days)
echo "Cleaning up old local backups..."
find $BACKUP_DIR -type f -mtime +7 -exec rm {} \;

echo "Backup completed successfully."
```
```
chmod +x /path/to/backup.sh
crontab -e
0 2 * * * /path/to/backup.sh >> /path/to/backup.log 2>&1
crontab -l
```
To restore:
```
gunzip -c /path/to/db_backup_TIMESTAMP.sql.gz | docker exec -i db psql -U myuser -d mydb
```
Restore media
```
tar -xzf /path/to/media_backup_TIMESTAMP.tar.gz -C /path/to/restore/location
```


## sdsdsd

PART 6: MANAGEMENT COMMAND USAGE

Run management commands within the Docker container:
```
docker-compose exec web python manage.py test_command
```
## Rebuild
```
docker-compose build && docker-compose up -d --force-recreate
```

## Access docker container

docker-compose exec web bash
