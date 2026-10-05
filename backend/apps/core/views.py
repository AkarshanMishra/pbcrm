from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from apps.core.models import MasterWorkflowProcess, MasterWorkflowStep, CentralEventRecord
from apps.core.serializers import (
    MasterWorkflowProcessSerializer,
    MasterWorkflowStepSerializer,
    CentralEventRecordSerializer
)
from apps.core.workflow_engine import WorkflowEngine

class MasterWorkflowViewSet(viewsets.ModelViewSet):
    queryset = MasterWorkflowProcess.objects.all().prefetch_related('steps')
    serializer_class = MasterWorkflowProcessSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['workflow_type', 'status', 'current_department', 'entity_type', 'entity_id']
    search_fields = ['process_code', 'title', 'entity_id', 'current_stage_name']

    @action(detail=True, methods=['post'], url_path='advance-step')
    def advance_step(self, request, pk=None):
        process = self.get_object()
        step_id = request.data.get('step_id')
        action_name = request.data.get('action', 'COMPLETE').upper()
        comments = request.data.get('comments', '')

        if not step_id:
            step = process.steps.filter(status=MasterWorkflowStep.Status.IN_PROGRESS).first()
            if not step:
                step = process.steps.filter(status=MasterWorkflowStep.Status.PENDING_APPROVAL).first()
            if not step:
                return Response({'error': 'No active step found to advance.'}, status=status.HTTP_400_BAD_REQUEST)
            step_id = step.id

        try:
            updated_process = WorkflowEngine.advance_step(
                step_id=step_id,
                action=action_name,
                actor=request.user,
                comments=comments
            )
            return Response(MasterWorkflowProcessSerializer(updated_process).data)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class CentralEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CentralEventRecord.objects.all()
    serializer_class = CentralEventRecordSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['event_type', 'entity_type', 'entity_id']
    search_fields = ['entity_id', 'event_type']


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def entity_360_graph_view(request):
    """
    Returns the comprehensive 360° relationship graph across all 5 departments for an entity.
    Query params: ?entity_type=employee&entity_id=EMP-000124 or ?entity_type=partner&entity_id=PBV0000001
    """
    entity_type = request.query_params.get('entity_type', 'employee').lower()
    entity_id = request.query_params.get('entity_id', '')

    if not entity_id:
        return Response({'error': 'entity_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

    graph_data = WorkflowEngine.get_360_graph(entity_type, entity_id)
    return Response(graph_data)
