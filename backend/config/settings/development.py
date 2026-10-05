import os
from .base import *

DEBUG = True

# Database connection: Defaults to SQLite in local development unless DB_ENGINE=postgresql
if os.getenv('DB_ENGINE') != 'postgresql':
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
else:
    try:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.postgresql',
                'NAME': os.getenv('DB_NAME', 'pcrm_db'),
                'USER': os.getenv('DB_USER', 'pcrm_user'),
                'PASSWORD': os.getenv('DB_PASSWORD', 'pcrm_secure_password_123!'),
                'HOST': os.getenv('DB_HOST', 'localhost'),
                'PORT': os.getenv('DB_PORT', '5432'),
                'CONN_MAX_AGE': 60,
            }
        }
    except Exception:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }

# Cache: Redis if available, else local memory cache
if os.getenv('REDIS_URL'):
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': os.getenv('REDIS_URL', 'redis://127.0.0.1:6379/1'),
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            }
        }
    }
else:
    CACHES = {
        'default': {
            'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
            'LOCATION': 'unique-snowflake',
        }
    }

# In dev, output emails to console
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Relax password validators in dev to allow common test passwords
AUTH_PASSWORD_VALIDATORS = []

