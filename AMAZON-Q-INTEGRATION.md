# Amazon Q Business Chatbot Integration Guide

This guide provides step-by-step instructions for integrating Amazon Q Business chatbot into the Sagesoft HRIS system.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Sagesoft HRIS Web Application                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   Frontend      │    │   Backend       │    │   Database   │ │
│  │   (Blade Views) │◄──►│   (Laravel)     │◄──►│   (RDS)      │ │
│  │                 │    │                 │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│           │                       │                             │
│           │                       │                             │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Q Chat Widget │    │   Q API Client  │                    │
│  │   (JavaScript)  │◄──►│   (PHP/Laravel) │                    │
│  └─────────────────┘    └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Services                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   Amazon Q      │    │   IAM Roles     │    │   CloudWatch │ │
│  │   Business      │◄──►│   & Policies    │◄──►│   Logs       │ │
│  │                 │    │                 │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │   Knowledge     │                                           │
│  │   Base Sources  │                                           │
│  │   (S3, Docs)    │                                           │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS Account with Amazon Q Business access
- Existing Sagesoft HRIS deployment
- IAM permissions for Q Business
- Knowledge base documents (HR policies, procedures)

## Step 1: Set Up Amazon Q Business

### 1.1 Create Q Business Application

```bash
# Using AWS CLI
aws qbusiness create-application \
    --display-name "Sagesoft HRIS Assistant" \
    --description "HR chatbot for employee assistance" \
    --role-arn "arn:aws:iam::ACCOUNT:role/QBusinessServiceRole"
```

### 1.2 Create Knowledge Base

```bash
# Create S3 bucket for documents
aws s3 mb s3://sagesoft-hris-knowledge-base

# Upload HR documents
aws s3 sync ./hr-documents/ s3://sagesoft-hris-knowledge-base/

# Create data source
aws qbusiness create-data-source \
    --application-id "your-app-id" \
    --index-id "your-index-id" \
    --display-name "HR Documents" \
    --type "S3" \
    --configuration file://datasource-config.json
```

## Step 2: Create IAM Roles and Policies

### 2.1 Q Business Service Role

```json
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
```

### 2.2 Application Access Policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "qbusiness:ChatSync",
                "qbusiness:ListMessages",
                "qbusiness:ListConversations"
            ],
            "Resource": "arn:aws:qbusiness:*:*:application/your-app-id/*"
        }
    ]
}
```

## Step 3: Backend Integration (Laravel)

### 3.1 Install AWS SDK

```bash
cd /var/www/sagesoft-hris
composer require aws/aws-sdk-php
```

### 3.2 Create Q Business Service

```php
<?php
// app/Services/QBusinessService.php

namespace App\Services;

use Aws\QBusiness\QBusinessClient;
use Aws\Exception\AwsException;

class QBusinessService
{
    private $client;
    private $applicationId;

    public function __construct()
    {
        $this->client = new QBusinessClient([
            'version' => 'latest',
            'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
            'credentials' => [
                'key' => env('AWS_ACCESS_KEY_ID'),
                'secret' => env('AWS_SECRET_ACCESS_KEY'),
            ]
        ]);
        
        $this->applicationId = env('Q_BUSINESS_APPLICATION_ID');
    }

    public function sendMessage($message, $conversationId = null, $userId = null)
    {
        try {
            $params = [
                'applicationId' => $this->applicationId,
                'userMessage' => $message,
                'userId' => $userId ?? 'anonymous-' . uniqid(),
            ];

            if ($conversationId) {
                $params['conversationId'] = $conversationId;
            }

            $result = $this->client->chatSync($params);
            
            return [
                'success' => true,
                'response' => $result['systemMessage'],
                'conversationId' => $result['conversationId'],
                'sources' => $result['sourceAttributions'] ?? []
            ];
        } catch (AwsException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function getConversations($userId)
    {
        try {
            $result = $this->client->listConversations([
                'applicationId' => $this->applicationId,
                'userId' => $userId
            ]);

            return $result['conversations'] ?? [];
        } catch (AwsException $e) {
            return [];
        }
    }
}
```

### 3.3 Create Chatbot Controller

```php
<?php
// app/Http/Controllers/ChatbotController.php

namespace App\Http\Controllers;

use App\Services\QBusinessService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatbotController extends Controller
{
    private $qBusinessService;

    public function __construct(QBusinessService $qBusinessService)
    {
        $this->qBusinessService = $qBusinessService;
    }

    public function sendMessage(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
            'conversation_id' => 'nullable|string'
        ]);

        $userId = Auth::check() ? Auth::user()->email : null;
        
        $response = $this->qBusinessService->sendMessage(
            $request->message,
            $request->conversation_id,
            $userId
        );

        return response()->json($response);
    }

    public function getConversations()
    {
        $userId = Auth::check() ? Auth::user()->email : 'anonymous';
        $conversations = $this->qBusinessService->getConversations($userId);
        
        return response()->json($conversations);
    }
}
```

### 3.4 Add Routes

```php
<?php
// routes/web.php - Add these routes

Route::middleware('auth')->group(function () {
    Route::post('/chatbot/message', [ChatbotController::class, 'sendMessage']);
    Route::get('/chatbot/conversations', [ChatbotController::class, 'getConversations']);
});
```

## Step 4: Frontend Integration

### 4.1 Create Chatbot Widget Blade Component

```php
<?php
// resources/views/components/chatbot-widget.blade.php

<div id="chatbot-widget" class="chatbot-widget">
    <div id="chatbot-toggle" class="chatbot-toggle">
        <i class="fas fa-comments"></i>
    </div>
    
    <div id="chatbot-container" class="chatbot-container" style="display: none;">
        <div class="chatbot-header">
            <h5>HR Assistant</h5>
            <button id="chatbot-close" class="btn-close"></button>
        </div>
        
        <div id="chatbot-messages" class="chatbot-messages">
            <div class="message bot-message">
                <div class="message-content">
                    Hello! I'm your HR assistant. How can I help you today?
                </div>
            </div>
        </div>
        
        <div class="chatbot-input">
            <div class="input-group">
                <input type="text" id="chatbot-input" class="form-control" 
                       placeholder="Type your message..." maxlength="1000">
                <button id="chatbot-send" class="btn btn-primary">
                    <i class="fas fa-paper-plane"></i>
                </button>
            </div>
        </div>
    </div>
</div>

<style>
.chatbot-widget {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 1000;
}

.chatbot-toggle {
    width: 60px;
    height: 60px;
    background: #007bff;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    cursor: pointer;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    transition: all 0.3s ease;
}

.chatbot-toggle:hover {
    background: #0056b3;
    transform: scale(1.1);
}

.chatbot-container {
    position: absolute;
    bottom: 70px;
    right: 0;
    width: 350px;
    height: 500px;
    background: white;
    border-radius: 10px;
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
    display: flex;
    flex-direction: column;
}

.chatbot-header {
    background: #007bff;
    color: white;
    padding: 15px;
    border-radius: 10px 10px 0 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.chatbot-messages {
    flex: 1;
    padding: 15px;
    overflow-y: auto;
    max-height: 350px;
}

.message {
    margin-bottom: 15px;
}

.message-content {
    padding: 10px 15px;
    border-radius: 18px;
    max-width: 80%;
    word-wrap: break-word;
}

.bot-message .message-content {
    background: #f1f3f4;
    color: #333;
}

.user-message {
    text-align: right;
}

.user-message .message-content {
    background: #007bff;
    color: white;
    margin-left: auto;
}

.chatbot-input {
    padding: 15px;
    border-top: 1px solid #eee;
}

.typing-indicator {
    display: none;
    padding: 10px 15px;
    font-style: italic;
    color: #666;
}

@media (max-width: 768px) {
    .chatbot-container {
        width: 300px;
        height: 400px;
    }
}
</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const toggle = document.getElementById('chatbot-toggle');
    const container = document.getElementById('chatbot-container');
    const close = document.getElementById('chatbot-close');
    const input = document.getElementById('chatbot-input');
    const send = document.getElementById('chatbot-send');
    const messages = document.getElementById('chatbot-messages');
    
    let conversationId = null;
    let isOpen = false;

    // Toggle chatbot
    toggle.addEventListener('click', function() {
        isOpen = !isOpen;
        container.style.display = isOpen ? 'flex' : 'none';
        if (isOpen) {
            input.focus();
        }
    });

    // Close chatbot
    close.addEventListener('click', function() {
        isOpen = false;
        container.style.display = 'none';
    });

    // Send message on Enter
    input.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });

    // Send message on button click
    send.addEventListener('click', sendMessage);

    function sendMessage() {
        const message = input.value.trim();
        if (!message) return;

        // Add user message to chat
        addMessage(message, 'user');
        input.value = '';

        // Show typing indicator
        showTyping();

        // Send to backend
        fetch('/chatbot/message', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                message: message,
                conversation_id: conversationId
            })
        })
        .then(response => response.json())
        .then(data => {
            hideTyping();
            
            if (data.success) {
                addMessage(data.response, 'bot');
                conversationId = data.conversationId;
                
                // Add sources if available
                if (data.sources && data.sources.length > 0) {
                    addSources(data.sources);
                }
            } else {
                addMessage('Sorry, I encountered an error. Please try again.', 'bot');
            }
        })
        .catch(error => {
            hideTyping();
            addMessage('Sorry, I encountered an error. Please try again.', 'bot');
            console.error('Error:', error);
        });
    }

    function addMessage(content, type) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}-message`;
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        contentDiv.textContent = content;
        
        messageDiv.appendChild(contentDiv);
        messages.appendChild(messageDiv);
        
        // Scroll to bottom
        messages.scrollTop = messages.scrollHeight;
    }

    function addSources(sources) {
        if (sources.length === 0) return;
        
        const sourcesDiv = document.createElement('div');
        sourcesDiv.className = 'message bot-message';
        sourcesDiv.innerHTML = `
            <div class="message-content">
                <small><strong>Sources:</strong><br>
                ${sources.map(source => `• ${source.title || 'Document'}`).join('<br>')}
                </small>
            </div>
        `;
        
        messages.appendChild(sourcesDiv);
        messages.scrollTop = messages.scrollHeight;
    }

    function showTyping() {
        const typingDiv = document.createElement('div');
        typingDiv.id = 'typing-indicator';
        typingDiv.className = 'typing-indicator';
        typingDiv.textContent = 'HR Assistant is typing...';
        typingDiv.style.display = 'block';
        
        messages.appendChild(typingDiv);
        messages.scrollTop = messages.scrollHeight;
    }

    function hideTyping() {
        const typing = document.getElementById('typing-indicator');
        if (typing) {
            typing.remove();
        }
    }
});
</script>
```

### 4.2 Include Widget in Layout

```php
<?php
// resources/views/layouts/app.blade.php - Add before closing </body> tag

@auth
    <x-chatbot-widget />
@endauth
```

## Step 5: Environment Configuration

### 5.1 Update .env File

```bash
# Add to /var/www/sagesoft-hris/.env

# Amazon Q Business Configuration
Q_BUSINESS_APPLICATION_ID=your-application-id
Q_BUSINESS_INDEX_ID=your-index-id
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
```

## Step 6: Deployment Script

### 6.1 Create Deployment Script

```bash
#!/bin/bash
# deploy-chatbot.sh

echo "Deploying Amazon Q Business Chatbot Integration..."

# Install AWS SDK
cd /var/www/sagesoft-hris
sudo -u apache composer require aws/aws-sdk-php

# Create service directory
sudo mkdir -p app/Services

# Set permissions
sudo chown -R apache:apache app/Services
sudo chmod -R 755 app/Services

# Clear caches
sudo -u apache php artisan config:clear
sudo -u apache php artisan route:clear
sudo -u apache php artisan view:clear

# Restart Apache
sudo systemctl restart httpd

echo "Chatbot integration deployed successfully!"
echo "Don't forget to:"
echo "1. Update .env with Q Business credentials"
echo "2. Upload HR documents to S3 knowledge base"
echo "3. Test the chatbot functionality"
```

### 6.2 Knowledge Base Setup Script

```bash
#!/bin/bash
# setup-knowledge-base.sh

BUCKET_NAME="sagesoft-hris-knowledge-base"
REGION="us-east-1"

echo "Setting up Amazon Q Business Knowledge Base..."

# Create S3 bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Upload sample HR documents
echo "Uploading HR documents..."
aws s3 sync ./hr-documents/ s3://$BUCKET_NAME/

# Set bucket policy for Q Business access
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

echo "Knowledge base setup complete!"
```

## Step 7: Testing and Validation

### 7.1 Test Checklist

- [ ] Q Business application created
- [ ] Knowledge base configured with HR documents
- [ ] IAM roles and policies set up
- [ ] Laravel service and controller working
- [ ] Frontend widget displays correctly
- [ ] Messages send and receive properly
- [ ] Conversation persistence works
- [ ] Sources are displayed when available
- [ ] Mobile responsiveness verified

### 7.2 Sample Test Queries

```
1. "What is the company's vacation policy?"
2. "How do I request time off?"
3. "What are the working hours?"
4. "Who do I contact for IT support?"
5. "What benefits are available to employees?"
```

## Step 8: Monitoring and Maintenance

### 8.1 CloudWatch Monitoring

```bash
# Create CloudWatch dashboard for Q Business metrics
aws cloudwatch put-dashboard --dashboard-name "QBusiness-HRIS" --dashboard-body file://dashboard.json
```

### 8.2 Log Analysis

```bash
# Monitor application logs
sudo tail -f /var/www/sagesoft-hris/storage/logs/laravel.log | grep -i chatbot

# Monitor Q Business usage
aws logs filter-log-events --log-group-name "/aws/qbusiness/application/your-app-id"
```

## Security Considerations

1. **Authentication**: Only authenticated users can access chatbot
2. **Rate Limiting**: Implement rate limiting for API calls
3. **Data Privacy**: Ensure sensitive HR data is properly handled
4. **Access Control**: Use IAM policies to restrict Q Business access
5. **Audit Logging**: Log all chatbot interactions for compliance

## Cost Optimization

1. **Usage Monitoring**: Track Q Business API calls and costs
2. **Caching**: Implement response caching for common queries
3. **Knowledge Base**: Optimize document indexing frequency
4. **Regional Deployment**: Use appropriate AWS region for cost efficiency

---

This integration provides a sophisticated HR chatbot that can answer employee questions using your organization's HR documents and policies, seamlessly integrated into the existing Sagesoft HRIS interface.
