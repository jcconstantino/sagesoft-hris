#!/bin/bash

# Amazon Q Business Chatbot Deployment Script
# For Sagesoft HRIS System

set -e

echo "=========================================="
echo "Amazon Q Business Chatbot Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "artisan" ]; then
    print_error "Please run this script from the Laravel application root directory"
    exit 1
fi

print_status "Fixing file permissions for composer..."
sudo chown apache:apache composer.json composer.lock 2>/dev/null || true
sudo chown -R apache:apache vendor/ 2>/dev/null || true

print_status "Installing AWS SDK for PHP..."
sudo -u apache composer require aws/aws-sdk-php

print_status "Creating service directories..."
sudo mkdir -p app/Services
sudo mkdir -p resources/views/components

print_status "Setting proper permissions..."
sudo chown -R apache:apache app/Services
sudo chown -R apache:apache resources/views/components
sudo chmod -R 755 app/Services
sudo chmod -R 755 resources/views/components

print_status "Clearing Laravel caches..."
sudo -u apache php artisan config:clear
sudo -u apache php artisan route:clear
sudo -u apache php artisan view:clear

print_status "Restarting web server..."
sudo systemctl restart httpd

print_status "Checking environment configuration..."
if ! grep -q "Q_BUSINESS_APPLICATION_ID" .env 2>/dev/null; then
    print_warning "Q_BUSINESS_APPLICATION_ID not found in .env file"
    echo "Please add the following to your .env file:"
    echo ""
    echo "# Amazon Q Business Configuration"
    echo "Q_BUSINESS_APPLICATION_ID=your-application-id"
    echo "Q_BUSINESS_INDEX_ID=your-index-id"
    echo "AWS_ACCESS_KEY_ID=your-access-key"
    echo "AWS_SECRET_ACCESS_KEY=your-secret-key"
    echo "AWS_DEFAULT_REGION=us-east-1"
    echo ""
fi

print_status "Testing chatbot service..."
if sudo -u apache php artisan tinker --execute="app(App\Services\QBusinessService::class)->isConfigured() ? 'Configured' : 'Not configured'" 2>/dev/null | grep -q "Configured"; then
    print_status "Chatbot service is properly configured!"
else
    print_warning "Chatbot service needs configuration. Please update your .env file."
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure Amazon Q Business in AWS Console"
echo "2. Update .env file with Q Business credentials"
echo "3. Upload HR documents to S3 knowledge base"
echo "4. Test the chatbot functionality"
echo ""
echo "The chatbot widget will appear for authenticated users."
echo "Access your application and look for the chat icon in the bottom-right corner."
echo ""
