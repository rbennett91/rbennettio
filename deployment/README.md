# Production Deployment

## Infrastructure
TBD - describe infrastructure, ec2 instance, other aws resources (security groups, roles, ec2 instance role),

this application is deployed on aws infrastructure.

compute: reserved ec2 instance, t4g.small, running Amazon Linux 2023 kernel-6.12 AMI

s3 bucket used for sqlite3 database backups. ec2 instance role with iam created for access to s3 bucket and attached to ec2 instance. ec2 security group allows http and https access. cloud-init.yaml is supplied as user data for ec2 instance setup. route53 for dns.

the django application uses:
python3 3.13
django 5.2.1
sqlite3 3.40

django is served bu uwsgi which sits behind an nginx reverse proxy.

## Configuration After ec2 launch
<ssh to ec2 instance>
sudo su - django
cd apps/rbennettio
uv sync

cp rbennettio/settings/app.env.example rbennettio/settings/app.env
vim rbennettio/settings/app.env
    add secret key and allowed hostname ("rbennett.io, www.rbennett.io")
source rbennettio/settings/app.env

copy racket_stringer.sqlite3 into repository:
# aws s3 cp s3://rbennettio-private/database_backups/production/rbennettio.sqlite3 .
uv run python3 manage.py migrate
uv run python3 manage.py collectstatic

uv run python3 manage.py import_rackets
uv run python3 manage.py import_strings

test database backup script:
./deployment/scripts/backup_database_to_s3.sh

start uwsgi:
uv run uwsgi --ini deployment/django_rbennettio.ini

if you're moving hosts, update dns, wait for dns to update. then run certbot. this will be interactive:
sudo certbot --nginx


## Backup and Restore SQLite3 Database
TBD - describe s3 bucket, versioning, s3 lifecycle management policy, reasoning for sqlite3 over postgresql

database backups are scheduled at midnight UTC via systemd timer.

systemd timer management:
# View timer status
sudo systemctl status backup-database.timer
# View service logs
sudo journalctl -u rbennettio-backup-database.service -f
# View timer logs
sudo journalctl -u rbennettio-backup-database.timer -f
# Test the service manually
sudo systemctl start backup-database.service
# Restart timer after config changes
sudo systemctl daemon-reload
sudo systemctl restart backup-database.timer


explain manual process for restoring db backup from s3. download the version of the database file from s3, copy to the code repository on the server


## deploying new code
cd to repo, git pull, migrate, collectstatic, restart uwsgi

### stop and start uwsgi
# stop existing uwsgi processes and restart (if necessary):
# it is also possible to `kill -SIGINT <PID>` after finding the PID.
uwsgi --stop /tmp/django_rbennettio.pid
uwsgi --ini django_rbennettio.ini

# alternatiely, do a soft restart:
touch deployment/django_rbennettio.ini
