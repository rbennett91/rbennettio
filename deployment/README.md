# Production Deployment Guide

This document describes the production deployment of the rbennettio Django application on AWS infrastructure.

## Table of Contents

- [Infrastructure Overview](#infrastructure-overview)
- [Prerequisites](#prerequisites)
- [Initial Deployment](#initial-deployment)
- [Configuration](#configuration)
- [SSL Certificate Setup](#ssl-certificate-setup)
- [Database Management](#database-management)
- [Application Updates](#application-updates)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Infrastructure Overview

### AWS Resources

- **Region**: us-west-2
- **Compute**: Reserved EC2 instance (t4g.small) running Amazon Linux 2023 (kernel-6.12 AMI 64-bit Arm)
- **Storage**: Private S3 bucket for SQLite database backups with versioning and lifecycle management
- **DNS**: Route53 for domain management
- **Security**:
  - EC2 Security Group allowing HTTP (80) and HTTPS (443) inbound traffic
  - IAM role with S3 access permissions attached to EC2 instance
- **SSL**: Let's Encrypt certificates managed via Certbot

### Application Stack

- **Python**: 3.13
- **Framework**: Django 5.2.1
- **Database**: SQLite 3.40
- **Python Package Manager**: UV
- **Application Server**: uWSGI
- **Web Server**: Nginx (reverse proxy)

## Prerequisites

### AWS Setup

1. **Security Group**: Create an EC2 security group that allows inbound HTTP and HTTPS
2. **S3 Bucket**: Create a private bucket for database backups with:
   - Versioning enabled
   - Lifecycle policy to delete old backups
3. **IAM Role**: Create an AWS service role allowing the EC2 service to perform actions on the S3 bucket

## Initial Deployment

### Launch EC2 Instance

In the EC2 launch wizard:

- Give the server a name
- Select the Amazon Linux 2023 kernel-6.12 64-bit Arm AMI
- Select t4g.small instance type
- Add a key pair
- Add the security group from the prerequisites section
- Add the IAM EC2 instance role from above
- Paste the contents of `cloud-init.yaml` into the user data field
- Launch the instance

### What Does cloud-init.yaml Do?

The cloud-init script automatically:

- Installs required system packages (git, sqlite, nginx, etc.)
- Creates a dedicated `django` user
- Clones the application repository
- Installs UV Python package manager
- Sets up directory structure and permissions
- Configures nginx reverse proxy
- Installs Certbot for SSL certificates
- Sets up systemd services for automated database backups

## Configuration

### 1. SSH into the server and assume the django role:

```bash
ssh -i <path_to_private_key> ec2-user@<instance_ip>
sudo su - django
cd apps/rbennettio
```

### 2. Install Python Dependencies

```bash
uv sync
```

### 3. Configure Environment Variables

```bash
cp rbennettio/settings/app.env.example rbennettio/settings/app.env
vim rbennettio/settings/app.env
```

### 4. Source Environment Variables

```bash
source rbennettio/settings/app.env
```

### 5. Database Setup

```bash
# If restoring from backup:
aws s3 cp s3://<s3_path_to_db_backup_file> .
gunzip rbennettio.sqlite3.bak.gz
mv rbennettio.sqlite3.bak rbennettio.sqlite3

# Run migrations
uv run python3 manage.py migrate

# Collect static files
uv run python3 manage.py collectstatic

# Import initial data
uv run python3 manage.py import_rackets
uv run python3 manage.py import_strings
```

### 6. Test Database Backup

```bash
./deployment/scripts/backup_database_to_s3.sh
```

### 7. Start uWSGI Application Server

```bash
uv run uwsgi --ini deployment/django_rbennettio.ini
```

### Configure DNS

Configure Route 53 DNS records for the domain by adding an A record(s) pointing to the EC2 instance. Wait for DNS to propagate before continuing with SSL Certificate Setup.

## SSL Certificate Setup

### Initial Certificate Installation

After DNS has propagated, as ec2-user:

```bash
sudo certbot --nginx
```

This will:

- Automatically detect the nginx configuration
- Request certificates for the domains
- Update nginx configuration with SSL settings

### Certificate Renewal

Manual renewal, if needed, as ec2-user:

```bash
sudo certbot renew --dry-run
sudo certbot renew
```

## Database Management

### Automated Backups

Database backups run automatically daily at midnight UTC via systemd timer.

**Backup System Components:**

- **systemd Service**: `rbennettio-backup-database.service`
- **systemd Timer**: `rbennettio-backup-database.timer`
- **Script**: `deployment/scripts/backup_database_to_s3.sh`

### Backup Management Commands

```bash
# View service and timer status
sudo systemctl status rbennettio-backup-database.timer
sudo systemctl status rbennettio-backup-database.service

# View service and timer logs
sudo journalctl -u rbennettio-backup-database.service
sudo journalctl -u rbennettio-backup-database.timer

# Restart after config changes
sudo systemctl restart rbennettio-backup-database.service
sudo systemctl restart rbennettio-backup-database.timer
```

### Manual Database Restore

You'll need to:

- Find a suitable version of the database backup in S3
- Move the backup file to the server
- Decompress the backup file
- Restart uWSGI

## Application Updates

### Deployment Process for New Code
Once the server is configured, new code changes can be deployed as follows:

SSH into the server and assume the django role:

```bash
ssh -i <path_to_private_key> ec2-user@<instance_ip>
sudo su - django
cd apps/rbennettio
```

Pull new code to server. Run migrations and collect static files, if needed:

```bash
git pull origin main
uv run python3 manage.py migrate
uv run python3 manage.py collectstatic
```

Restart uWSGI:

**Graceful Restart:**

If no changes to static files are made, a soft restart can be made:

```bash
touch deployment/django_rbennettio.ini
```

**Hard Restart:**

Otherwise, perform a hard restart to pickup the new static files:

```bash
uv run uwsgi --stop /tmp/django_rbennettio.pid
uv run uwsgi --ini deployment/django_rbennettio.ini
```

**Alternative Stop Method:**

```bash
# Find PID and kill process
ps aux | grep uwsgi
kill -SIGINT <PID>
```

## Monitoring and Maintenance

### Log Locations

- **uWSGI Logs**: `/var/log/uwsgi/django_rbennettio.log`
- **Nginx Access**: `/var/log/nginx/access.log`
- **Nginx Error**: `/var/log/nginx/error.log`

### Configuration Files Reference

- **Nginx Config**: `/etc/nginx/conf.d/rbennettio.conf`
- **uWSGI Config**: `/home/django/apps/rbennettio/deployment/django_rbennettio.ini`
- **Environment Variables**: `/home/django/apps/rbennettio/rbennettio/settings/app.env`
- **Database Backup Service**: `/etc/systemd/system/rbennettio-backup-database.service`
- **Database Backup Timer**: `/etc/systemd/system/rbennettio-backup-database.timer`
