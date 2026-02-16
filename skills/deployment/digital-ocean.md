# Digital Ocean Deployment

Patterns for deploying a web application to a Digital Ocean Droplet with Nginx, systemd, and HTTPS.

## Infrastructure Overview

| Component | Platform | Details |
|-----------|----------|---------|
| Server | DO Droplet | Ubuntu 22.04 LTS |
| Database | Managed PostgreSQL | Hosted externally |
| Web Server | Nginx | Reverse proxy + static files |
| Process Manager | systemd | Service management |

## Directory Structure

```
/opt/your-app/
├── .venv/                    # Python virtual environment
├── .env.production           # Backend environment variables
├── src/                      # Backend source
├── frontend/
│   ├── dist/                 # Built frontend (served by Nginx)
│   └── .env.production       # Frontend build-time variables
└── deploy/production/        # Deployment scripts
```

## Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Frontend static files
    location / {
        root /opt/your-app/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        root /opt/your-app/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Backend API proxy
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
}
```

**Key patterns:**
- SPA routing: `try_files $uri $uri/ /index.html` for client-side routing
- Static asset caching: `expires 1y` with `immutable` for hashed filenames
- Rate limiting: `limit_req` on API endpoints
- Health check: proxied to backend, no access logging

## systemd Service

```ini
[Unit]
Description=Your App API Server
After=network.target

[Service]
Type=exec
User=deploy
Group=deploy
WorkingDirectory=/opt/your-app/current
Environment=PATH=/opt/your-app/current/.venv/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/opt/your-app/current/.env.production

ExecStart=/opt/your-app/current/.venv/bin/python -m uvicorn src.api:app --host 127.0.0.1 --port 8000 --workers 4

Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/your-app/current
ReadWritePaths=/var/log/your-app

[Install]
WantedBy=multi-user.target
```

**Security hardening:**
- `NoNewPrivileges` — prevents privilege escalation
- `PrivateTmp` — isolated temp directory
- `ProtectSystem=strict` — read-only filesystem except allowed paths
- `ProtectHome` — no access to home directories
- `ReadWritePaths` — explicit write access only where needed

## Deploy Script Structure

```bash
#!/bin/bash
set -euo pipefail

APP_DIR="/opt/your-app"
LOG="/var/log/your-app/deployments.log"

echo "$(date): Starting deployment" | tee -a "$LOG"

# 1. Pull latest code
cd "$APP_DIR" && git pull origin main

# 2. Install/update Python dependencies
source .venv/bin/activate
pip install -r requirements.txt

# 3. Build frontend
cd frontend
source .env.production  # Load build-time env vars
npm ci && npm run build
cd ..

# 4. Copy production env
cp .env.production .env

# 5. Smoke test
python -c "from your_app.main import app; print('Import OK')"

# 6. Restart services
sudo systemctl restart your-app-api
sudo systemctl reload nginx

# 7. Health check
sleep 3
if curl -sf http://localhost:8000/health > /dev/null; then
    echo "$(date): Deployment successful" | tee -a "$LOG"
else
    echo "$(date): HEALTH CHECK FAILED" | tee -a "$LOG"
    exit 1
fi
```

## HTTPS via Certbot

```bash
# After DNS is configured and pointing to your droplet
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

Certbot automatically:
- Obtains SSL certificate from Let's Encrypt
- Modifies Nginx config for HTTPS
- Sets up auto-renewal

## Environment Variables (Production)

```bash
# .env.production (backend)
DATABASE_URL=postgresql://user:pass@host:port/db
SECRET_KEY=your-secret-key
ENVIRONMENT=production
API_HOST=0.0.0.0
API_PORT=8000
ALLOWED_ORIGINS=https://your-domain.com
LOG_LEVEL=INFO

# frontend/.env.production
VITE_API_URL=https://your-domain.com/api
```

**Rules:**
- Never commit `.env.production` to git
- Use placeholder values in examples
- Rotate keys periodically

## Log Management and Monitoring

```bash
# Application logs
journalctl -u your-app-api -f

# Nginx logs
tail -f /var/log/nginx/your-app-access.log
tail -f /var/log/nginx/your-app-error.log

# Deployment history
tail -f /var/log/your-app/deployments.log

# Service status
systemctl status your-app-api
systemctl status nginx
```

## Rollback

Keep a rollback script that reverts to the previous deployment:

```bash
#!/bin/bash
set -euo pipefail

# Revert to previous commit
cd /opt/your-app && git checkout HEAD~1

# Rebuild and restart
source .venv/bin/activate
pip install -r requirements.txt
cd frontend && npm ci && npm run build && cd ..
sudo systemctl restart your-app-api
sudo systemctl reload nginx

# Verify
sleep 3
curl -sf http://localhost:8000/health && echo "Rollback successful"
```

## Service Commands

```bash
sudo systemctl restart your-app-api    # Restart backend
sudo journalctl -u your-app-api -f     # View backend logs
sudo nginx -t && sudo systemctl reload nginx  # Reload Nginx config
```
