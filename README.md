# Sagesoft HRIS Management System

A comprehensive Human Resource Information System built with Laravel, featuring employee management, authentication, and a modern responsive interface.

## Features

- **User Authentication**: Secure login system with role-based access
- **Employee Management**: Complete CRUD operations for employee records
- **Dashboard**: Overview of employee statistics and recent activities
- **Responsive Design**: Mobile-friendly interface with Bootstrap
- **Sagesoft Branding**: Professional corporate design
- **AWS Ready**: Optimized for deployment on Amazon Linux 2

## Technology Stack

- **Backend**: PHP 8.1, Laravel 10
- **Database**: MySQL 8.0
- **Frontend**: Bootstrap 5, Font Awesome
- **Server**: Apache HTTP Server
- **Platform**: Amazon Linux 2

## Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
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

### AWS Deployment

For detailed AWS deployment instructions, see [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)

#### Quick AWS Deployment

1. **Upload files to EC2 instance**
   ```bash
   scp -i your-key.pem -r sagesoft-hris/ ec2-user@your-ec2-ip:~/
   ```

2. **Run automated deployment**
   ```bash
   ssh -i your-key.pem ec2-user@your-ec2-ip
   cd sagesoft-hris
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure database and initialize**
   ```bash
   # Edit database credentials
   sudo nano /var/www/sagesoft-hris/.env
   
   # Initialize database
   ./setup-database.sh
   ```

## Default Login Credentials

- **Administrator**: admin@sagesoft.com / password123
- **HR Manager**: hr@sagesoft.com / password123

## System Requirements

### Minimum Requirements
- PHP 8.1 or higher
- MySQL 5.7 or higher
- Apache 2.4 or higher
- 1GB RAM
- 1GB disk space

### Recommended for Production
- PHP 8.1+
- MySQL 8.0+
- Apache 2.4+
- 2GB RAM
- 10GB disk space
- SSL certificate

## Application Structure

```
sagesoft-hris/
├── app/
│   ├── Http/Controllers/
│   │   ├── AuthController.php
│   │   ├── DashboardController.php
│   │   └── EmployeeController.php
│   └── Models/
│       ├── User.php
│       └── Employee.php
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/views/
│   ├── auth/
│   ├── employees/
│   └── layouts/
├── routes/web.php
├── deploy.sh
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
Automated deployment script for Amazon Linux 2 that:
- Installs all required packages
- Configures Apache and PHP
- Sets up the application
- Creates helper scripts

### Helper Scripts
- `setup-database.sh` - Initialize database
- `setup-ssl.sh` - Configure SSL certificate
- `monitor.sh` - System health check
- `backup.sh` - Create system backups

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
