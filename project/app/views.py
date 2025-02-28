from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import ensure_csrf_cookie
from django.middleware.csrf import get_token

# Create your views here.


@ensure_csrf_cookie
def test_csrf(request):
    if request.method == "POST":
        return HttpResponse("CSRF test passed!")
    return render(request, "test_csrf.html")


@ensure_csrf_cookie
def csrf_debug(request):
    """View to debug CSRF token issues"""
    token = get_token(request)
    headers = {k: v for k, v in request.META.items() if k.startswith("HTTP_")}

    return JsonResponse(
        {
            "csrfToken": token,
            "method": request.method,
            "secure": request.is_secure(),
            "headers": headers,
            "cookies": request.COOKIES,
        }
    )


def csrf_failure(request, reason=""):
    context = {
        "reason": reason,
        "headers": {k: v for k, v in request.META.items() if k.startswith("HTTP_")},
        "is_secure": request.is_secure(),
        "path": request.path,
    }
    return render(request, "csrf_failure.html", context)
