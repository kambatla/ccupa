# Digital Ocean Deployment

Stack: Ubuntu 22.04 Droplet, Managed PostgreSQL, Nginx, systemd.

## Directory Structure

```
/opt/your-app/
├── .venv/
├── .env.production
├── src/
├── frontend/
│   ├── dist/
│   └── .env.production
└── deploy/production/
```

## Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        root /opt/your-app/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        root /opt/your-app/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
}
```

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
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/your-app/current
ReadWritePaths=/var/log/your-app

[Install]
WantedBy=multi-user.target
```

## Deploy Script

```bash
#!/bin/bash
set -euo pipefail

APP_DIR="/opt/your-app"
LOG="/var/log/your-app/deployments.log"

echo "$(date): Starting deployment" | tee -a "$LOG"

cd "$APP_DIR" && git pull origin main
source .venv/bin/activate && pip install -r requirements.txt
cd frontend && source .env.production && npm ci && npm run build && cd ..
cp .env.production .env
python -c "from your_app.main import app; print('Import OK')"
sudo systemctl restart your-app-api && sudo systemctl reload nginx

sleep 3
if curl -sf http://localhost:8000/health > /dev/null; then
    echo "$(date): Deployment successful" | tee -a "$LOG"
else
    echo "$(date): HEALTH CHECK FAILED" | tee -a "$LOG"
    exit 1
fi
```

## HTTPS

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## Environment Variables

```bash
# .env.production (backend)
DATABASE_URL=postgresql://user:pass@host:port/db
SECRET_KEY=your-secret-key
ENVIRONMENT=production
ALLOWED_ORIGINS=https://your-domain.com

# frontend/.env.production
VITE_API_URL=https://your-domain.com/api
```

Never commit `.env.production` to git.

## Logs and Service Commands

```bash
journalctl -u your-app-api -f              # Backend logs
tail -f /var/log/nginx/your-app-error.log  # Nginx errors
systemctl status your-app-api nginx        # Service status
sudo nginx -t && sudo systemctl reload nginx
```

## Rollback

```bash
#!/bin/bash
set -euo pipefail
cd /opt/your-app && git checkout HEAD~1
source .venv/bin/activate && pip install -r requirements.txt
cd frontend && npm ci && npm run build && cd ..
sudo systemctl restart your-app-api && sudo systemctl reload nginx
sleep 3 && curl -sf http://localhost:8000/health && echo "Rollback successful"
```
