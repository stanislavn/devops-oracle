from django.contrib import admin
from django.core.management import call_command
from django.contrib import messages
from django.utils import timezone
from io import StringIO
import sys
from django.urls import path
from django.shortcuts import render, redirect
from django.template.response import TemplateResponse
from django.views.decorators.csrf import csrf_protect
from django.utils.decorators import method_decorator
from .models import DummyModel, ManagementCommand


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


@admin.register(ManagementCommand)
class ManagementCommandAdmin(admin.ModelAdmin):
    list_display = ["name", "description", "last_run", "success"]
    readonly_fields = ["name", "description", "last_run", "success", "output"]
    search_fields = ["name", "description"]
    actions = ["run_selected_commands"]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def run_selected_commands(self, request, queryset):
        for command in queryset:
            self.run_command(request, command.name)

    run_selected_commands.short_description = "Run selected commands"

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                "run/<str:command_name>/",
                self.admin_site.admin_view(self.run_command_view),
                name="run-management-command",
            ),
        ]
        return custom_urls + urls

    @method_decorator(csrf_protect)
    def run_command_view(self, request, command_name):
        if request.method == "POST":
            return self.run_command(request, command_name)
        else:
            # Render confirmation form
            command = ManagementCommand.objects.get(name=command_name)
            context = {
                "title": f"Run management command: {command_name}",
                "command": command,
                "opts": self.model._meta,
                "app_label": self.model._meta.app_label,
                "original": command,
                "is_popup": False,
                "save_as": False,
                "has_delete_permission": False,
                "has_add_permission": False,
                "has_change_permission": True,
            }
            return TemplateResponse(
                request, "admin/app/managementcommand/run_confirmation.html", context
            )

    def run_command(self, request, command_name):
        command = ManagementCommand.objects.get(name=command_name)

        # Capture command output
        old_stdout, old_stderr = sys.stdout, sys.stderr
        stdout_buffer = StringIO()
        stderr_buffer = StringIO()
        sys.stdout, sys.stderr = stdout_buffer, stderr_buffer

        try:
            call_command(command_name)
            output = stdout_buffer.getvalue()
            success = True
            self.message_user(
                request,
                f"Command '{command_name}' executed successfully!",
                level=messages.SUCCESS,
            )
        except Exception as e:
            output = f"Error: {str(e)}\n{stderr_buffer.getvalue()}"
            success = False
            self.message_user(
                request,
                f"Error running '{command_name}': {str(e)}",
                level=messages.ERROR,
            )
        finally:
            sys.stdout, sys.stderr = old_stdout, old_stderr

        # Update command record
        command.last_run = timezone.now()
        command.success = success
        command.output = output
        command.save()

        return redirect("admin:app_managementcommand_changelist")


admin.site.register(DummyModel, DummyModelAdmin)
