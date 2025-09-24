# Sagesoft HRIS Management System

A comprehensive Human Resource Information System built with Laravel, featuring employee management, authentication, and a modern responsive interface.

## Features

- **User Authentication**: Secure login system with role-based access
- **Employee Management**: Complete CRUD operations for employee records
- **Dashboard**: Overview of employee statistics and recent activities
- **Responsive Design**: Mobile-friendly interface with Bootstrap
- **Sagesoft Branding**: Professional corporate design
- **AWS Ready**: Optimized for deployment on Amazon Linux 2/2023
- **Load Balancer Support**: SSL termination with AWS ACM
- **Shared Sessions**: EFS-based session storage for multi-server deployments

## Technology Stack

- **Backend**: PHP 8.1+, Laravel 10
- **Database**: MySQL 8.0 / Amazon RDS
- **Frontend**: Bootstrap 5, Font Awesome
- **Server**: Apache HTTP Server
- **Platform**: Amazon Linux 2/2023
- **Storage**: Amazon EFS for shared sessions
- **SSL**: AWS Certificate Manager (ACM)

## Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/jcconstantino/sagesoft-hris.git
   cd sagesoft-hris
   ```

2. **Install dependencies**
   ```bash
   composer install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. **Configure database in .env**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=sagesoft_hris
   DB_USERNAME=root
   DB_PASSWORD=
   ```

5. **Run migrations and seeders**
   ```bash
   php artisan migrate
   php artisan db:seed
   ```

6. **Start development server**
   ```bash
   php artisan serve
   ```

### AWS Production Deployment

For detailed AWS deployment instructions, see [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)

#### Quick AWS Deployment

1. **Launch EC2 instance with Amazon Linux 2023**

2. **Clone and deploy**
   ```bash
   git clone https://github.com/jcconstantino/sagesoft-hris.git
   cd sagesoft-hris
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure environment**
   ```bash
   sudo cp .env.example .env
   sudo nano .env
   # Update database credentials and other settings
   ```

4. **Initialize database**
   ```bash
   ./setup-database.sh
   ```

5. **Configure SSL (optional)**
   ```bash
   ./setup-ssl.sh
   ```

## Default Login Credentials

- **Administrator**: admin@sagesoft.com / password123
- **HR Manager**: hr@sagesoft.com / password123

## System Requirements

### Minimum Requirements
- PHP 8.1 or higher
- MySQL 5.7 or higher / MariaDB 10.3+
- Apache 2.4 or higher
- 1GB RAM
- 1GB disk space

### Recommended for Production
- PHP 8.1+
- MySQL 8.0+ / MariaDB 10.6+
- Apache 2.4+
- 2GB RAM
- 10GB disk space
- SSL certificate
- Amazon EFS for shared sessions (load balancer setup)

### AWS Production Requirements
- Amazon Linux 2023
- RDS MySQL 8.0
- Application Load Balancer with SSL termination
- Amazon EFS for session storage
- Auto Scaling Group for high availability

## Application Structure

```
sagesoft-hris/
├── app/
│   ├── Console/
│   │   └── Kernel.php
│   ├── Exceptions/
│   │   └── Handler.php
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Controller.php
│   │   │   ├── AuthController.php
│   │   │   ├── DashboardController.php
│   │   │   └── EmployeeController.php
│   │   ├── Kernel.php
│   │   └── Middleware/
│   │       └── TrustProxies.php
│   ├── Models/
│   │   ├── User.php
│   │   └── Employee.php
│   └── Providers/
│       ├── AppServiceProvider.php
│       ├── AuthServiceProvider.php
│       ├── EventServiceProvider.php
│       └── RouteServiceProvider.php
├── bootstrap/
│   ├── app.php
│   └── cache/
├── config/
│   ├── app.php
│   ├── auth.php
│   ├── cache.php
│   ├── database.php
│   ├── session.php
│   └── view.php
├── database/
│   ├── migrations/
│   └── seeders/
├── public/
│   ├── .htaccess
│   └── index.php
├── resources/views/
│   ├── auth/
│   ├── employees/
│   └── layouts/
├── routes/
│   ├── console.php
│   └── web.php
├── storage/
│   ├── framework/
│   │   ├── cache/
│   │   ├── sessions/
│   │   └── views/
│   └── logs/
├── artisan
├── deploy.sh
├── .env.example
└── AWS-DEPLOYMENT-GUIDE.md
```

## Key Features

### Employee Management
- Create, read, update, delete employee records
- Employee search and filtering
- Pagination for large datasets
- Soft delete functionality

### Dashboard
- Employee statistics overview
- Recent employee activities
- Quick access to key functions

### Security
- User authentication and authorization
- Role-based access control
- CSRF protection
- Input validation and sanitization

### Responsive Design
- Mobile-friendly interface
- Bootstrap 5 framework
- Professional Sagesoft branding
- Intuitive navigation

## API Endpoints

The system uses web routes for all functionality:

- `GET /` - Redirect to login
- `GET /login` - Login form
- `POST /login` - Authenticate user
- `POST /logout` - Logout user
- `GET /dashboard` - Dashboard (authenticated)
- `GET /employees` - Employee list (authenticated)
- `GET /employees/create` - Create employee form
- `POST /employees` - Store new employee
- `GET /employees/{id}` - View employee details
- `GET /employees/{id}/edit` - Edit employee form
- `PUT /employees/{id}` - Update employee
- `DELETE /employees/{id}` - Delete employee

## Database Schema

### Users Table
- id, name, email, password, role, timestamps

### Employees Table
- id, employee_id, first_name, last_name, email, phone
- department, position, hire_date, salary, status
- timestamps, soft_deletes

## Deployment Scripts

### deploy.sh
Automated deployment script for Amazon Linux 2023 that:
- Detects package manager (dnf vs yum)
- Installs all required packages (PHP, Apache, MySQL client)
- Configures Apache and PHP-FPM
- Sets up the application with proper permissions
- Creates helper scripts for database and SSL setup

### Helper Scripts
- `setup-database.sh` - Initialize database with migrations and seeders
- `setup-ssl.sh` - Configure SSL certificate with Let's Encrypt
- `monitor.sh` - System health check and monitoring
- `backup.sh` - Create system and database backups

## Load Balancer Configuration

### EFS Session Storage
For load-balanced deployments, sessions are stored on Amazon EFS:

1. **Mount EFS on all instances:**
   ```bash
   sudo mkdir -p /mnt/efs-sessions
   sudo mount -t efs fs-your-efs-id.efs.region.amazonaws.com:/ /mnt/efs-sessions
   ```

2. **Add to /etc/fstab:**
   ```
   fs-your-efs-id.efs.region.amazonaws.com:/ /mnt/efs-sessions efs defaults,_netdev 0 0
   ```

3. **Configure Laravel session path:**
   ```php
   // config/session.php
   'files' => '/mnt/efs-sessions/laravel-sessions',
   ```

### SSL Termination
When using AWS Application Load Balancer with ACM certificates:

1. **TrustProxies middleware** handles forwarded headers
2. **HTTPS detection** from X-Forwarded-Proto header
3. **Secure cookie settings** for HTTPS-only sessions

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   sudo chown -R apache:apache /var/www/sagesoft-hris
   sudo chmod -R 775 /var/www/sagesoft-hris/storage
   ```

2. **Database Connection Issues**
   - Verify database credentials in .env
   - Check database server status
   - Ensure proper security group configuration

3. **Apache Configuration**
   ```bash
   sudo systemctl restart httpd
   sudo tail -f /var/log/httpd/error_log
   ```

### Monitoring Commands
```bash
# Check application status
./monitor.sh

# View application logs
sudo tail -f /var/www/sagesoft-hris/storage/logs/laravel.log

# Check Apache status
sudo systemctl status httpd
```

## Support

For technical support or questions about the Sagesoft HRIS system, please contact the development team.

## License

This project is proprietary software developed by Sagesoft Company.

---

**Sagesoft HRIS** - Professional Human Resource Management Solution
