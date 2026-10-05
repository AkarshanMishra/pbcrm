import os
import mimetypes
from pathlib import Path
from django.contrib import admin
from django.urls import path, re_path, include
from django.conf import settings
from django.http import HttpResponse, FileResponse, Http404
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

FLUTTER_WEB_DIR = Path(settings.BASE_DIR).parent / 'mobile' / 'build' / 'web'

def serve_flutter_app(request, resource=''):
    if not FLUTTER_WEB_DIR.exists():
        return HttpResponse(
            "<html><body style='font-family:sans-serif;padding:40px;background:#0f172a;color:#fff;text-align:center;'>"
            "<h2>Flutter Web build not ready</h2>"
            "<p>Please run <code>flutter build web</code> to generate the desktop web client.</p>"
            "</body></html>",
            status=503,
            content_type="text/html"
        )
    
    resource_clean = resource.strip('/')
    if not resource_clean:
        index_path = FLUTTER_WEB_DIR / 'index.html'
        if index_path.exists():
            resp = FileResponse(open(index_path, 'rb'), content_type='text/html')
            resp['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            return resp
        raise Http404("index.html not found")

    target_file = (FLUTTER_WEB_DIR / resource_clean).resolve()
    # Security directory traversal check
    if not str(target_file).startswith(str(FLUTTER_WEB_DIR.resolve())):
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
    index_path = FLUTTER_WEB_DIR / 'index.html'
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
            body { background: #0F172A; color: #F8FAFC; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
            .container { max-width: 860px; width: 100%; background: #1E293B; border-radius: 20px; border: 1px solid #334155; padding: 40px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); }
            .badge { display: inline-flex; align-items: center; gap: 6px; background: rgba(16, 185, 129, 0.15); color: #10B981; padding: 6px 14px; border-radius: 9999px; font-size: 13px; font-weight: 600; margin-bottom: 20px; border: 1px solid rgba(16, 185, 129, 0.3); }
            .badge-dot { width: 8px; height: 8px; background: #10B981; border-radius: 50%; box-shadow: 0 0 10px #10B981; }
            h1 { font-size: 32px; font-weight: 800; margin-bottom: 12px; background: linear-gradient(to right, #60A5FA, #A78BFA, #34D399); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
            p.subtitle { color: #94A3B8; font-size: 15px; margin-bottom: 25px; line-height: 1.6; }
            
            .hero-card {
                background: linear-gradient(135deg, rgba(37, 99, 235, 0.2), rgba(124, 58, 237, 0.2));
                border: 1.5px solid #60A5FA;
                border-radius: 16px;
                padding: 24px;
                margin-bottom: 25px;
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 20px;
            }
            .hero-card h2 { font-size: 20px; font-weight: 700; color: #FFFFFF; margin-bottom: 6px; }
            .hero-card p { font-size: 14px; color: #CBD5E1; }
            .btn-primary {
                background: linear-gradient(135deg, #2563EB, #7C3AED);
                color: #FFFFFF;
                text-decoration: none;
                font-weight: 700;
                padding: 12px 24px;
                border-radius: 10px;
                display: inline-flex;
                align-items: center;
                gap: 8px;
                box-shadow: 0 10px 20px -5px rgba(37, 99, 235, 0.5);
                transition: transform 0.2s;
                white-space: nowrap;
            }
            .btn-primary:hover { transform: scale(1.03); }

            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 30px; }
            .card { background: #0F172A; border: 1px solid #334155; border-radius: 14px; padding: 20px; text-decoration: none; color: inherit; transition: all 0.2s ease; display: flex; flex-direction: column; }
            .card:hover { border-color: #60A5FA; transform: translateY(-3px); box-shadow: 0 10px 20px -5px rgba(96, 165, 250, 0.2); }
            .card h3 { font-size: 16px; font-weight: 700; color: #F8FAFC; margin-bottom: 6px; }
            .card p { font-size: 13px; color: #94A3B8; line-height: 1.4; flex-grow: 1; margin-bottom: 12px; }
            .card-link { font-size: 13px; font-weight: 600; color: #60A5FA; display: flex; align-items: center; gap: 4px; }
            
            .credentials-box { background: #0F172A; border: 1px solid #334155; border-radius: 14px; padding: 20px; }
            .credentials-box h4 { font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em; color: #64748B; margin-bottom: 12px; }
            table { width: 100%; border-collapse: collapse; font-size: 13px; }
            th { text-align: left; color: #94A3B8; padding-bottom: 8px; border-bottom: 1px solid #334155; }
            td { padding: 8px 0; border-bottom: 1px solid rgba(51, 65, 85, 0.5); }
            code { background: #1E293B; padding: 2px 6px; border-radius: 4px; color: #E2E8F0; font-family: monospace; }
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
                            <td><strong style="color: #A78BFA;">Admin</strong></td>
                            <td><code>PBE000001</code> / <code>admin@pcrm.local</code></td>
                            <td><code>AdminPassword@123!</code></td>
                        </tr>
                        <tr>
                            <td><strong style="color: #60A5FA;">Manager</strong></td>
                            <td><code>PBE000002</code> / <code>it.manager@pcrm.local</code></td>
                            <td><code>ManagerPassword@123!</code></td>
                        </tr>
                        <tr>
                            <td><strong style="color: #34D399;">Employee</strong></td>
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
    # Root Portal
    path('', root_landing_view, name='root-portal'),
    
    # Desktop / Web App
    path('app/', serve_flutter_app, name='flutter-web-root'),
    re_path(r'^app/(?P<resource>.*)$', serve_flutter_app, name='flutter-web-assets'),

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
