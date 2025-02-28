"""
Django settings for project project.

Generated by 'django-admin startproject' using Django 5.1.3.

For more information on this file, see
https://docs.djangoproject.com/en/5.1/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/5.1/ref/settings/
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/5.1/howto/deployment/checklist/

DEBUG = os.getenv("DEBUG", "False") == "True"

SECRET_KEY = os.getenv(
    "SECRET_KEY", "django-insecure-*g1#wak^caj_+!46qrpxd0y$hu%1w@)*k@f1s4tt(goho(3g*0"
)

if DEBUG:
    ALLOWED_HOSTS = ["localhost", "127.0.0.1", "[::1]", "*"]
else:
    ALLOWED_HOSTS = [
        "django.nadzam.sk",
        "www.django.nadzam.sk",
        "*.nadzam.sk",
        "127.0.0.1",
        "152.67.72.228",
        "0.0.0.0",
    ]

# Application definition

INSTALLED_APPS = [
    "whitenoise.runserver_nostatic",
    "django.contrib.staticfiles",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "axes",
    "app",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "axes.middleware.AxesMiddleware",
]

STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}
ROOT_URLCONF = "project.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "project.wsgi.application"


# Database
# https://docs.djangoproject.com/en/5.1/ref/settings/#databases

# Database settings
if os.getenv("ENV") == "PRODUCTION":
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.getenv("POSTGRES_DB", "postgres"),
            "USER": os.getenv("POSTGRES_USER", "postgres"),
            "PASSWORD": os.getenv("POSTGRES_PASSWORD", ""),
            "HOST": os.getenv("POSTGRES_HOST", "db"),
            "PORT": os.getenv("POSTGRES_PORT", "5432"),
        }
    }

    LOGGING = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "verbose": {
                "format": "[%(asctime)s] %(levelname)s %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
        },
        "handlers": {
            "file_info": {  # Handler for general info logs
                "level": "INFO",
                "class": "logging.FileHandler",
                "filename": "/app/logs/django_info.log",
                "formatter": "verbose",
            },
            "file_error": {  # Handler for error logs
                "level": "ERROR",
                "class": "logging.FileHandler",
                "filename": "/app/logs/django_error.log",
                "formatter": "verbose",
            },
            "file_login": {  # Handler for login attempts
                "level": "INFO",
                "class": "logging.FileHandler",
                "filename": "/app/logs/django_login.log",
                "formatter": "verbose",
            },
        },
        "loggers": {
            "django": {  # General Django logs
                "handlers": ["file_info", "file_error"],
                "level": "INFO",
                "propagate": True,
            },
            "django.security.LoginView": {  # Login attempts logs
                "handlers": ["file_login"],
                "level": "INFO",
                "propagate": False,
            },
            "django.request": {  # Capture error logs separately
                "handlers": ["file_error"],
                "level": "ERROR",
                "propagate": False,
            },
        },
        "root": {
            "handlers": ["file_info", "file_error"],
            "level": "INFO",
        },
    }

    # Allow Proxy Headers For HTTPS
    USE_X_FORWARDED_HOST = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

    # Serve cookies securely
    CSRF_COOKIE_SECURE = True  # Ensures CSRF cookies are only sent over HTTPS
    SESSION_COOKIE_SECURE = True  # Makes session cookies only sent over HTTPS

    # Redirect all HTTP traffic to HTTPS
    SECURE_SSL_REDIRECT = True  # Redirect HTTP to HTTPS

    AXES_FAILURE_LIMIT = 5  # Number of attempts before lockout
    AXES_COOLOFF_TIME = 1  # Lockout duration in hours


else:  # Local Development
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }


# Password validation
# https://docs.djangoproject.com/en/5.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.1/topics/i18n/

LANGUAGE_CODE = "sk"
TIME_ZONE = "Europe/Bratislava"

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.1/howto/static-files/

STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(
    BASE_DIR, "staticfiles"
)  # Common practice to use 'staticfiles' for production
STATICFILES_STORAGE = (
    "whitenoise.storage.CompressedManifestStaticFilesStorage"  # Required for whitenoise
)


# Default primary key field type
# https://docs.djangoproject.com/en/5.1/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# MEDIA SETUP
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media/")

AUTHENTICATION_BACKENDS = [
    "axes.backends.AxesStandaloneBackend",  # Add this line
    "django.contrib.auth.backends.ModelBackend",  # Default Django backend
]

# Logging configuration
LOGS_DIR = os.path.join(BASE_DIR, 'logs')
if not os.path.exists(LOGS_DIR):
    os.makedirs(LOGS_DIR)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {asctime} {message}',
            'style': '{',
        },
    },
    'filters': {
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(LOGS_DIR, 'django.log'),
            'maxBytes': 1024*1024*5,  # 5 MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
        'management_commands': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(LOGS_DIR, 'management_commands.log'),
            'maxBytes': 1024*1024*5,  # 5 MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': True,
        },
        'django.request': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False,
        },
        'app.management.commands': {
            'handlers': ['console', 'management_commands'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
