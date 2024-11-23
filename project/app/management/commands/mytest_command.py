from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "A test management command"

    def handle(self, *args, **kwargs):
        self.stdout.write("Hello from the management command!")
