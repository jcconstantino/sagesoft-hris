#!/bin/bash

# Sagesoft HRIS Automated Deployment Script for Amazon Linux 2
# This script automates the complete deployment process

set -e

echo "=========================================="
echo "Sagesoft HRIS Deployment Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Starting Sagesoft HRIS deployment..."

# Update system
print_status "Updating system packages..."
if command -v dnf &> /dev/null; then
    sudo dnf update -y
else
    sudo yum update -y
fi

# Install Apache
print_status "Installing Apache web server..."
if command -v dnf &> /dev/null; then
    sudo dnf install -y httpd
else
    sudo yum install -y httpd
fi
sudo systemctl start httpd
sudo systemctl enable httpd

# Install PHP 8.1 and extensions
print_status "Installing PHP and required extensions..."
# Detect the system and install PHP accordingly
if command -v dnf &> /dev/null; then
    # Amazon Linux 2023 or newer
    sudo dnf install -y php php-cli php-fpm php-mysqlnd php-json php-opcache php-xml php-gd php-devel php-intl php-mbstring php-bcmath php-zip
elif command -v amazon-linux-extras &> /dev/null; then
    # Amazon Linux 2 with extras
    sudo amazon-linux-extras install -y php8.1
    sudo yum install -y php-cli php-fpm php-mysqlnd php-json php-opcache php-xml php-gd php-devel php-intl php-mbstring php-bcmath php-zip
else
    # Fallback for other systems
    sudo yum install -y php php-cli php-fpm php-mysqlnd php-json php-opcache php-xml php-gd php-devel php-intl php-mbstring php-bcmath php-zip
fi

# Install Composer
print_status "Installing Composer..."
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
else
    print_status "Composer already installed"
fi

# Install MySQL client (optional - for database operations)
print_status "Installing MySQL client..."
if command -v dnf &> /dev/null; then
    sudo dnf install -y mariadb105 2>/dev/null || sudo dnf install -y mysql 2>/dev/null || print_warning "MySQL client not available, you can install it later if needed"
else
    sudo yum install -y mysql 2>/dev/null || sudo yum install -y mariadb 2>/dev/null || print_warning "MySQL client not available, you can install it later if needed"
fi

# Create application directory
print_status "Setting up application directory..."
sudo mkdir -p /var/www/sagesoft-hris
sudo chown -R apache:apache /var/www/sagesoft-hris

# Copy application files
print_status "Copying application files..."
sudo cp -r . /var/www/sagesoft-hris/
cd /var/www/sagesoft-hris

# Install PHP dependencies
print_status "Installing PHP dependencies..."
sudo -u apache composer install --no-dev --optimize-autoloader

# Set up environment file
print_status "Setting up environment configuration..."
sudo cp .env.example .env
sudo chown apache:apache .env

# Generate application key
print_status "Generating application key..."
sudo -u apache php artisan key:generate

# Configure Apache Virtual Host
print_status "Configuring Apache virtual host..."
sudo tee /etc/httpd/conf.d/sagesoft-hris.conf > /dev/null <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/sagesoft-hris/public
    ServerName localhost
    
    <Directory /var/www/sagesoft-hris/public>
        AllowOverride All
        Require all granted
        DirectoryIndex index.php
        
        # Enable URL rewriting
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    ErrorLog /var/log/httpd/sagesoft_hris_error.log
    CustomLog /var/log/httpd/sagesoft_hris_access.log combined
</VirtualHost>
EOF

# Set proper permissions
print_status "Setting file permissions..."
sudo chown -R apache:apache /var/www/sagesoft-hris
sudo chmod -R 755 /var/www/sagesoft-hris
sudo chmod -R 775 /var/www/sagesoft-hris/storage
sudo chmod -R 775 /var/www/sagesoft-hris/bootstrap/cache
sudo chmod 600 /var/www/sagesoft-hris/.env

# Configure PHP-FPM
print_status "Configuring PHP-FPM..."
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Enable mod_rewrite and mod_headers
print_status "Enabling Apache modules..."
sudo sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/#LoadModule headers_module/LoadModule headers_module/' /etc/httpd/conf/httpd.conf

# Restart Apache
print_status "Restarting Apache..."
sudo systemctl restart httpd

# Create database setup script
print_status "Creating database setup script..."
cat > setup-database.sh << 'EOF'
#!/bin/bash
echo "Setting up database..."

# Check if .env file has database configuration
if grep -q "DB_HOST=your-rds-endpoint" .env; then
    echo "Please update the .env file with your RDS database credentials first!"
    echo "Edit /var/www/sagesoft-hris/.env and update:"
    echo "  DB_HOST=your-rds-endpoint.region.rds.amazonaws.com"
    echo "  DB_DATABASE=sagesoft_hris"
    echo "  DB_USERNAME=admin"
    echo "  DB_PASSWORD=your-password"
    exit 1
fi

# Run migrations
php artisan migrate --force

# Seed database with sample data
php artisan db:seed --force

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Database setup complete!"
echo "You can now access the application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "Login credentials:"
echo "  Admin: admin@sagesoft.com / password123"
echo "  HR Manager: hr@sagesoft.com / password123"
EOF

chmod +x setup-database.sh

# Create SSL setup script
print_status "Creating SSL setup script..."
cat > setup-ssl.sh << 'EOF'
#!/bin/bash
echo "Setting up SSL certificate..."

# Install Certbot
sudo yum install -y certbot python3-certbot-apache

# Note: Replace 'your-domain.com' with your actual domain
echo "To enable SSL, run:"
echo "sudo certbot --apache -d your-domain.com"
echo ""
echo "Make sure your domain points to this server's IP address first!"
EOF

chmod +x setup-ssl.sh

# Create monitoring script
print_status "Creating monitoring script..."
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "=== Sagesoft HRIS System Status ==="
echo ""

echo "Apache Status:"
sudo systemctl status httpd --no-pager -l

echo ""
echo "PHP-FPM Status:"
sudo systemctl status php-fpm --no-pager -l

echo ""
echo "Disk Usage:"
df -h /var/www/sagesoft-hris

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "Recent Apache Errors:"
sudo tail -n 10 /var/log/httpd/sagesoft_hris_error.log

echo ""
echo "Recent Application Logs:"
sudo tail -n 10 /var/www/sagesoft-hris/storage/logs/laravel.log 2>/dev/null || echo "No application logs found"
EOF

chmod +x monitor.sh

# Create backup script
print_status "Creating backup script..."
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ec2-user/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating backup of application files..."
tar -czf $BACKUP_DIR/sagesoft-hris-files-$DATE.tar.gz -C /var/www sagesoft-hris

echo "Creating database backup..."
# Note: Update with your actual database credentials
mysqldump -h your-rds-endpoint -u admin -p sagesoft_hris > $BACKUP_DIR/sagesoft-hris-db-$DATE.sql

echo "Backup completed: $BACKUP_DIR/"
ls -la $BACKUP_DIR/
EOF

chmod +x backup.sh

print_status "Deployment completed successfully!"
print_warning "Next steps:"
echo "1. Update database credentials in /var/www/sagesoft-hris/.env"
echo "2. Run ./setup-database.sh to initialize the database"
echo "3. Access your application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 --max-time 5 2>/dev/null || curl -s http://checkip.amazonaws.com 2>/dev/null || echo 'your-server-ip')"
echo ""
echo "Available scripts:"
echo "  ./setup-database.sh  - Initialize database"
echo "  ./setup-ssl.sh       - Set up SSL certificate"
echo "  ./monitor.sh         - Check system status"
echo "  ./backup.sh          - Create system backup"
echo ""
echo "Login credentials:"
echo "  Admin: admin@sagesoft.com / password123"
echo "  HR Manager: hr@sagesoft.com / password123"
echo ""
print_status "Sagesoft HRIS is ready for use!"
