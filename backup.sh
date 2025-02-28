#!/bin/bash

# Environment variables are loaded from .env.prod via docker-compose

# Variables
BACKUP_DIR="/backups"
DB_HOST="db"  # use service name from docker-compose
DATE=$(date +%Y%m%d-%H%M%S)
MEDIA_DIR="/app/media"  # path inside container
REMOTE_NAME="nextcloud"
REMOTE_DIR="backups"

# Ensure backup directory exists
echo "Ensuring backup directory exists..."
mkdir -p $BACKUP_DIR
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Unable to create backup directory: $BACKUP_DIR"
    exit 1
fi

# Step 1: Backup Database
echo "Backing up database..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h $DB_HOST -U $POSTGRES_USER $POSTGRES_DB | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

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