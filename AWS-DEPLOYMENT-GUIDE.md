# Sagesoft HRIS - AWS Deployment Guide

## Prerequisites
- AWS Account with appropriate permissions
- AWS CLI installed and configured
- SSH key pair for EC2 access

## Step 1: Create RDS Database

### 1.1 Create RDS MySQL Instance
```bash
aws rds create-db-instance \
    --db-instance-identifier sagesoft-hris-db \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0.35 \
    --master-username admin \
    --master-user-password "SagesoftHRIS2024!" \
    --allocated-storage 20 \
    --db-name sagesoft_hris \
    --vpc-security-group-ids sg-your-security-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --tags Key=Name,Value=Sagesoft-HRIS-Database
```

### 1.2 Get RDS Endpoint
```bash
aws rds describe-db-instances \
    --db-instance-identifier sagesoft-hris-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
```

## Step 2: Create Security Groups

### 2.1 Create Web Server Security Group
```bash
aws ec2 create-security-group \
    --group-name sagesoft-hris-web \
    --description "Security group for Sagesoft HRIS web server"

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
    --group-name sagesoft-hris-web \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Allow HTTPS traffic
aws ec2 authorize-security-group-ingress \
    --group-name sagesoft-hris-web \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Allow SSH access
aws ec2 authorize-security-group-ingress \
    --group-name sagesoft-hris-web \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```

### 2.2 Create Database Security Group
```bash
aws ec2 create-security-group \
    --group-name sagesoft-hris-db \
    --description "Security group for Sagesoft HRIS database"

# Allow MySQL access from web servers
aws ec2 authorize-security-group-ingress \
    --group-name sagesoft-hris-db \
    --protocol tcp \
    --port 3306 \
    --source-group sagesoft-hris-web
```

## Step 3: Launch EC2 Instance

### 3.1 Create User Data Script
Create a file named `user-data.sh`:
```bash
#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd php-cli php-json php-opcache php-xml php-gd php-devel php-intl php-mbstring php-bcmath php-zip git

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create web directory
mkdir -p /var/www/sagesoft-hris
chown apache:apache /var/www/sagesoft-hris
```

### 3.2 Launch EC2 Instance
```bash
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t3.micro \
    --key-name your-key-pair \
    --security-groups sagesoft-hris-web \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Sagesoft-HRIS-Web}]'
```

## Step 4: Deploy Application

### 4.1 Connect to EC2 Instance
```bash
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

### 4.2 Upload Application Files
```bash
# From your local machine
scp -i your-key.pem -r sagesoft-hris/ ec2-user@your-ec2-public-ip:~/
```

### 4.3 Set Up Application on Server
```bash
# On EC2 instance
sudo cp -r ~/sagesoft-hris/* /var/www/sagesoft-hris/
cd /var/www/sagesoft-hris

# Install dependencies
sudo -u apache composer install --no-dev --optimize-autoloader

# Set up environment
sudo cp .env.example .env
sudo chown apache:apache .env

# Generate application key
sudo -u apache php artisan key:generate
```

### 4.4 Configure Environment File
```bash
sudo nano /var/www/sagesoft-hris/.env
```

Update the following values:
```env
APP_NAME="Sagesoft HRIS"
APP_ENV=production
APP_DEBUG=false
APP_URL=http://your-ec2-public-ip

DB_CONNECTION=mysql
DB_HOST=your-rds-endpoint.region.rds.amazonaws.com
DB_PORT=3306
DB_DATABASE=sagesoft_hris
DB_USERNAME=admin
DB_PASSWORD=SagesoftHRIS2024!
```

### 4.5 Set Permissions
```bash
sudo chown -R apache:apache /var/www/sagesoft-hris
sudo chmod -R 755 /var/www/sagesoft-hris
sudo chmod -R 775 /var/www/sagesoft-hris/storage
sudo chmod -R 775 /var/www/sagesoft-hris/bootstrap/cache
```

## Step 5: Configure Apache

### 5.1 Create Virtual Host
```bash
sudo tee /etc/httpd/conf.d/sagesoft-hris.conf > /dev/null <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/sagesoft-hris/public
    ServerName your-domain.com
    
    <Directory /var/www/sagesoft-hris/public>
        AllowOverride All
        Require all granted
        DirectoryIndex index.php
    </Directory>
    
    ErrorLog /var/log/httpd/sagesoft_hris_error.log
    CustomLog /var/log/httpd/sagesoft_hris_access.log combined
</VirtualHost>
EOF
```

### 5.2 Restart Apache
```bash
sudo systemctl restart httpd
```

## Step 6: Initialize Database

### 6.1 Run Migrations and Seeders
```bash
cd /var/www/sagesoft-hris
sudo -u apache php artisan migrate --force
sudo -u apache php artisan db:seed --force
```

### 6.2 Optimize Application
```bash
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache
```

## Step 7: Test Application

### 7.1 Access Application
Open your browser and navigate to: `http://your-ec2-public-ip`

### 7.2 Login Credentials
- **Admin**: admin@sagesoft.com / password123
- **HR Manager**: hr@sagesoft.com / password123

## Step 8: Optional - Set Up Load Balancer

### 8.1 Create Application Load Balancer
```bash
aws elbv2 create-load-balancer \
    --name sagesoft-hris-alb \
    --subnets subnet-12345678 subnet-87654321 \
    --security-groups sg-your-alb-security-group
```

### 8.2 Create Target Group
```bash
aws elbv2 create-target-group \
    --name sagesoft-hris-targets \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-12345678 \
    --health-check-path /login
```

### 8.3 Register Targets
```bash
aws elbv2 register-targets \
    --target-group-arn arn:aws:elasticloadbalancing:region:account:targetgroup/sagesoft-hris-targets \
    --targets Id=i-1234567890abcdef0
```

## Step 9: Set Up Auto Scaling (Optional)

### 9.1 Create Launch Template
```bash
aws ec2 create-launch-template \
    --launch-template-name sagesoft-hris-template \
    --launch-template-data '{
        "ImageId":"ami-0abcdef1234567890",
        "InstanceType":"t3.micro",
        "KeyName":"your-key-pair",
        "SecurityGroupIds":["sg-your-security-group"],
        "UserData":"base64-encoded-user-data"
    }'
```

### 9.2 Create Auto Scaling Group
```bash
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name sagesoft-hris-asg \
    --launch-template LaunchTemplateName=sagesoft-hris-template,Version=1 \
    --min-size 1 \
    --max-size 3 \
    --desired-capacity 2 \
    --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/sagesoft-hris-targets \
    --availability-zones us-east-1a us-east-1b
```

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check RDS endpoint in .env file
   - Verify security group allows MySQL traffic
   - Ensure RDS instance is running

2. **Permission Errors**
   - Run: `sudo chown -R apache:apache /var/www/sagesoft-hris`
   - Run: `sudo chmod -R 775 /var/www/sagesoft-hris/storage`

3. **Apache Not Starting**
   - Check logs: `sudo tail -f /var/log/httpd/error_log`
   - Verify PHP modules: `php -m`

4. **Application Key Error**
   - Run: `sudo -u apache php artisan key:generate`

### Monitoring Commands
```bash
# Check Apache status
sudo systemctl status httpd

# Check PHP-FPM status
sudo systemctl status php-fpm

# View application logs
sudo tail -f /var/www/sagesoft-hris/storage/logs/laravel.log

# Check database connectivity
mysql -h your-rds-endpoint -u admin -p sagesoft_hris
```

## Security Best Practices

1. **Update .env file permissions**
   ```bash
   sudo chmod 600 /var/www/sagesoft-hris/.env
   ```

2. **Enable HTTPS with SSL certificate**
3. **Regularly update system packages**
4. **Use IAM roles instead of access keys**
5. **Enable CloudTrail for audit logging**
6. **Set up CloudWatch monitoring**

## Backup Strategy

1. **RDS Automated Backups**: Already enabled with 7-day retention
2. **Application Files**: Use S3 for regular backups
3. **Database Snapshots**: Create manual snapshots before major updates

Your Sagesoft HRIS system is now deployed and ready for use!
