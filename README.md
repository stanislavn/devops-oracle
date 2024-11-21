# Django template + VPS, Docker, Github actions

Sup bro

## Installation

PART 4: HANDLING MEDIA FILES
Local Directory for Media Files

    Use the MEDIA_ROOT directory (as shown in settings.py) and mount it as a Docker volume in docker-compose.yml:
```
volumes:
      - ./media:/app/media
```
PART 5: BACKUP AUTOMATION
Backup Files and Database

Regular Database Backup: Use pg_dump to periodically backup the PostgreSQL database:
```
# Create a backup script: backup.sh
#!/bin/bash

TIMESTAMP=$(date +"%F")
BACKUP_DIR="/backups"
BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

mkdir -p $BACKUP_DIR
docker exec postgres-container-name pg_dump -U myuser mydb > $BACKUP_FILE
echo "Backup created: $BACKUP_FILE"
```
Automatic Scheduling with Cron: Add a cron job on the VPS:
```
crontab -e
# Add the following line to run the backup script daily at midnight
0 0 * * * /path/to/backup.sh
```
Backup Media Files: Use rsync or tar to back up the media file directory similarly.

PART 6: MANAGEMENT COMMAND USAGE

Run management commands within the Docker container:
```
docker-compose exec web python manage.py test_command
```
