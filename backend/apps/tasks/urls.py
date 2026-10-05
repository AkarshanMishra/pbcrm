from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet, TaskTemplateViewSet, ProjectViewSet

router = DefaultRouter()
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'templates', TaskTemplateViewSet, basename='task-template')
router.register(r'', TaskViewSet, basename='task')

urlpatterns = [
    path('', include(router.urls)),
]
