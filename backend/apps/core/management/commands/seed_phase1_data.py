from django.core.management.base import BaseCommand
from django.db import transaction
from apps.accounts.models import User
from apps.organization.models import Department, Position, Role, Permission, RolePermission
from apps.employees.models import Employee

class Command(BaseCommand):
    help = 'Seeds essential Phase 1 departments, roles, permissions, and test accounts.'

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write("--- Seeding Phase 1 Database ---")

        # 1. Departments
        depts_data = [
            ('IT', 'Information Technology', 'Software, Hardware & Infrastructure'),
            ('MKT', 'Marketing', 'Brand, Content & Growth Operations'),
            ('OPS', 'Operations', 'Field Operations & Supply Logistics'),
            ('ACC', 'Accounts & Finance', 'Payroll, Billing & Auditing'),
            ('EXEC', 'Executive Leadership', 'Board of Directors & Management'),
        ]
        dept_map = {}
        for code, name, desc in depts_data:
            dept, _ = Department.objects.get_or_create(code=code, defaults={'name': name, 'description': desc})
            dept_map[code] = dept
            self.stdout.write(f"Department: {dept.name}")

        # 2. Positions
        positions_data = [
            ('IT', 'IT Manager', 'ITM', 'Manages IT engineering & support'),
            ('IT', 'Software Developer', 'SDE', 'Designs & builds software products'),
            ('IT', 'IT Support Executive', 'ITS', 'Assists with IT helpdesk'),
            ('MKT', 'Marketing Manager', 'MKM', 'Leads growth & acquisition campaigns'),
            ('MKT', 'Marketing Executive', 'MKE', 'Executes marketing operations'),
            ('OPS', 'Operations Manager', 'OPM', 'Oversees operational workflows'),
            ('ACC', 'Senior Accountant', 'ACC1', 'Handles finances and tax audits'),
            ('EXEC', 'Chief Executive Officer', 'CEO', 'Overall business leadership'),
        ]
        pos_map = {}
        for dept_code, title, code, desc in positions_data:
            pos, _ = Position.objects.get_or_create(
                department=dept_map[dept_code],
                title=title,
                defaults={'code': code, 'description': desc}
            )
            pos_map[title] = pos
            self.stdout.write(f"Position: {pos.title} ({dept_code})")

        # 3. Roles
        roles_data = [
            (Role.RoleCode.ADMIN, 'Administrator', 'Full system access and security administration', True),
            (Role.RoleCode.IT, 'Information Technology', 'IT department access', False),
            (Role.RoleCode.MARKETING, 'Marketing', 'Marketing operations access', False),
            (Role.RoleCode.OPERATIONS, 'Operations', 'Operations operations access', False),
            (Role.RoleCode.ACCOUNTS, 'Accounts', 'Accounts & payroll access', False),
        ]
        role_map = {}
        for code, name, desc, reserved in roles_data:
            role, _ = Role.objects.get_or_create(code=code, defaults={'name': name, 'description': desc, 'is_system_reserved': reserved})
            role_map[code] = role
            self.stdout.write(f"Role: {role.name}")

        # 4. Permissions Catalog
        permissions_data = [
            ('VIEW_OWN_PROFILE', 'View Own Profile', Permission.Category.PROFILE, 'Can view own employee profile'),
            ('VIEW_OWN_ATTENDANCE', 'View Own Attendance', Permission.Category.ATTENDANCE, 'Can view personal check-ins and history'),
            ('CHECK_IN_OUT', 'Check In & Out', Permission.Category.ATTENDANCE, 'Can perform daily attendance check-in and check-out'),
            ('REQUEST_ATTENDANCE_CORRECTION', 'Request Attendance Correction', Permission.Category.ATTENDANCE, 'Can submit correction requests for attendance'),
            ('VIEW_TEAM_ATTENDANCE', 'View Team Attendance', Permission.Category.ATTENDANCE, 'Can view direct reports attendance'),
            ('APPROVE_ATTENDANCE_CORRECTION', 'Approve Attendance Corrections', Permission.Category.ATTENDANCE, 'Can approve or reject team attendance corrections'),
            ('VIEW_EMPLOYEE_LIST', 'View Employee Directory', Permission.Category.EMPLOYEE, 'Can search and view employee list'),
            ('ADD_EMPLOYEE', 'Add New Employee', Permission.Category.EMPLOYEE, 'Can provision new employee accounts'),
            ('EDIT_EMPLOYEE', 'Edit Employee Profile', Permission.Category.EMPLOYEE, 'Can edit employee profile details'),
            ('DISABLE_EMPLOYEE', 'Disable Employee Account', Permission.Category.EMPLOYEE, 'Can deactivate or suspend employee accounts'),
            ('CHANGE_POSITION', 'Change Employee Position', Permission.Category.ORGANIZATION, 'Can reassign department and position'),
            ('VIEW_AUDIT_LOGS', 'View Audit Logs', Permission.Category.SECURITY, 'Can inspect immutable security and action audit trail'),
            ('SECURITY_SETTINGS', 'Manage Security Settings', Permission.Category.SECURITY, 'Can manage password policy, MFA, and lockouts'),
        ]
        all_perms = []
        for code, name, cat, desc in permissions_data:
            perm, _ = Permission.objects.get_or_create(code=code, defaults={'name': name, 'category': cat, 'description': desc})
            all_perms.append(perm)

        # 5. Role Permissions Mapping
        # ADMIN gets all permissions
        for perm in all_perms:
            RolePermission.objects.get_or_create(role=role_map[Role.RoleCode.ADMIN], permission=perm)

        # Base roles get standard self-service permissions
        standard_perm_codes = ['VIEW_OWN_PROFILE', 'VIEW_OWN_ATTENDANCE', 'CHECK_IN_OUT', 'REQUEST_ATTENDANCE_CORRECTION', 'VIEW_EMPLOYEE_LIST']
        for role_code in [Role.RoleCode.IT, Role.RoleCode.MARKETING, Role.RoleCode.OPERATIONS, Role.RoleCode.ACCOUNTS]:
            for p in all_perms:
                if p.code in standard_perm_codes:
                    RolePermission.objects.get_or_create(role=role_map[role_code], permission=p)

        # 6. Admin User & Employee Profile
        admin_user, created = User.objects.get_or_create(
            employee_code='PBE000001',
            defaults={
                'email': 'admin@pcrm.local',
                'is_staff': True,
                'is_superuser': True,
                'status': User.AccountStatus.ACTIVE
            }
        )
        if created:
            admin_user.set_password('12345678')
            admin_user.save()

        admin_emp, _ = Employee.objects.get_or_create(
            user=admin_user,
            defaults={
                'first_name': 'Super',
                'last_name': 'Administrator',
                'department': dept_map['EXEC'],
                'position': pos_map['Chief Executive Officer'],
                'role': role_map[Role.RoleCode.ADMIN],
            }
        )
        self.stdout.write(self.style.SUCCESS(f"Created Admin: PBE000001 (admin@pcrm.local / 12345678)"))

        # 7. IT Manager & Team Member
        mgr_user, created = User.objects.get_or_create(
            employee_code='PBE000002',
            defaults={
                'email': 'it.manager@pcrm.local',
                'is_staff': False,
                'is_superuser': False,
                'status': User.AccountStatus.ACTIVE
            }
        )
        if created:
            mgr_user.set_password('12345678')
            mgr_user.save()

        mgr_emp, _ = Employee.objects.get_or_create(
            user=mgr_user,
            defaults={
                'first_name': 'Vikram',
                'last_name': 'Mehta',
                'department': dept_map['IT'],
                'position': pos_map['IT Manager'],
                'role': role_map[Role.RoleCode.IT],
            }
        )
        self.stdout.write(self.style.SUCCESS(f"Created Manager: PBE000002 (it.manager@pcrm.local / 12345678)"))

        dev_user, created = User.objects.get_or_create(
            employee_code='PBE000003',
            defaults={
                'email': 'dev.rahul@pcrm.local',
                'is_staff': False,
                'is_superuser': False,
                'status': User.AccountStatus.ACTIVE
            }
        )
        if created:
            dev_user.set_password('12345678')
            dev_user.save()

        dev_emp, _ = Employee.objects.get_or_create(
            user=dev_user,
            defaults={
                'first_name': 'Rahul',
                'last_name': 'Sharma',
                'department': dept_map['IT'],
                'position': pos_map['Software Developer'],
                'role': role_map[Role.RoleCode.IT],
                'reporting_manager': mgr_emp,
            }
        )
        self.stdout.write(self.style.SUCCESS(f"Created Employee: PBE000003 (dev.rahul@pcrm.local / 12345678)"))

        self.stdout.write(self.style.SUCCESS("[SUCCESS] Successfully seeded all Phase 1 baseline data!"))
