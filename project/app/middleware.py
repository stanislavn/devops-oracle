import logging
from django.conf import settings

logger = logging.getLogger("django.request")


class CSRFDebugMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        # Log details if it's a CSRF failure
        if response.status_code == 403 and "CSRF" in getattr(
            response, "content", b""
        ).decode("utf-8", errors="ignore"):
            logger.warning(
                f"CSRF Failure detected for: {request.path}\n"
                f"Method: {request.method}\n"
                f"Is secure: {request.is_secure()}\n"
                f"Headers: {', '.join(f'{k}: {v}' for k, v in request.META.items() if k.startswith('HTTP_'))}"
            )

        return response


class FixedSecureProxyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Force is_secure() to return True when appropriate headers are present
        if (
            "HTTP_X_FORWARDED_PROTO" in request.META
            and request.META["HTTP_X_FORWARDED_PROTO"] == "https"
        ):
            request.is_secure = lambda: True

        return self.get_response(request)
