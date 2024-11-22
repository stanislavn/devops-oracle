from django.contrib import admin
from django.urls import path
from django.http import JsonResponse


# Define the hello_world view
def hello_world(request):
    return JsonResponse({"message": "Hello, World!"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("helloworld/", hello_world),  # Add the Hello, World! URL
]
