# Deployment Checklist - Sagesoft HRIS

Use this checklist to ensure a successful deployment of the Sagesoft HRIS system.

## Pre-Deployment

### AWS Resources
- [ ] RDS MySQL 8.0 instance created
- [ ] EFS file system created
- [ ] VPC and subnets configured
- [ ] Security groups configured (HTTP/HTTPS, MySQL, NFS)
- [ ] SSL certificate requested and validated in ACM
- [ ] Domain name configured

### Local Setup
- [ ] AWS CLI configured with appropriate permissions
- [ ] SSH key pair created for EC2 access
- [ ] Repository cloned locally
- [ ] Environment variables prepared

## Deployment Steps

### 1. Database Setup
- [ ] RDS instance accessible
- [ ] Database credentials secured
- [ ] Security group allows EC2 access to port 3306
- [ ] Test connection from EC2 instance

### 2. EFS Configuration
- [ ] EFS file system created
- [ ] Mount targets in correct subnets
- [ ] Security group allows NFS (port 2049)
- [ ] Test mount from EC2 instance

### 3. Launch Template
- [ ] Launch template created with correct AMI
- [ ] User data script includes all necessary commands
- [ ] EFS ID updated in user data
- [ ] RDS endpoint updated in user data
- [ ] Security groups attached

### 4. Load Balancer
- [ ] Application Load Balancer created
- [ ] Target group configured
- [ ] Health check path set to `/login`
- [ ] SSL certificate attached to HTTPS listener
- [ ] HTTP redirects to HTTPS

### 5. Auto Scaling Group
- [ ] ASG created with launch template
- [ ] Desired capacity set appropriately
- [ ] Health checks enabled (ELB + EC2)
- [ ] Multiple availability zones selected

### 6. Application Configuration
- [ ] `.env` file configured with production settings
- [ ] Database migrations run successfully
- [ ] Seeders executed (if needed)
- [ ] Application key generated
- [ ] File permissions set correctly

## Post-Deployment Verification

### Functionality Tests
- [ ] Application loads without errors
- [ ] Login functionality works
- [ ] Database operations successful
- [ ] Session persistence across requests
- [ ] HTTPS enforced properly
- [ ] Load balancer health checks passing

### Security Checks
- [ ] SSL certificate valid and trusted
- [ ] HTTP redirects to HTTPS
- [ ] Default passwords changed
- [ ] Security groups properly configured
- [ ] Database access restricted to application servers
- [ ] EFS access restricted to application servers

### Performance Tests
- [ ] Page load times acceptable
- [ ] Database queries performing well
- [ ] Auto scaling triggers working
- [ ] Session storage on EFS functioning
- [ ] Multiple instances serving traffic

### Monitoring Setup
- [ ] CloudWatch monitoring enabled
- [ ] Log aggregation configured
- [ ] Alerts set up for critical metrics
- [ ] Backup strategy implemented

## Configuration Files Checklist

### Required Laravel Files
- [ ] `artisan` - Command line interface
- [ ] `bootstrap/app.php` - Application bootstrap
- [ ] `config/app.php` - Application configuration
- [ ] `config/auth.php` - Authentication configuration
- [ ] `config/cache.php` - Cache configuration
- [ ] `config/database.php` - Database configuration
- [ ] `config/session.php` - Session configuration
- [ ] `config/view.php` - View configuration
- [ ] `app/Http/Kernel.php` - HTTP kernel
- [ ] `app/Console/Kernel.php` - Console kernel
- [ ] `app/Exceptions/Handler.php` - Exception handler
- [ ] `app/Http/Controllers/Controller.php` - Base controller
- [ ] `app/Http/Middleware/TrustProxies.php` - Proxy middleware
- [ ] `app/Providers/AppServiceProvider.php` - App service provider
- [ ] `app/Providers/AuthServiceProvider.php` - Auth service provider
- [ ] `app/Providers/EventServiceProvider.php` - Event service provider
- [ ] `app/Providers/RouteServiceProvider.php` - Route service provider
- [ ] `public/.htaccess` - URL rewriting and HTTPS detection
- [ ] `public/index.php` - Application entry point
- [ ] `routes/console.php` - Console routes

### Environment Configuration
- [ ] `APP_NAME` set to "Sagesoft HRIS"
- [ ] `APP_ENV` set to "production"
- [ ] `APP_DEBUG` set to "false"
- [ ] `APP_URL` set to your domain with HTTPS
- [ ] `DB_*` variables configured for RDS
- [ ] `SESSION_DRIVER` set to "file"
- [ ] `SESSION_SECURE_COOKIE` set to "true"
- [ ] `SESSION_DOMAIN` set to your domain
- [ ] `FORCE_HTTPS` set to "true"

### File Permissions
- [ ] Application directory owned by `apache:apache`
- [ ] Storage directory writable (775)
- [ ] Bootstrap cache directory writable (775)
- [ ] EFS session directory writable by apache user

## Rollback Plan

### If Deployment Fails
- [ ] Revert to previous Auto Scaling Group configuration
- [ ] Restore database from backup if needed
- [ ] Update DNS to point to working environment
- [ ] Document issues for troubleshooting

### Emergency Contacts
- [ ] AWS Support contact information
- [ ] Database administrator contact
- [ ] Network administrator contact
- [ ] Application developer contact

## Maintenance Tasks

### Regular Tasks
- [ ] Monitor application logs
- [ ] Check system resource usage
- [ ] Verify backup completion
- [ ] Review security group rules
- [ ] Update SSL certificates before expiration

### Monthly Tasks
- [ ] Review and apply security updates
- [ ] Analyze performance metrics
- [ ] Test disaster recovery procedures
- [ ] Review and optimize costs

## Success Criteria

The deployment is considered successful when:
- [ ] Application is accessible via HTTPS
- [ ] All functionality works as expected
- [ ] Load balancer distributes traffic properly
- [ ] Sessions persist across server instances
- [ ] Database operations complete successfully
- [ ] Monitoring and alerting are functional
- [ ] Security requirements are met
- [ ] Performance meets expectations

---

**Note**: Keep this checklist updated as the application evolves and new requirements are added.
