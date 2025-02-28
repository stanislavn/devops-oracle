import os
import importlib
from django.core.management.base import BaseCommand
from app.models import ManagementCommand
from django.core.management import get_commands

class Command(BaseCommand):
    help = "Registers all available management commands"

    def handle(self, *args, **options):
        # Get all available commands
        command_dict = get_commands()
        
        # Track commands we've processed
        processed_commands = set()
        
        for app_name, command_name in command_dict.items():
            if command_name in processed_commands:
                continue
                
            # Skip some built-in commands we don't want to expose
            if command_name in ['shell', 'dbshell', 'register_commands']:
                continue
                
            processed_commands.add(command_name)
            
            # Get the command description if possible
            description = ""
            try:
                if app_name == 'app':
                    module_path = f"app.management.commands.{command_name}"
                else:
                    module_path = f"django.core.management.commands.{command_name}"
                    
                module = importlib.import_module(module_path)
                command_class = module.Command
                description = getattr(command_class, 'help', '')
            except (ImportError, AttributeError):
                description = f"Command from {app_name}"
            
            # Create or update the command entry
            obj, created = ManagementCommand.objects.update_or_create(
                name=command_name,
                defaults={'description': description}
            )
            
            action = "Created" if created else "Updated"
            self.stdout.write(f"{action} command: {command_name}")
            
        self.stdout.write(self.style.SUCCESS(f"Registered {len(processed_commands)} commands"))
