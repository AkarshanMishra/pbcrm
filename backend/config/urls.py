import os
import mimetypes
from pathlib import Path
from django.contrib import admin
from django.urls import path, re_path, include
from django.conf import settings
from django.http import HttpResponse, FileResponse, Http404
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

def get_flutter_web_dir():
    static_app = Path(settings.BASE_DIR) / 'static' / 'app'
    if (static_app / 'index.html').exists():
        return static_app
    mobile_web = Path(settings.BASE_DIR).parent / 'mobile' / 'build' / 'web'
    if (mobile_web / 'index.html').exists():
        return mobile_web
    return static_app

def serve_flutter_app(request, resource=''):
    web_dir = get_flutter_web_dir()
    if not (web_dir / 'index.html').exists():
        return HttpResponse(
            "<html><body style='font-family:sans-serif;padding:40px;background:#F8FAFC;color:#0F172A;text-align:center;'>"
            "<h2>PCRM Enterprise Web Client Preparing</h2>"
            "<p>The application assets are building. Please refresh in a few seconds.</p>"
            "</body></html>",
            status=503,
            content_type="text/html"
        )
    
    resource_clean = resource.strip('/')
    if not resource_clean or resource_clean == 'app':
        index_path = web_dir / 'index.html'
        if index_path.exists():
            resp = FileResponse(open(index_path, 'rb'), content_type='text/html')
            resp['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            return resp
        raise Http404("index.html not found")

    target_file = (web_dir / resource_clean).resolve()
    # Security directory traversal check
    if not str(target_file).startswith(str(web_dir.resolve())):
        raise Http404("Access denied")

    if target_file.is_file():
        mime_type, _ = mimetypes.guess_type(str(target_file))
        if target_file.suffix == '.js':
            mime_type = 'application/javascript'
        elif target_file.suffix == '.json':
            mime_type = 'application/json'
        elif target_file.suffix == '.wasm':
            mime_type = 'application/wasm'
        elif target_file.suffix in ('.otf', '.ttf', '.woff', '.woff2'):
            mime_type = 'font/otf'
        resp = FileResponse(open(target_file, 'rb'), content_type=mime_type or 'application/octet-stream')
        if target_file.suffix in ('.html', '.js'):
            resp['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        else:
            resp['Cache-Control'] = 'public, max-age=86400'
        return resp

    # Fallback to index.html for client-side routing
    index_path = web_dir / 'index.html'
    if index_path.exists():
        resp = FileResponse(open(index_path, 'rb'), content_type='text/html')
        resp['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return resp
    raise Http404("Resource not found")


def root_landing_view(request):
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>PCRM Enterprise Portal</title>
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Plus Jakarta Sans', sans-serif; }
            body { background: #F8FAFC; color: #0F172A; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
            .container { max-width: 860px; width: 100%; background: #FFFFFF; border-radius: 20px; border: 1.5px solid #E2E8F0; padding: 40px; box-shadow: 0 20px 40px -10px rgba(0,0,0,0.06); }
            .badge { display: inline-flex; align-items: center; gap: 6px; background: #ECFDF5; color: #059669; padding: 6px 14px; border-radius: 9999px; font-size: 13px; font-weight: 700; margin-bottom: 20px; border: 1px solid #A7F3D0; }
            .badge-dot { width: 8px; height: 8px; background: #10B981; border-radius: 50%; box-shadow: 0 0 8px #10B981; }
            h1 { font-size: 32px; font-weight: 800; margin-bottom: 12px; color: #0F172A; }
            p.subtitle { color: #64748B; font-size: 15px; margin-bottom: 25px; line-height: 1.6; }
            
            .hero-card {
                background: linear-gradient(135deg, #EFF6FF, #FDF2F8);
                border: 1.5px solid #BFDBFE;
                border-radius: 16px;
                padding: 24px;
                margin-bottom: 25px;
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 20px;
            }
            .hero-card h2 { font-size: 20px; font-weight: 800; color: #0F172A; margin-bottom: 6px; }
            .hero-card p { font-size: 14px; color: #475569; }
            .btn-primary {
                background: linear-gradient(135deg, #2563EB, #4F46E5);
                color: #FFFFFF;
                text-decoration: none;
                font-weight: 700;
                padding: 12px 24px;
                border-radius: 10px;
                display: inline-flex;
                align-items: center;
                gap: 8px;
                box-shadow: 0 10px 20px -5px rgba(37, 99, 235, 0.4);
                transition: transform 0.2s;
                white-space: nowrap;
            }
            .btn-primary:hover { transform: scale(1.03); }

            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 30px; }
            .card { background: #FFFFFF; border: 1.5px solid #E2E8F0; border-radius: 14px; padding: 20px; text-decoration: none; color: inherit; transition: all 0.2s ease; display: flex; flex-direction: column; }
            .card:hover { border-color: #2563EB; transform: translateY(-3px); box-shadow: 0 10px 20px -5px rgba(37, 99, 235, 0.15); }
            .card h3 { font-size: 16px; font-weight: 700; color: #0F172A; margin-bottom: 6px; }
            .card p { font-size: 13px; color: #64748B; line-height: 1.4; flex-grow: 1; margin-bottom: 12px; }
            .card-link { font-size: 13px; font-weight: 700; color: #2563EB; display: flex; align-items: center; gap: 4px; }
            
            .credentials-box { background: #F8FAFC; border: 1.5px solid #E2E8F0; border-radius: 14px; padding: 20px; }
            .credentials-box h4 { font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em; color: #475569; margin-bottom: 12px; font-weight: 800; }
            table { width: 100%; border-collapse: collapse; font-size: 13px; }
            th { text-align: left; color: #64748B; padding-bottom: 8px; border-bottom: 1px solid #E2E8F0; font-weight: 700; }
            td { padding: 8px 0; border-bottom: 1px solid #F1F5F9; color: #1E293B; }
            code { background: #E2E8F0; padding: 2px 6px; border-radius: 4px; color: #0F172A; font-family: monospace; font-weight: 600; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="badge"><span class="badge-dot"></span> PCRM Enterprise Server Online</div>
            <h1>PCRM Enterprise Platform</h1>
            <p class="subtitle">Complete Work, Task Management, To-Do, Real-time Notifications, RBAC & Attendance System.</p>
            
            <div class="hero-card">
                <div>
                    <h2>💻 Desktop / Web Application</h2>
                    <p>Open and use the full PCRM Enterprise app directly in your desktop browser or app window.</p>
                </div>
                <a href="/app/" class="btn-primary">
                    Launch Desktop App &rarr;
                </a>
            </div>

            <div class="grid">
                <a href="/api/docs/" class="card">
                    <h3>Swagger UI Docs</h3>
                    <p>Interactive API testing console with live JWT authentication & endpoints.</p>
                    <span class="card-link">Explore Endpoints &rarr;</span>
                </a>
                <a href="/api/redoc/" class="card">
                    <h3>Redoc API Specs</h3>
                    <p>Clean OpenAPI documentation and schema specifications.</p>
                    <span class="card-link">View Documentation &rarr;</span>
                </a>
                <a href="/admin/" class="card">
                    <h3>Django Admin</h3>
                    <p>Administrative portal for managing database models and records.</p>
                    <span class="card-link">Open Portal &rarr;</span>
                </a>
            </div>

            <div class="credentials-box">
                <h4>Seeded Test Accounts (ID / Password)</h4>
                <table>
                    <thead>
                        <tr>
                            <th>Role</th>
                            <th>Employee ID / Email</th>
                            <th>Password</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong style="color: #7C3AED;">Admin</strong></td>
                            <td><code>PBE000001</code> / <code>admin@pcrm.local</code></td>
                            <td><code>AdminPassword@123!</code></td>
                        </tr>
                        <tr>
                            <td><strong style="color: #2563EB;">Manager</strong></td>
                            <td><code>PBE000002</code> / <code>it.manager@pcrm.local</code></td>
                            <td><code>ManagerPassword@123!</code></td>
                        </tr>
                        <tr>
                            <td><strong style="color: #059669;">Employee</strong></td>
                            <td><code>PBE000003</code> / <code>dev.rahul@pcrm.local</code></td>
                            <td><code>EmployeePassword@123!</code></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </body>
    </html>
    """
    return HttpResponse(html_content)

urlpatterns = [
    # Direct Desktop / Web App Entry Point at Root & /app/
    path('', serve_flutter_app, name='flutter-web-root-direct'),
    path('app/', serve_flutter_app, name='flutter-web-root'),
    re_path(r'^app/(?P<resource>.*)$', serve_flutter_app, name='flutter-web-assets'),

    # Direct Flutter static asset resolvers for root-relative paths
    re_path(r'^(?P<resource>(flutter_bootstrap\.js|main\.dart\.js|flutter_service_worker\.js|assets/.*|canvaskit/.*|manifest\.json|favicon\.png|version\.json))$', serve_flutter_app, name='flutter-root-assets'),

    # Optional Portal Landing & Docs
    path('portal/', root_landing_view, name='root-portal'),

    # Django Admin
    path('admin/', admin.site.urls),
    
    # API Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Application Endpoints
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/organization/', include('apps.organization.urls')),
    path('api/v1/employees/', include('apps.employees.urls')),
    path('api/v1/attendance/', include('apps.attendance.urls')),
    path('api/v1/audit/', include('apps.audit.urls')),
    path('api/v1/security/', include('apps.security_center.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),
    path('api/v1/tasks/', include('apps.tasks.urls')),
    path('api/v1/work/', include('apps.work_management.urls')),
    path('api/v1/tickets/', include('apps.tickets.urls')),
    path('api/v1/marketing/', include('apps.marketing.urls')),
    path('api/v1/it/', include('apps.it_ops.urls')),
    path('api/v1/operations/', include('apps.operations.urls')),
    path('api/v1/hr/', include('apps.hr.urls')),
    path('api/v1/sync/', include('apps.sync_engine.urls')),
    path('api/v1/core/', include('apps.core.urls')),
    path('api/v1/workflows/', include('apps.core.urls')),
]
