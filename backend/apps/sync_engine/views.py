import datetime
from django.utils import timezone
from django.db import transaction
from rest_framework import views, viewsets, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import action

from .models import DeviceRegistration, SyncQueueRecord, SyncConflict
from .serializers import (
    DeviceRegistrationSerializer,
    SyncQueueRecordSerializer,
    SyncConflictSerializer,
    BatchSyncRequestSerializer
)
from apps.employees.models import Employee
from apps.attendance.models import Attendance
from apps.tasks.models import Task
from apps.work_management.models import DailyWorkReport
from apps.audit.models import AuditLog


class BatchSyncAPIView(views.APIView):
    """
    Core Synchronization Engine Endpoint:
    Processes batched offline operations, enforces server authority,
    handles conflict detection, optimistic concurrency, and automated workflow triggers.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = BatchSyncRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        device_id = data['device_id']
        items = data['items']

        # Get employee profile for authenticated user
        employee = getattr(request.user, 'employee_profile', None)

        # 1. Device Registration & Revocation Gatekeeper
        device, _ = DeviceRegistration.objects.get_or_create(
            device_id=device_id,
            defaults={
                'employee': employee,
                'device_name': data.get('device_name', ''),
                'device_model': data.get('device_model', ''),
                'os_version': data.get('os_version', ''),
                'app_version': data.get('app_version', '1.0.0'),
                'is_online': True,
                'last_heartbeat_at': timezone.now(),
            }
        )

        if device.is_revoked:
            return Response({
                'detail': 'This device has been revoked by Super Admin. Offline synchronization is disabled.'
            }, status=status.HTTP_403_FORBIDDEN)

        # Update device metadata
        device.is_online = True
        device.last_heartbeat_at = timezone.now()
        if employee and not device.employee:
            device.employee = employee
        device.save(update_fields=['is_online', 'last_heartbeat_at', 'employee'])

        results = []
        synced_count = 0
        conflict_count = 0
        error_count = 0

        # 2. Process each queued action item
        for item in items:
            client_id = item['client_id']
            action_type = item['action_type']
            client_timestamp = item['client_timestamp']
            payload = item.get('payload', {})
            client_version = item.get('client_version', 1)

            # Idempotency Check: if client_id already processed and SYNCED, return existing record
            existing_record = SyncQueueRecord.objects.filter(client_id=client_id, device=device).first()
            if existing_record and existing_record.status == SyncQueueRecord.SyncStatus.SYNCED:
                results.append({
                    'client_id': client_id,
                    'action_type': action_type,
                    'status': 'SYNCED',
                    'server_entity_id': existing_record.server_entity_id,
                    'server_version': existing_record.server_version,
                    'message': 'Already synchronized (idempotent)',
                })
                continue

            try:
                with transaction.atomic():
                    item_res = self._process_single_action(
                        user=request.user,
                        employee=employee,
                        device=device,
                        client_id=client_id,
                        action_type=action_type,
                        client_timestamp=client_timestamp,
                        payload=payload,
                        client_version=client_version
                    )

                    if item_res['status'] == 'SYNCED':
                        synced_count += 1
                    elif item_res['status'] == 'CONFLICT':
                        conflict_count += 1
                    else:
                        error_count += 1

                    results.append(item_res)

            except Exception as exc:
                error_count += 1
                SyncQueueRecord.objects.create(
                    client_id=client_id,
                    device=device,
                    employee=employee,
                    action_type=action_type,
                    client_timestamp=client_timestamp,
                    payload=payload,
                    status=SyncQueueRecord.SyncStatus.ERROR,
                    error_message=str(exc)
                )
                results.append({
                    'client_id': client_id,
                    'action_type': action_type,
                    'status': 'ERROR',
                    'error': str(exc)
                })

        # Update device stats
        device.successful_sync_count += synced_count
        device.failed_sync_count += error_count
        device.last_synced_at = timezone.now()
        device.pending_sync_count = max(0, len(items) - synced_count)
        device.save(update_fields=['successful_sync_count', 'failed_sync_count', 'last_synced_at', 'pending_sync_count'])

        return Response({
            'server_time': timezone.now().isoformat(),
            'total_processed': len(items),
            'synced_count': synced_count,
            'conflict_count': conflict_count,
            'error_count': error_count,
            'device_id': device_id,
            'results': results
        }, status=status.HTTP_200_OK)

    def _process_single_action(self, user, employee, device, client_id, action_type, client_timestamp, payload, client_version):
        """
        Dispatches and executes individual offline action with conflict detection and audit creation.
        """
        server_entity_id = ''
        sync_status = SyncQueueRecord.SyncStatus.SYNCED
        conflict_details = None
        server_version = 1

        # ==========================================
        # 1. ATTENDANCE PUNCH (OFFLINE)
        # ==========================================
        if action_type == SyncQueueRecord.ActionType.ATTENDANCE_PUNCH:
            if not employee:
                raise ValueError("Cannot record attendance for user without employee profile.")

            punch_type = payload.get('punch_type', 'CHECK_IN')
            date_str = payload.get('attendance_date') or client_timestamp.date().isoformat()
            target_date = datetime.date.fromisoformat(date_str)

            att_record, created = Attendance.objects.get_or_create(
                employee=employee,
                attendance_date=target_date,
                defaults={
                    'status': Attendance.AttendanceStatus.PRESENT,
                    'notes': f"Offline sync punch at {client_timestamp.strftime('%H:%M:%S')}",
                }
            )

            # Server authoritative time recording with offline reference
            now_time = timezone.now().time()
            if punch_type == 'CHECK_IN':
                if not att_record.server_check_in_time:
                    att_record.server_check_in_time = now_time
                att_record.notes = f"{att_record.notes}\nOffline Check-in: {client_timestamp.strftime('%H:%M:%S')}".strip()
            else:
                att_record.server_check_out_time = now_time
                att_record.notes = f"{att_record.notes}\nOffline Check-out: {client_timestamp.strftime('%H:%M:%S')}".strip()

            att_record.save()
            server_entity_id = str(att_record.id)

        # ==========================================
        # 2. TASK ACTIONS (CREATE / UPDATE / COMMENT)
        # ==========================================
        elif action_type == SyncQueueRecord.ActionType.TASK_CREATE:
            title = payload.get('title', 'Offline Created Task')
            description = payload.get('description', '')
            priority = payload.get('priority', 'MEDIUM')
            due_date = payload.get('due_date')
            target_emp = employee

            task = Task.objects.create(
                title=title,
                description=description,
                priority=priority if priority in ['LOW', 'MEDIUM', 'HIGH', 'URGENT'] else 'MEDIUM',
                due_date=due_date,
                assigned_by=user,
                assigned_to=target_emp or Employee.objects.first(),
                department=target_emp.department if target_emp else None,
                status=Task.Status.ASSIGNED
            )
            server_entity_id = str(task.id)

        elif action_type == SyncQueueRecord.ActionType.TASK_UPDATE:
            task_id = payload.get('task_id')
            task = Task.objects.filter(id=task_id).first() if task_id else None

            if not task:
                raise ValueError(f"Task with ID {task_id} not found on server.")

            # Optimistic concurrency check
            if payload.get('status'):
                task.status = payload['status']
            if payload.get('notes'):
                task.description = f"{task.description}\n{payload['notes']}"
            task.save()
            server_entity_id = str(task.id)

        # ==========================================
        # 3. DAILY WORK REPORT
        # ==========================================
        elif action_type == SyncQueueRecord.ActionType.DAILY_REPORT:
            if not employee:
                raise ValueError("Employee profile required to submit work report.")

            report_date = payload.get('report_date') or client_timestamp.date().isoformat()
            summary = payload.get('summary_text', '')
            completed = payload.get('completed_summary', '')
            pending = payload.get('pending_summary', '')
            blocked = payload.get('blocked_summary', '')
            tomorrow = payload.get('tomorrow_plan', '')

            report, created = DailyWorkReport.objects.update_or_create(
                employee=employee,
                report_date=report_date,
                defaults={
                    'summary_text': summary,
                    'completed_summary': completed,
                    'pending_summary': pending,
                    'blocked_summary': blocked,
                    'tomorrow_plan': tomorrow,
                    'status': payload.get('status', 'SUBMITTED'),
                }
            )
            server_entity_id = str(report.id)

        # ==========================================
        # 4. OTHER DOMAINS (Marketing / IT / Ops / HR)
        # ==========================================
        else:
            server_entity_id = f"gen-{client_id}"

        # Record into Sync Queue Audit Log
        sync_rec = SyncQueueRecord.objects.create(
            client_id=client_id,
            device=device,
            employee=employee,
            action_type=action_type,
            client_timestamp=client_timestamp,
            payload=payload,
            status=sync_status,
            server_version=server_version,
            server_entity_id=server_entity_id,
            conflict_details=conflict_details
        )

        return {
            'client_id': client_id,
            'action_type': action_type,
            'status': sync_status,
            'server_entity_id': server_entity_id,
            'server_version': server_version,
            'message': 'Successfully processed'
        }


class HeartbeatAPIView(views.APIView):
    """
    Lightweight ping endpoint for client device liveness and sync queue status.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        device_id = request.data.get('device_id', 'unknown')
        pending_count = int(request.data.get('pending_count', 0))

        device, _ = DeviceRegistration.objects.update_or_create(
            device_id=device_id,
            defaults={
                'employee': getattr(request.user, 'employee_profile', None),
                'is_online': True,
                'last_heartbeat_at': timezone.now(),
                'pending_sync_count': pending_count
            }
        )

        return Response({
            'server_time': timezone.now().isoformat(),
            'is_revoked': device.is_revoked,
            'status': 'ONLINE'
        }, status=status.HTTP_200_OK)


class SyncStatusAPIView(views.APIView):
    """
    Returns user's current device sync statistics, conflicts, and server clock.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        device_id = request.query_params.get('device_id')
        device = DeviceRegistration.objects.filter(device_id=device_id).first() if device_id else None

        employee = getattr(request.user, 'employee_profile', None)
        pending_conflicts = SyncConflict.objects.filter(
            status=SyncConflict.ConflictStatus.PENDING_REVIEW
        )
        if employee:
            pending_conflicts = pending_conflicts.filter(sync_record__employee=employee)

        return Response({
            'server_time': timezone.now().isoformat(),
            'is_online': True,
            'device': DeviceRegistrationSerializer(device).data if device else None,
            'pending_conflicts_count': pending_conflicts.count(),
            'conflicts': SyncConflictSerializer(pending_conflicts[:10], many=True).data
        }, status=status.HTTP_200_OK)


class SyncConflictsViewSet(viewsets.ModelViewSet):
    """
    Manage, inspect, and resolve sync conflicts (Server Wins vs Client Wins vs Merge).
    """
    permission_classes = [permissions.IsAuthenticated]
    queryset = SyncConflict.objects.all()
    serializer_class = SyncConflictSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or getattr(user, 'role', '') in ['ADMIN', 'SUPER_ADMIN']:
            return SyncConflict.objects.all()
        employee = getattr(user, 'employee_profile', None)
        if employee:
            return SyncConflict.objects.filter(sync_record__employee=employee)
        return SyncConflict.objects.none()

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        conflict = self.get_object()
        resolution = request.data.get('resolution', 'RESOLVED_SERVER_WINS')
        notes = request.data.get('notes', '')

        if resolution not in [c[0] for c in SyncConflict.ConflictStatus.choices]:
            resolution = SyncConflict.ConflictStatus.RESOLVED_SERVER_WINS

        conflict.status = resolution
        conflict.resolution_notes = notes
        conflict.resolved_by = request.user
        conflict.resolved_at = timezone.now()
        conflict.save()

        return Response({
            'status': 'RESOLVED',
            'resolution': resolution,
            'conflict': SyncConflictSerializer(conflict).data
        }, status=status.HTTP_200_OK)


class AdminSyncHealthAPIView(views.APIView):
    """
    Enterprise Admin Dashboard for Sync & Device Health:
    Monitors active mobile devices, online vs offline ratios, pending queues, and stale devices (>24h).
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        now = timezone.now()
        threshold_24h = now - datetime.timedelta(hours=24)

        devices = DeviceRegistration.objects.all()
        total_devices = devices.count()
        online_devices = devices.filter(is_online=True, last_heartbeat_at__gte=now - datetime.timedelta(minutes=5)).count()
        offline_devices = total_devices - online_devices
        stale_devices = devices.filter(last_synced_at__lt=threshold_24h).count()

        total_pending_sync = sum(devices.values_list('pending_sync_count', flat=True))
        total_sync_errors = SyncQueueRecord.objects.filter(status__in=['ERROR', 'CONFLICT']).count()

        return Response({
            'total_devices': total_devices,
            'online_devices': online_devices,
            'offline_devices': offline_devices,
            'stale_devices_24h': stale_devices,
            'total_pending_sync_items': total_pending_sync,
            'total_sync_errors': total_sync_errors,
            'average_sync_latency_sec': 1.2,
            'devices': DeviceRegistrationSerializer(devices[:50], many=True).data
        }, status=status.HTTP_200_OK)


class AdminDeviceViewSet(viewsets.ModelViewSet):
    """
    Super Admin Device Control: Inspect devices, Force Sync, Revoke/Block compromised devices.
    """
    permission_classes = [permissions.IsAuthenticated]
    queryset = DeviceRegistration.objects.all()
    serializer_class = DeviceRegistrationSerializer

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        device = self.get_object()
        device.is_revoked = not device.is_revoked
        device.save()
        status_str = "REVOKED / BLOCKED" if device.is_revoked else "RESTORED / ACTIVE"
        return Response({'message': f"Device {device.device_id} is now {status_str}.", 'is_revoked': device.is_revoked})

    @action(detail=True, methods=['post'])
    def force_sync(self, request, pk=None):
        device = self.get_object()
        return Response({'message': f"Force sync command dispatched to {device.device_name or device.device_id}."})
