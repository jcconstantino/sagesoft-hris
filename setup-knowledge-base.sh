#!/bin/bash

# Amazon Q Business Knowledge Base Setup Script
# Creates S3 bucket and uploads HR documents

set -e

# Configuration
BUCKET_NAME="sagesoft-hris-knowledge-base-$(date +%s)"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
APP_NAME="sagesoft-hris-assistant"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "Amazon Q Business Knowledge Base Setup"
echo "=========================================="

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

print_status "Creating sample HR documents..."
sudo mkdir -p hr-documents
sudo chown ec2-user:ec2-user hr-documents

# Create sample HR documents
sudo tee hr-documents/employee-handbook.txt > /dev/null << 'EOF'
SAGESOFT EMPLOYEE HANDBOOK

1. COMPANY OVERVIEW
Sagesoft is a leading technology company committed to innovation and excellence.

2. WORKING HOURS
Standard working hours are Monday to Friday, 9:00 AM to 5:00 PM.
Flexible working arrangements are available upon approval.

3. VACATION POLICY
- New employees: 15 days annual leave
- After 2 years: 20 days annual leave
- After 5 years: 25 days annual leave
- Vacation requests must be submitted 2 weeks in advance

4. SICK LEAVE
Employees are entitled to 10 sick days per year.
Medical certificate required for absences exceeding 3 consecutive days.

5. BENEFITS
- Health insurance coverage
- Dental and vision insurance
- 401(k) retirement plan with company matching
- Professional development budget
- Gym membership reimbursement

6. CODE OF CONDUCT
All employees must maintain professional behavior and respect for colleagues.
Harassment and discrimination are strictly prohibited.

7. IT POLICIES
- Use company equipment responsibly
- Report security incidents immediately
- Follow password security guidelines
- No personal software installation without approval
EOF

sudo tee hr-documents/leave-policy.txt > /dev/null << 'EOF'
LEAVE POLICY

ANNUAL LEAVE
- Accrual: 1.25 days per month for new employees
- Maximum carryover: 5 days to next year
- Approval required from direct supervisor

SICK LEAVE
- 10 days per calendar year
- Can be used for personal illness or family care
- Medical certificate required for 3+ consecutive days

MATERNITY/PATERNITY LEAVE
- 12 weeks paid maternity leave
- 4 weeks paid paternity leave
- Additional unpaid leave available under FMLA

BEREAVEMENT LEAVE
- 3 days for immediate family
- 1 day for extended family
- Additional time may be granted at manager discretion

JURY DUTY
- Full pay for jury service
- Provide court documentation

HOW TO REQUEST LEAVE
1. Submit request through HRIS system
2. Get supervisor approval
3. HR will confirm and update records
4. Minimum 2 weeks notice for planned leave
EOF

sudo tee hr-documents/benefits-guide.txt > /dev/null << 'EOF'
EMPLOYEE BENEFITS GUIDE

HEALTH INSURANCE
- Company pays 80% of premium
- Coverage includes medical, dental, vision
- Open enrollment in November
- Qualifying life events allow mid-year changes

RETIREMENT PLAN
- 401(k) with 4% company match
- Immediate vesting
- Multiple investment options available
- Financial planning resources provided

PROFESSIONAL DEVELOPMENT
- $2,000 annual budget per employee
- Conference attendance
- Online training platforms
- Tuition reimbursement for relevant courses

WELLNESS PROGRAMS
- On-site fitness center
- Wellness challenges
- Mental health resources
- Annual health screenings

FLEXIBLE BENEFITS
- Flexible Spending Account (FSA)
- Health Savings Account (HSA)
- Commuter benefits
- Employee assistance program

CONTACT INFORMATION
HR Department: hr@sagesoft.com
Benefits Questions: benefits@sagesoft.com
Phone: (555) 123-4567
EOF

sudo tee hr-documents/it-support.txt > /dev/null << 'EOF'
IT SUPPORT GUIDE

GETTING HELP
- Email: itsupport@sagesoft.com
- Phone: (555) 123-4568
- Internal extension: 4568
- Help desk portal: https://helpdesk.sagesoft.com

COMMON ISSUES
Password Reset:
1. Go to password reset portal
2. Enter your email address
3. Check email for reset link
4. Create new password following policy

Software Installation:
- Submit request through IT portal
- Include business justification
- Allow 2-3 business days for approval

Hardware Issues:
- Report immediately for critical issues
- Include error messages and screenshots
- Remote support available

SECURITY POLICIES
- Use strong passwords (8+ characters, mixed case, numbers, symbols)
- Enable two-factor authentication
- Don't share login credentials
- Report suspicious emails to security@sagesoft.com
- Lock your computer when away from desk

APPROVED SOFTWARE
- Microsoft Office Suite
- Slack for communication
- Zoom for video conferencing
- Adobe Creative Suite (with approval)
- Development tools (with approval)
EOF

print_status "Uploading HR documents to S3..."
aws s3 sync hr-documents/ s3://$BUCKET_NAME/

print_status "Setting up bucket policy for Q Business access..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "qbusiness.amazonaws.com"
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

print_status "Creating IAM role for Q Business..."
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "qbusiness.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

ROLE_NAME="QBusinessServiceRole-$(date +%s)"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json

cat > service-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

aws iam put-role-policy --role-name $ROLE_NAME --policy-name QBusinessS3Access --policy-document file://service-policy.json

ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

print_status "Creating Q Business application..."
APP_RESULT=$(aws qbusiness create-application \
    --display-name "$APP_NAME" \
    --description "HR chatbot for Sagesoft HRIS system" \
    --role-arn "$ROLE_ARN" \
    --output json)

APP_ID=$(echo $APP_RESULT | jq -r '.applicationId')

print_status "Creating retriever..."
RETRIEVER_RESULT=$(aws qbusiness create-retriever \
    --application-id $APP_ID \
    --display-name "HR Documents Retriever" \
    --type "NATIVE_INDEX" \
    --output json)

RETRIEVER_ID=$(echo $RETRIEVER_RESULT | jq -r '.retrieverId')

print_status "Creating data source..."
cat > datasource-config.json << EOF
{
    "s3Configuration": {
        "bucketName": "$BUCKET_NAME"
    }
}
EOF

DATASOURCE_RESULT=$(aws qbusiness create-data-source \
    --application-id $APP_ID \
    --index-id $RETRIEVER_ID \
    --display-name "HR Documents" \
    --type "S3" \
    --configuration file://datasource-config.json \
    --output json)

DATASOURCE_ID=$(echo $DATASOURCE_RESULT | jq -r '.dataSourceId')

print_status "Starting data source sync..."
aws qbusiness start-data-source-sync-job \
    --application-id $APP_ID \
    --data-source-id $DATASOURCE_ID \
    --index-id $RETRIEVER_ID

# Cleanup temporary files
rm -f bucket-policy.json trust-policy.json service-policy.json datasource-config.json
rm -rf hr-documents/

echo ""
echo "=========================================="
echo -e "${GREEN}Knowledge Base Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Configuration Details:"
echo "S3 Bucket: $BUCKET_NAME"
echo "Application ID: $APP_ID"
echo "Retriever ID: $RETRIEVER_ID"
echo "Data Source ID: $DATASOURCE_ID"
echo "IAM Role: $ROLE_ARN"
echo ""
echo "Add these to your .env file:"
echo "Q_BUSINESS_APPLICATION_ID=$APP_ID"
echo "Q_BUSINESS_INDEX_ID=$RETRIEVER_ID"
echo ""
echo "The data source sync is running. It may take a few minutes to complete."
echo "You can check the sync status in the AWS Q Business console."
echo ""
