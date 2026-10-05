from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.core.views import MasterWorkflowViewSet, CentralEventViewSet, entity_360_graph_view

router = DefaultRouter()
router.register(r'workflows', MasterWorkflowViewSet, basename='master-workflows')
router.register(r'events', CentralEventViewSet, basename='central-events')

urlpatterns = [
    path('360-graph/', entity_360_graph_view, name='entity-360-graph'),
    path('', include(router.urls)),
]
