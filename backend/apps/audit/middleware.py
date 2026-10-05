import json
from django.utils.deprecation import MiddlewareMixin
from .models import AuditLog

class AuditLogMiddleware(MiddlewareMixin):
    """
    Middleware attaching request context to thread local or auditing critical administrative actions.
    """
    def process_response(self, request, response):
        return response
