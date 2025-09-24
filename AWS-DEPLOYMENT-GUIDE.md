# AWS Deployment Guide - Sagesoft HRIS

This guide provides step-by-step instructions for deploying the Sagesoft HRIS system on AWS with high availability, load balancing, and shared session storage.

## Architecture Overview

- **EC2 Instances**: Amazon Linux 2023 with Auto Scaling
- **Load Balancer**: Application Load Balancer with SSL termination
- **Database**: RDS MySQL 8.0
- **Session Storage**: Amazon EFS for shared sessions
- **SSL**: AWS Certificate Manager (ACM)

## Prerequisites

- AWS Account with appropriate permissions
- Domain name for SSL certificate
- Basic knowledge of AWS services

## Step 1: Create RDS Database

1. **Navigate to RDS Console**
2. **Create Database**
   - Engine: MySQL 8.0
   - Template: Production
   - DB Instance Identifier: `sagesoft-hris-production-rds`
   - Master Username: `admin`
   - Master Password: (secure password)
   - DB Instance Class: `db.t3.micro` (or larger for production)
   - Storage: 20 GB (or as needed)
   - VPC: Default or custom VPC
   - Subnet Group: Default
   - Security Group: Create new (allow port 3306 from EC2 security group)

3. **Note the RDS Endpoint** for later configuration

## Step 2: Create EFS File System

1. **Navigate to EFS Console**
2. **Create File System**
   - Name: `sagesoft-hris-sessions`
   - VPC: Same as RDS
   - Performance Mode: General Purpose
   - Throughput Mode: Provisioned (or Bursting)

3. **Configure Security Groups**
   - Allow NFS (port 2049) from EC2 security group

4. **Note the EFS ID** (e.g., `fs-0a91d618573c05bbd`)

## Step 3: Create Launch Template

1. **Navigate to EC2 Console > Launch Templates**
2. **Create Launch Template**
   - Name: `sagesoft-hris-launch-template`
   - AMI: Amazon Linux 2023
   - Instance Type: `t3.micro` (or larger)
   - Key Pair: Your existing key pair
   - Security Groups: Create new with HTTP/HTTPS access

3. **Add User Data Script:**
   ```bash
   #!/bin/bash
   yum update -y
   yum install -y amazon-efs-utils git httpd php php-mysqlnd composer

   # Mount EFS
   mkdir -p /mnt/efs-sessions
   mount -t efs fs-0a91d618573c05bbd.efs.us-east-1.amazonaws.com:/ /mnt/efs-sessions

   # Add to fstab for persistence
   echo "fs-0a91d618573c05bbd.efs.us-east-1.amazonaws.com:/ /mnt/efs-sessions efs defaults,_netdev 0 0" >> /etc/fstab

   # Create Laravel session directory
   mkdir -p /mnt/efs-sessions/laravel-sessions
   chown -R apache:apache /mnt/efs-sessions/laravel-sessions
   chmod -R 775 /mnt/efs-sessions/laravel-sessions

   # Clone and setup application
   cd /var/www
   git clone https://github.com/jcconstantino/sagesoft-hris.git
   cd sagesoft-hris
   chmod +x deploy.sh
   ./deploy.sh

   # Configure environment
   cp .env.example .env
   sed -i 's/DB_HOST=.*/DB_HOST=your-rds-endpoint.region.rds.amazonaws.com/' .env
   sed -i 's/DB_DATABASE=.*/DB_DATABASE=sagesoft_hris/' .env
   sed -i 's/DB_USERNAME=.*/DB_USERNAME=admin/' .env
   sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=your-rds-password/' .env
   sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=file/' .env

   # Generate app key and setup database
   sudo -u apache php artisan key:generate
   sudo -u apache php artisan migrate --force
   sudo -u apache php artisan db:seed --force

   # Start services
   systemctl enable httpd
   systemctl start httpd
   ```

   **Replace:**
   - `fs-0a91d618573c05bbd` with your EFS ID
   - `your-rds-endpoint.region.rds.amazonaws.com` with your RDS endpoint
   - `your-rds-password` with your RDS password

## Step 4: Create Application Load Balancer

1. **Navigate to EC2 Console > Load Balancers**
2. **Create Application Load Balancer**
   - Name: `sagesoft-hris-alb`
   - Scheme: Internet-facing
   - IP Address Type: IPv4
   - VPC: Same as RDS and EFS
   - Subnets: Select at least 2 availability zones

3. **Configure Security Groups**
   - Allow HTTP (80) and HTTPS (443) from anywhere

4. **Configure Listeners**
   - HTTP:80 → Redirect to HTTPS
   - HTTPS:443 → Forward to target group

5. **Create Target Group**
   - Name: `sagesoft-hris-targets`
   - Protocol: HTTP
   - Port: 80
   - Health Check Path: `/login`

## Step 5: Request SSL Certificate

1. **Navigate to Certificate Manager**
2. **Request Certificate**
   - Domain: `your-domain.com`
   - Validation: DNS validation
   - Follow DNS validation steps

3. **Attach Certificate to Load Balancer**
   - Edit HTTPS listener
   - Select your certificate

## Step 6: Create Auto Scaling Group

1. **Navigate to EC2 Console > Auto Scaling Groups**
2. **Create Auto Scaling Group**
   - Name: `sagesoft-hris-asg`
   - Launch Template: Select your template
   - VPC: Same as other resources
   - Subnets: Select multiple AZs
   - Load Balancer: Attach to your ALB target group
   - Health Checks: ELB + EC2
   - Desired Capacity: 2
   - Min: 1, Max: 4

## Step 7: Configure DNS

1. **Update your domain's DNS**
2. **Create CNAME or A record**
   - Point your domain to the ALB DNS name

## Step 8: Final Configuration

### Update Environment Variables

SSH into one of your instances and update the `.env` file:

```bash
# SSH to instance
ssh -i your-key.pem ec2-user@instance-ip

# Edit environment
sudo nano /var/www/sagesoft-hris/.env
```

Update these values:
```env
APP_NAME="Sagesoft HRIS"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=your-rds-endpoint.region.rds.amazonaws.com
DB_PORT=3306
DB_DATABASE=sagesoft_hris
DB_USERNAME=admin
DB_PASSWORD=your-rds-password

SESSION_DRIVER=file
SESSION_SECURE_COOKIE=true
SESSION_DOMAIN=.your-domain.com

FORCE_HTTPS=true
```

### Clear Caches
```bash
sudo -u apache php artisan config:clear
sudo -u apache php artisan cache:clear
sudo -u apache php artisan route:clear
```

## Troubleshooting

### Common Issues

1. **500 Internal Server Error**
   ```bash
   # Check Apache logs
   sudo tail -f /var/log/httpd/error_log
   
   # Check Laravel logs
   sudo tail -f /var/www/sagesoft-hris/storage/logs/laravel.log
   
   # Fix permissions
   sudo chown -R apache:apache /var/www/sagesoft-hris/storage
   sudo chmod -R 775 /var/www/sagesoft-hris/storage
   ```

2. **Database Connection Issues**
   ```bash
   # Test database connection
   mysql -h your-rds-endpoint -u admin -p
   
   # Check security groups allow port 3306
   ```

3. **EFS Mount Issues**
   ```bash
   # Check EFS mount
   df -h | grep efs
   
   # Remount if needed
   sudo mount -a
   
   # Check security groups allow port 2049
   ```

4. **SSL/HTTPS Issues**
   ```bash
   # Check certificate status in ACM
   # Verify DNS validation
   # Check load balancer listener configuration
   ```

### Health Checks

```bash
# Check application status
curl -I http://localhost/login

# Check EFS mount
ls -la /mnt/efs-sessions/laravel-sessions/

# Check database connectivity
sudo -u apache php artisan tinker --execute="DB::connection()->getPdo();"
```

## Security Considerations

1. **Security Groups**: Restrict access to necessary ports only
2. **RDS**: Enable encryption at rest and in transit
3. **EFS**: Enable encryption
4. **SSL**: Use strong cipher suites
5. **Application**: Keep Laravel and dependencies updated

## Monitoring and Maintenance

1. **CloudWatch**: Set up monitoring for EC2, RDS, and ALB
2. **Backups**: Configure automated RDS backups
3. **Updates**: Regular security updates via Systems Manager
4. **Logs**: Centralize logs using CloudWatch Logs

## Cost Optimization

1. **Instance Types**: Use appropriate instance sizes
2. **Reserved Instances**: For predictable workloads
3. **Auto Scaling**: Scale based on demand
4. **RDS**: Use appropriate instance class and storage type

## Default Login Credentials

- **Administrator**: admin@sagesoft.com / password123
- **HR Manager**: hr@sagesoft.com / password123

**Important**: Change these credentials immediately after deployment!

---

This deployment provides a production-ready, highly available Sagesoft HRIS system on AWS with proper security, scalability, and monitoring capabilities.
