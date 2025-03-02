import logging
import subprocess
from celery import shared_task
from django.core.management import call_command

logger = logging.getLogger(__name__)


@shared_task(bind=True)
def run_management_command(self, command_name, *args, **kwargs):
    """
    Generic task to run any Django management command.

    Args:
        command_name (str): Name of the management command to run
        *args: Positional arguments for the command
        **kwargs: Keyword arguments for the command

    Returns:
        dict: Result information about the command execution
    """
    logger.info(
        f"Running management command: {command_name} with args={args} kwargs={kwargs}"
    )

    try:
        # Call the management command
        output = call_command(command_name, *args, **kwargs)
        logger.info(f"Command {command_name} completed successfully")
        return {
            "status": "success",
            "command": command_name,
            "args": args,
            "kwargs": kwargs,
            "output": str(output) if output else "Command executed successfully",
        }
    except Exception as e:
        logger.error(f"Error running command {command_name}: {str(e)}")
        return {
            "status": "error",
            "command": command_name,
            "args": args,
            "kwargs": kwargs,
            "error": str(e),
        }


# Example predefined tasks for specific commands
@shared_task(bind=True)
def cleanup_logs(self):
    """Task to run the cleanup_logs management command"""
    return run_management_command("cleanup_logs")


@shared_task(bind=True)
def clearsessions(self):
    """Task to clear expired sessions"""
    return run_management_command("clearsessions")


@shared_task(bind=True)
def collect_static(self):
    """Task to collect static files"""
    return run_management_command("collectstatic", "--noinput")
