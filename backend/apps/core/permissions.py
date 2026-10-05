from rest_framework.permissions import BasePermission

class HasPermissionCode(BasePermission):
    """
    Checks whether the authenticated user has a specific permission code assigned via their Role.
    Usage in View:
        permission_classes = [HasPermissionCode]
        required_permission = 'MANAGE_EMPLOYEES'
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Superuser / Admin role bypass
        if getattr(request.user, 'is_superuser', False):
            return True

        required_permission = getattr(view, 'required_permission', None)
        if not required_permission:
            return True

        return request.user.has_permission_code(required_permission)


class IsAdminUserOnly(BasePermission):
    """
    Grants access only to ADMIN role or superusers.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.is_superuser or request.user.is_admin_role


class IsManagerOrAdmin(BasePermission):
    """
    Grants access to Managers, Admins, or Superusers.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.is_superuser or request.user.is_admin_role or request.user.is_manager_role
