from django.contrib import admin
from django.core.management import call_command
from django.contrib import messages
from .models import DummyModel  # Import the dummy model


class DummyModelAdmin(admin.ModelAdmin):
    actions = ["run_my_command"]

    def run_my_command(self, request, queryset):
        try:
            call_command("mytest_command")
            self.message_user(
                request, "Command executed successfully!", level=messages.SUCCESS
            )
        except Exception as e:
            self.message_user(request, f"Error: {str(e)}", level=messages.ERROR)

    run_my_command.short_description = "Run test management command"


admin.site.register(DummyModel, DummyModelAdmin)
