from django.core.management.base import BaseCommand
from django_celery_beat.models import PeriodicTask, CrontabSchedule, IntervalSchedule
import json
from datetime import datetime


class Command(BaseCommand):
    """
    Management command to set up default periodic tasks.
    Useful for initializing scheduled tasks after deployment.
    """

    help = "Sets up default periodic tasks for common operations"

    def handle(self, *args, **options):
        # Clear sessions every day at midnight
        self.stdout.write("Setting up clearsessions task...")
        crontab, _ = CrontabSchedule.objects.get_or_create(
            minute="0",
            hour="0",
            day_of_week="*",
            day_of_month="*",
            month_of_year="*",
            timezone="UTC",
        )

        PeriodicTask.objects.update_or_create(
            name="Daily Session Cleanup",
            defaults={
                "crontab": crontab,
                "task": "app.tasks.clearsessions",
                "enabled": True,
                "description": "Clears expired sessions daily at midnight",
            },
        )

        # Log cleanup weekly
        self.stdout.write("Setting up log cleanup task...")
        weekly_crontab, _ = CrontabSchedule.objects.get_or_create(
            minute="0",
            hour="1",
            day_of_week="0",  # Sunday
            day_of_month="*",
            month_of_year="*",
            timezone="UTC",
        )

        PeriodicTask.objects.update_or_create(
            name="Weekly Log Cleanup",
            defaults={
                "crontab": weekly_crontab,
                "task": "app.tasks.cleanup_logs",
                "enabled": True,
                "description": "Cleans up logs weekly on Sunday at 1 AM",
            },
        )

        # Database backup daily
        self.stdout.write("Setting up database backup task...")
        backup_crontab, _ = CrontabSchedule.objects.get_or_create(
            minute="0",
            hour="2",
            day_of_week="*",
            day_of_month="*",
            month_of_year="*",
            timezone="UTC",
        )

        # Example of a task with arguments
        PeriodicTask.objects.update_or_create(
            name="Daily Database Backup",
            defaults={
                "crontab": backup_crontab,
                "task": "app.tasks.run_management_command",
                "args": json.dumps(
                    ["dbbackup"]
                ),  # Assuming you have a dbbackup command
                "kwargs": json.dumps({}),
                "enabled": True,
                "description": "Creates database backup daily at 2 AM",
            },
        )

        self.stdout.write(self.style.SUCCESS("Successfully set up periodic tasks"))
