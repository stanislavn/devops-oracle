from django.shortcuts import render
from django.http import HttpResponse
from django.views.decorators.csrf import ensure_csrf_cookie

# Create your views here.


@ensure_csrf_cookie
def test_csrf(request):
    if request.method == "POST":
        return HttpResponse("CSRF test passed!")
    return render(request, "test_csrf.html")
