from django.contrib import admin
from django.urls import path
from django.http import JsonResponse


# Define the hello_world view
def hello_world(request) -> JsonResponse:
    return JsonResponse({"message": "Hello, World!"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", hello_world),  # Add the Hello, World! URL
]
