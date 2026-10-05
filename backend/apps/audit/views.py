from rest_framework import generics, permissions
from apps.core.permissions import IsAdminUserOnly
from .models import AuditLog
from .serializers import AuditLogSerializer

class AuditLogListView(generics.ListAPIView):
    """
    Read-only append-only audit log endpoint for Admins.
    """
    queryset = AuditLog.objects.select_related('actor').all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUserOnly]
    filterset_fields = ['event_type', 'target_model']
    search_fields = ['actor__employee_code', 'actor__email', 'target_id', 'ip_address']
    ordering_fields = ['created_at']


class AuditLogDetailView(generics.RetrieveAPIView):
    queryset = AuditLog.objects.select_related('actor').all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUserOnly]
