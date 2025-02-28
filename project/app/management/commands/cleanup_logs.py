import os
import logging
from datetime import datetime, timedelta
from django.core.management.base import BaseCommand
from django.conf import settings

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = "Cleans up old log files and performs database maintenance"

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=7,
            help='Delete log files older than this many days'
        )

    def handle(self, *args, **options):
        days = options['days']
        log_dir = os.path.join(settings.BASE_DIR, 'logs')
        self.stdout.write(f"Cleaning up log files older than {days} days in {log_dir}")
        
        if not os.path.exists(log_dir):
            self.stdout.write(self.style.WARNING(f"Log directory {log_dir} does not exist"))
            return
            
        count = 0
        now = datetime.now()
        cutoff = now - timedelta(days=days)
        
        for filename in os.listdir(log_dir):
            if not filename.endswith('.log'):
                continue
                
            filepath = os.path.join(log_dir, filename)
            file_time = datetime.fromtimestamp(os.path.getmtime(filepath))
            
            if file_time < cutoff:
                try:
                    os.remove(filepath)
                    count += 1
                    self.stdout.write(f"Deleted {filepath}")
                except Exception as e:
                    self.stderr.write(f"Error deleting {filepath}: {e}")
        
        # Log the results
        logger.info(f"Cleanup completed: removed {count} log files older than {days} days")
        self.stdout.write(self.style.SUCCESS(f"Successfully removed {count} old log files"))
