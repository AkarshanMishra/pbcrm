import os
import mimetypes
from datetime import timedelta
from django.db import transaction
from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from apps.employees.models import Employee
from apps.notifications.models import Notification
from .models import (
    Project,
    Task,
    TaskTimeLog,
    TaskChecklistItem,
    TaskDependency,
    TaskComment,
    TaskAttachment,
    TaskActivityLog,
    TaskTemplate
)
from .serializers import (
    ProjectSerializer,
    TaskTimeLogSerializer,
    TaskListSerializer,
    TaskDetailSerializer,
    TaskCreateSerializer,
    TaskBlockSerializer,
    TaskProgressSerializer,
    TaskReviewSerializer,
    TaskReassignSerializer,
    TaskHandoverSerializer,
    TaskBulkUpdateSerializer,
    TaskChecklistItemSerializer,
    TaskCommentSerializer,
    TaskAttachmentSerializer,
    TaskTemplateSerializer
)

class ProjectViewSet(viewsets.ModelViewSet):
    serializer_class = ProjectSerializer
    filterset_fields = ['status', 'department', 'manager']
    search_fields = ['name', 'code', 'description']
    ordering_fields = ['-created_at', 'due_date', 'progress_percentage']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Project.objects.none()
        
        # Admin / Manager sees all or department projects
        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'MARKETING', 'OPERATIONS', 'ACCOUNTS']):
            return Project.objects.select_related('department', 'manager').prefetch_related('members', 'tasks').all()
        
        if hasattr(user, 'employee_profile'):
            return Project.objects.filter(Q(members=user.employee_profile) | Q(manager=user)).distinct()
        return Project.objects.none()

    def perform_create(self, serializer):
        serializer.save(manager=self.request.user)


class TaskViewSet(viewsets.ModelViewSet):
    filterset_fields = ['department', 'position', 'priority', 'status', 'project', 'is_recurring']
    search_fields = ['title', 'description', 'assigned_to__first_name', 'assigned_to__user__employee_code', 'project__name']
    ordering_fields = ['due_date', 'priority', 'progress_percentage', 'created_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Task.objects.none()

        qs = Task.objects.select_related(
            'department', 'position', 'assigned_to__user', 'assigned_by', 'reviewed_by', 'project'
        ).prefetch_related(
            'checklist_items', 'subtasks', 'time_logs', 'dependencies'
        )

        filter_mode = self.request.query_params.get('filter_mode', 'all')
        today = timezone.localdate()

        if filter_mode == 'today':
            qs = qs.filter(due_date=today)
        elif filter_mode == 'upcoming':
            qs = qs.filter(due_date__gt=today)
        elif filter_mode == 'overdue':
            qs = qs.filter(due_date__lt=today).exclude(status__in=[Task.Status.COMPLETED, Task.Status.CANCELLED])
        elif filter_mode == 'blocked':
            qs = qs.filter(status=Task.Status.BLOCKED)
        elif filter_mode == 'completed':
            qs = qs.filter(status=Task.Status.COMPLETED)

        # RBAC Filtering
        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'MARKETING', 'OPERATIONS', 'ACCOUNTS']):
            assigned_user_id = self.request.query_params.get('assigned_to')
            if assigned_user_id:
                qs = qs.filter(assigned_to_id=assigned_user_id)
            return qs

        if hasattr(user, 'employee_profile'):
            return qs.filter(assigned_to=user.employee_profile)

        return Task.objects.none()

    def get_serializer_class(self):
        if self.action == 'list':
            return TaskListSerializer
        elif self.action in ['retrieve', 'update', 'partial_update']:
            return TaskDetailSerializer
        elif self.action == 'create':
            return TaskCreateSerializer
        return TaskDetailSerializer

    def perform_create(self, serializer):
        task = serializer.save(assigned_by=self.request.user)
        task.log_activity(
            actor=self.request.user,
            action='TASK_CREATED',
            description=f"Task '{task.title}' created and assigned to {task.assigned_to.user.employee_code} ({task.assigned_to.full_name})."
        )
        Notification.send_notification(
            recipient=task.assigned_to.user,
            title=f"New Task Assigned: {task.title}",
            message=f"You have been assigned: '{task.title}' (Priority: {task.priority})",
            notification_type=Notification.NotificationType.TASK_ASSIGNED,
            link_type='TASK',
            link_id=task.id
        )

    # 1. TIME TRACKING: START TIMER
    @action(detail=True, methods=['post'], url_path='start-timer')
    def start_timer(self, request, pk=None):
        task = self.get_object()
        # Check if already running for this user
        active_log = TaskTimeLog.objects.filter(task=task, user=request.user, is_running=True).first()
        if active_log:
            return Response({'message': 'Timer already running for this task.', 'time_log': TaskTimeLogSerializer(active_log).data})

        new_log = TaskTimeLog.objects.create(
            task=task,
            user=request.user,
            start_time=timezone.now(),
            notes=request.data.get('notes', ''),
            is_running=True
        )
        task.is_timer_running = True
        if task.status in [Task.Status.ASSIGNED, Task.Status.ACCEPTED]:
            task.status = Task.Status.IN_PROGRESS
        task.save()
        task.log_activity(actor=request.user, action='TIMER_STARTED', description="Started work session timer.")
        return Response({'success': True, 'time_log': TaskTimeLogSerializer(new_log).data})

    # 2. TIME TRACKING: STOP TIMER
    @action(detail=True, methods=['post'], url_path='stop-timer')
    def stop_timer(self, request, pk=None):
        task = self.get_object()
        active_log = TaskTimeLog.objects.filter(task=task, user=request.user, is_running=True).first()
        if not active_log:
            return Response({'error': 'No active timer found for this task.'}, status=status.HTTP_400_BAD_REQUEST)

        active_log.end_time = timezone.now()
        active_log.is_running = False
        duration = int((active_log.end_time - active_log.start_time).total_seconds() / 60)
        active_log.duration_minutes = max(1, duration)
        active_log.notes = request.data.get('notes', active_log.notes)
        active_log.save()

        # Update actual hours on task
        total_minutes = TaskTimeLog.objects.filter(task=task).aggregate(total=Sum('duration_minutes'))['total'] or 0
        task.actual_hours = round(total_minutes / 60.0, 2)
        task.is_timer_running = TaskTimeLog.objects.filter(task=task, is_running=True).exists()
        task.save()

        task.log_activity(
            actor=request.user,
            action='TIMER_STOPPED',
            description=f"Stopped work timer. Logged {active_log.duration_minutes} minutes. Total actual hours: {task.actual_hours}h."
        )
        return Response({'success': True, 'duration_minutes': active_log.duration_minutes, 'actual_hours': task.actual_hours})

    # 3. TASK CLONING
    @action(detail=True, methods=['post'], url_path='clone')
    def clone_task(self, request, pk=None):
        original = self.get_object()
        cloned = Task.objects.create(
            title=f"Copy of {original.title}",
            description=original.description,
            project=original.project,
            department=original.department,
            position=original.position,
            assigned_to=original.assigned_to,
            assigned_by=request.user,
            priority=original.priority,
            status=Task.Status.ASSIGNED,
            estimated_hours=original.estimated_hours,
            tags=original.tags,
            department_data=original.department_data,
            start_date=timezone.localdate(),
            due_date=timezone.localdate() + timedelta(days=1)
        )
        # Clone checklist items
        for item in original.checklist_items.all():
            TaskChecklistItem.objects.create(task=cloned, item_text=item.item_text, order=item.order)
        
        cloned.log_activity(actor=request.user, action='TASK_CLONED', description=f"Cloned from task '{original.title}'.")
        return Response(TaskDetailSerializer(cloned).data, status=status.HTTP_201_CREATED)

    # 4. TASK REASSIGNMENT
    @action(detail=True, methods=['post'], url_path='reassign')
    def reassign_task(self, request, pk=None):
        task = self.get_object()
        serializer = TaskReassignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_emp = Employee.objects.get(id=serializer.validated_data['new_assignee_id'])
        old_emp_code = task.assigned_to.user.employee_code
        old_emp_name = task.assigned_to.full_name
        reason = serializer.validated_data['reason']

        task.assigned_to = new_emp
        task.status = Task.Status.ASSIGNED
        task.save()

        task.log_activity(
            actor=request.user,
            action='TASK_REASSIGNED',
            description=f"Reassigned from {old_emp_code} ({old_emp_name}) to {new_emp.user.employee_code} ({new_emp.full_name}). Reason: {reason}"
        )
        Notification.send_notification(
            recipient=new_emp.user,
            title="Task Reassigned To You",
            message=f"'{task.title}' reassigned to you by {request.user.get_full_name() or request.user.employee_code}. Reason: {reason}",
            notification_type=Notification.NotificationType.TASK_ASSIGNED,
            link_type='TASK',
            link_id=task.id
        )
        return Response({'success': True, 'message': f'Task reassigned to {new_emp.full_name}.', 'task': TaskDetailSerializer(task).data})

    # 5. WORK HANDOVER (Bulk handover when employee goes on leave)
    @action(detail=False, methods=['post'], url_path='handover')
    def bulk_handover(self, request):
        serializer = TaskHandoverSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from_emp = Employee.objects.get(id=serializer.validated_data['from_employee_id'])
        to_emp = Employee.objects.get(id=serializer.validated_data['to_employee_id'])
        task_ids = serializer.validated_data.get('task_ids')
        notes = serializer.validated_data['handover_notes']

        qs = Task.objects.filter(assigned_to=from_emp).exclude(status__in=[Task.Status.COMPLETED, Task.Status.CANCELLED])
        if task_ids:
            qs = qs.filter(id__in=task_ids)

        transferred_count = 0
        for task in qs:
            task.assigned_to = to_emp
            task.status = Task.Status.ASSIGNED
            task.save()
            task.log_activity(
                actor=request.user,
                action='WORK_HANDOVER',
                description=f"Handed over from {from_emp.full_name} to {to_emp.full_name}. Handover Notes: {notes}"
            )
            transferred_count += 1

        Notification.send_notification(
            recipient=to_emp.user,
            title=f"Work Handover: {transferred_count} Tasks Assigned",
            message=f"You received {transferred_count} task(s) in handover from {from_emp.full_name}. Notes: {notes}",
            notification_type=Notification.NotificationType.TASK_ASSIGNED,
            link_type='TASK'
        )
        return Response({'success': True, 'transferred_count': transferred_count, 'message': f'Successfully handed over {transferred_count} task(s) to {to_emp.full_name}.'})

    # 6. BULK OPERATIONS
    @action(detail=False, methods=['post'], url_path='bulk-update')
    def bulk_update(self, request):
        serializer = TaskBulkUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        task_ids = serializer.validated_data['task_ids']
        new_status = serializer.validated_data.get('status')
        new_priority = serializer.validated_data.get('priority')
        new_assignee_id = serializer.validated_data.get('assigned_to_id')

        qs = Task.objects.filter(id__in=task_ids)
        updated_count = 0
        for task in qs:
            if new_status:
                task.status = new_status
            if new_priority:
                task.priority = new_priority
            if new_assignee_id:
                task.assigned_to_id = new_assignee_id
            task.save()
            task.log_activity(actor=request.user, action='BULK_UPDATE', description="Task updated via bulk action.")
            updated_count += 1

        return Response({'success': True, 'updated_count': updated_count})

    # 7. KANBAN BOARD VIEW
    @action(detail=False, methods=['get'], url_path='kanban')
    def kanban(self, request):
        qs = self.get_queryset()
        dept = request.query_params.get('department')
        prj = request.query_params.get('project')
        if dept:
            qs = qs.filter(department_id=dept)
        if prj:
            qs = qs.filter(project_id=prj)

        todo = qs.filter(status__in=[Task.Status.ASSIGNED, Task.Status.ACCEPTED])
        in_progress = qs.filter(status=Task.Status.IN_PROGRESS)
        blocked = qs.filter(status=Task.Status.BLOCKED)
        review = qs.filter(status__in=[Task.Status.SUBMITTED, Task.Status.UNDER_REVIEW])
        completed = qs.filter(status=Task.Status.COMPLETED)

        return Response({
            'todo': TaskListSerializer(todo, many=True).data,
            'in_progress': TaskListSerializer(in_progress, many=True).data,
            'blocked': TaskListSerializer(blocked, many=True).data,
            'review': TaskListSerializer(review, many=True).data,
            'completed': TaskListSerializer(completed, many=True).data,
        })

    # 8. CALENDAR VIEW
    @action(detail=False, methods=['get'], url_path='calendar')
    def calendar(self, request):
        qs = self.get_queryset()
        month = request.query_params.get('month') # e.g. 2026-10
        if month:
            try:
                parts = month.split('-')
                qs = qs.filter(due_date__year=int(parts[0]), due_date__month=int(parts[1]))
            except Exception:
                pass

        tasks = TaskListSerializer(qs, many=True).data
        calendar_map = {}
        for t in tasks:
            d_str = t.get('due_date') or 'unscheduled'
            if d_str not in calendar_map:
                calendar_map[d_str] = []
            calendar_map[d_str].append(t)
        return Response(calendar_map)

    # 9. TEAM WORKLOAD ANALYSIS & CAPACITY WARNINGS
    @action(detail=False, methods=['get'], url_path='workload')
    def workload(self, request):
        today = timezone.localdate()
        employees = Employee.objects.select_related('user', 'department', 'position').filter(user__status='ACTIVE')
        
        dept = request.query_params.get('department')
        if dept:
            employees = employees.filter(department_id=dept)

        data = []
        for emp in employees:
            active_tasks = Task.objects.filter(assigned_to=emp).exclude(status__in=[Task.Status.COMPLETED, Task.Status.CANCELLED])
            due_today = active_tasks.filter(due_date=today).count()
            overdue = active_tasks.filter(due_date__lt=today).count()
            total_active = active_tasks.count()
            urgent_count = active_tasks.filter(priority=Task.Priority.URGENT).count()

            # Capacity load status
            load_status = 'NORMAL'
            warning = None
            if total_active >= 8 or due_today >= 3 or urgent_count >= 2:
                load_status = 'OVERLOADED'
                warning = f"High workload: {total_active} active tasks ({due_today} due today, {urgent_count} urgent)."
            elif total_active >= 5:
                load_status = 'HEAVY'

            data.append({
                'employee_id': emp.id,
                'employee_code': emp.user.employee_code,
                'full_name': emp.full_name,
                'department_name': emp.department.name if emp.department else '',
                'position_title': emp.position.title if emp.position else '',
                'active_tasks_count': total_active,
                'due_today_count': due_today,
                'overdue_count': overdue,
                'urgent_count': urgent_count,
                'load_status': load_status,
                'warning': warning,
            })

        return Response(sorted(data, key=lambda x: x['active_tasks_count'], reverse=True))

    # Existing Task Lifecycle actions
    @action(detail=True, methods=['post'], url_path='accept')
    def accept(self, request, pk=None):
        task = self.get_object()
        task.status = Task.Status.ACCEPTED
        task.save()
        task.log_activity(actor=request.user, action='TASK_ACCEPTED', description="Task accepted by employee.")
        return Response({'status': task.status, 'message': 'Task accepted successfully.'})

    @action(detail=True, methods=['post'], url_path='start')
    def start(self, request, pk=None):
        task = self.get_object()
        task.status = Task.Status.IN_PROGRESS
        if not task.start_date:
            task.start_date = timezone.localdate()
        task.save()
        task.log_activity(actor=request.user, action='TASK_STARTED', description="Task status changed to In Progress.")
        return Response({'status': task.status, 'message': 'Task started.'})

    @action(detail=True, methods=['post'], url_path='progress')
    def update_progress(self, request, pk=None):
        task = self.get_object()
        serializer = TaskProgressSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        pct = serializer.validated_data['progress_percentage']
        comment = serializer.validated_data.get('comment', '')

        task.progress_percentage = pct
        if pct == 100 and task.status != Task.Status.COMPLETED:
            task.status = Task.Status.SUBMITTED
            task.completed_at = timezone.now()
        task.save()

        if task.parent_task:
            task.parent_task.recalculate_subtask_progress()
        if task.project:
            task.project.recalculate_progress()

        desc = f"Progress updated to {pct}%."
        if comment:
            desc += f" Note: {comment}"
        task.log_activity(actor=request.user, action='PROGRESS_UPDATED', description=desc)
        return Response({'status': task.status, 'progress_percentage': task.progress_percentage})

    @action(detail=True, methods=['post'], url_path='block')
    def block(self, request, pk=None):
        task = self.get_object()
        serializer = TaskBlockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        task.status = Task.Status.BLOCKED
        task.blocked_reason = serializer.validated_data['reason']
        task.blocked_expected_resolution = serializer.validated_data.get('expected_resolution')
        task.blocked_comment = serializer.validated_data.get('comment', '')
        task.save()

        task.log_activity(
            actor=request.user,
            action='TASK_BLOCKED',
            description=f"Task blocked. Reason: {task.blocked_reason}. Note: {task.blocked_comment}"
        )
        if task.assigned_by:
            Notification.send_notification(
                recipient=task.assigned_by,
                title="⚠️ Task Blocked",
                message=f"Task '{task.title}' blocked by {task.assigned_to.user.employee_code}. Reason: {task.blocked_reason}",
                notification_type=Notification.NotificationType.TASK_BLOCKED,
                link_type='TASK',
                link_id=task.id
            )
        return Response({'status': task.status, 'message': 'Task marked as blocked.'})

    @action(detail=True, methods=['post'], url_path='unblock')
    def unblock(self, request, pk=None):
        task = self.get_object()
        task.status = Task.Status.IN_PROGRESS
        task.blocked_reason = ''
        task.blocked_comment = ''
        task.save()
        task.log_activity(actor=request.user, action='TASK_UNBLOCKED', description="Task unblocked and resumed.")
        return Response({'status': task.status, 'message': 'Task resumed.'})

    @action(detail=True, methods=['post'], url_path='submit')
    def submit(self, request, pk=None):
        task = self.get_object()
        task.status = Task.Status.SUBMITTED
        task.completed_at = timezone.now()
        task.save()
        task.log_activity(actor=request.user, action='TASK_SUBMITTED', description="Task submitted for manager review.")
        if task.assigned_by:
            Notification.send_notification(
                recipient=task.assigned_by,
                title="Task Submitted for Review",
                message=f"'{task.title}' submitted by {task.assigned_to.user.employee_code}.",
                notification_type=Notification.NotificationType.TASK_SUBMITTED,
                link_type='TASK',
                link_id=task.id
            )
        return Response({'status': task.status, 'message': 'Task submitted for review.'})

    @action(detail=True, methods=['post'], url_path='review')
    def review(self, request, pk=None):
        task = self.get_object()
        serializer = TaskReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        decision = serializer.validated_data['decision']
        remarks = serializer.validated_data.get('remarks', '')

        task.reviewed_by = request.user
        task.reviewed_at = timezone.now()
        task.manager_remarks = remarks

        if decision == 'APPROVE':
            task.status = Task.Status.COMPLETED
            task.progress_percentage = 100
        elif decision == 'REQUEST_CHANGES':
            task.status = Task.Status.REJECTED
        else:
            task.status = Task.Status.CANCELLED

        task.save()
        if task.parent_task:
            task.parent_task.recalculate_subtask_progress()
        if task.project:
            task.project.recalculate_progress()

        task.log_activity(
            actor=request.user,
            action=f"REVIEW_{decision}",
            description=f"Manager review: {decision}. Remarks: {remarks}"
        )
        Notification.send_notification(
            recipient=task.assigned_to.user,
            title=f"Task {decision.title()}",
            message=f"Your task '{task.title}' was reviewed. Result: {decision}.",
            notification_type=Notification.NotificationType.TASK_APPROVED if decision == 'APPROVE' else Notification.NotificationType.TASK_REJECTED,
            link_type='TASK',
            link_id=task.id
        )
        return Response({'status': task.status, 'message': f'Task review completed: {decision}'})

    @action(detail=True, methods=['post'], url_path='toggle-checklist')
    def toggle_checklist(self, request, pk=None):
        item_id = request.data.get('item_id')
        item = TaskChecklistItem.objects.get(id=item_id, task_id=pk)
        item.is_completed = not item.is_completed
        if item.is_completed:
            item.completed_by = request.user
            item.completed_at = timezone.now()
        else:
            item.completed_by = None
            item.completed_at = None
        item.save()

        # Recalculate task percentage
        task = item.task
        total = task.checklist_items.count()
        if total > 0:
            done = task.checklist_items.filter(is_completed=True).count()
            task.progress_percentage = int((done / total) * 100)
            task.save()

        return Response({
            'item': TaskChecklistItemSerializer(item).data,
            'task_progress': task.progress_percentage
        })

    @action(detail=True, methods=['post'], url_path='comments')
    def add_comment(self, request, pk=None):
        task = self.get_object()
        text = request.data.get('comment_text', '').strip()
        mentions = request.data.get('mentions', [])
        if not text:
            return Response({'error': 'Comment text cannot be empty'}, status=status.HTTP_400_BAD_REQUEST)

        comment = TaskComment.objects.create(
            task=task,
            author=request.user,
            comment_text=text,
            mentions=mentions
        )
        task.log_activity(
            actor=request.user,
            action='COMMENT_ADDED',
            description=f"Comment added by {request.user.employee_code}."
        )

        # Handle mentions
        for m in mentions:
            try:
                from apps.accounts.models import User
                mentioned_user = User.objects.filter(Q(employee_code=m) | Q(username=m)).first()
                if mentioned_user and mentioned_user != request.user:
                    Notification.send_notification(
                        recipient=mentioned_user,
                        title=f"Mentioned in '{task.title}'",
                        message=f"{request.user.employee_code} mentioned you in a task comment.",
                        notification_type=Notification.NotificationType.TASK_UPDATED,
                        link_type='TASK',
                        link_id=task.id
                    )
            except Exception:
                pass

        return Response(TaskCommentSerializer(comment).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='attachments')
    def upload_attachment(self, request, pk=None):
        task = self.get_object()
        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)

        mime_type, _ = mimetypes.guess_type(file_obj.name)
        existing_versions = task.attachments.filter(filename=file_obj.name).count()
        
        attachment = TaskAttachment.objects.create(
            task=task,
            uploaded_by=request.user,
            file=file_obj,
            filename=file_obj.name,
            file_size=file_obj.size,
            mime_type=mime_type or 'application/octet-stream',
            version=existing_versions + 1
        )
        task.log_activity(
            actor=request.user,
            action='ATTACHMENT_UPLOADED',
            description=f"Uploaded file: {attachment.filename} (v{attachment.version}, {attachment.file_size} bytes)."
        )
        return Response(TaskAttachmentSerializer(attachment).data, status=status.HTTP_201_CREATED)


class TaskTemplateViewSet(viewsets.ModelViewSet):
    queryset = TaskTemplate.objects.filter(is_active=True)
    serializer_class = TaskTemplateSerializer
    filterset_fields = ['department']
    search_fields = ['name', 'description']
