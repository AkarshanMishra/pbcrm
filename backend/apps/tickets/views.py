from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import SupportTicket, TicketComment
from .serializers import SupportTicketSerializer, TicketCommentSerializer
from apps.notifications.models import Notification

class SupportTicketViewSet(viewsets.ModelViewSet):
    serializer_class = SupportTicketSerializer
    filterset_fields = ['category', 'priority', 'status', 'target_department']
    search_fields = ['ticket_number', 'title', 'description', 'requester__first_name', 'requester__user__employee_code']
    ordering_fields = ['-created_at', 'priority', 'status']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return SupportTicket.objects.none()
        
        # Admin or Manager sees all or department tickets
        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'OPERATIONS', 'ACCOUNTS']):
            return SupportTicket.objects.select_related('requester__user', 'target_department', 'assigned_technician').prefetch_related('comments__author').all()
        
        # Regular employee sees tickets they raised
        if hasattr(user, 'employee_profile'):
            return SupportTicket.objects.select_related('requester__user', 'target_department', 'assigned_technician').prefetch_related('comments__author').filter(requester=user.employee_profile)
        return SupportTicket.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        emp = getattr(user, 'employee_profile', None)
        ticket = serializer.save(requester=emp)

        # Notify requester
        Notification.send_notification(
            recipient=user,
            title=f"Ticket {ticket.ticket_number} Created",
            message=f"Your request '{ticket.title}' has been submitted.",
            notification_type=Notification.NotificationType.TASK_ASSIGNED,
            link_type='TICKET',
            link_id=ticket.id
        )

    @action(detail=True, methods=['post'], url_path='assign')
    def assign(self, request, pk=None):
        ticket = self.get_object()
        technician_id = request.data.get('technician_id')
        if not technician_id:
            return Response({'error': 'technician_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        ticket.assigned_technician_id = technician_id
        if ticket.status == SupportTicket.Status.OPEN:
            ticket.status = SupportTicket.Status.IN_PROGRESS
        ticket.save()
        return Response({'success': True, 'message': 'Ticket assigned successfully.', 'data': SupportTicketSerializer(ticket).data})

    @action(detail=True, methods=['post'], url_path='resolve')
    def resolve(self, request, pk=None):
        ticket = self.get_object()
        notes = request.data.get('resolution_notes', '')
        ticket.status = SupportTicket.Status.RESOLVED
        ticket.resolution_notes = notes
        ticket.resolved_at = timezone.now()
        ticket.save()

        if ticket.requester and ticket.requester.user:
            Notification.send_notification(
                recipient=ticket.requester.user,
                title=f"Ticket {ticket.ticket_number} Resolved",
                message=f"Your ticket '{ticket.title}' has been marked resolved.",
                notification_type=Notification.NotificationType.TASK_APPROVED,
                link_type='TICKET',
                link_id=ticket.id
            )
        return Response({'success': True, 'message': 'Ticket resolved.', 'data': SupportTicketSerializer(ticket).data})

    @action(detail=True, methods=['post'], url_path='close')
    def close(self, request, pk=None):
        ticket = self.get_object()
        ticket.status = SupportTicket.Status.CLOSED
        ticket.closed_at = timezone.now()
        ticket.save()
        return Response({'success': True, 'message': 'Ticket closed.', 'data': SupportTicketSerializer(ticket).data})

    @action(detail=True, methods=['post'], url_path='comments')
    def add_comment(self, request, pk=None):
        ticket = self.get_object()
        text = request.data.get('comment_text', '').strip()
        if not text:
            return Response({'error': 'comment_text is required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        comment = TicketComment.objects.create(
            ticket=ticket,
            author=request.user,
            comment_text=text
        )
        return Response(TicketCommentSerializer(comment).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='metrics')
    def metrics(self, request):
        qs = self.get_queryset()
        return Response({
            'total': qs.count(),
            'open': qs.filter(status=SupportTicket.Status.OPEN).count(),
            'in_progress': qs.filter(status=SupportTicket.Status.IN_PROGRESS).count(),
            'resolved': qs.filter(status=SupportTicket.Status.RESOLVED).count(),
            'closed': qs.filter(status=SupportTicket.Status.CLOSED).count(),
        })
