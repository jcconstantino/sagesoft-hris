<div id="chatbot-widget" class="chatbot-widget">
    <div id="chatbot-toggle" class="chatbot-toggle">
        <i class="fas fa-comments"></i>
        <span id="chatbot-badge" class="chatbot-badge" style="display: none;">1</span>
    </div>
    
    <div id="chatbot-container" class="chatbot-container" style="display: none;">
        <div class="chatbot-header">
            <div class="chatbot-title">
                <i class="fas fa-robot me-2"></i>
                <h6 class="mb-0">HR Assistant</h6>
            </div>
            <button id="chatbot-close" class="btn-close btn-close-white"></button>
        </div>
        
        <div id="chatbot-messages" class="chatbot-messages">
            <div class="message bot-message">
                <div class="message-avatar">
                    <i class="fas fa-robot"></i>
                </div>
                <div class="message-content">
                    Hello! I'm your HR assistant. I can help you with company policies, procedures, and answer your HR-related questions. How can I assist you today?
                </div>
            </div>
        </div>
        
        <div class="chatbot-input">
            <div class="input-group">
                <input type="text" id="chatbot-input" class="form-control" 
                       placeholder="Ask me about HR policies, benefits, procedures..." 
                       maxlength="1000" disabled>
                <button id="chatbot-send" class="btn btn-primary" disabled>
                    <i class="fas fa-paper-plane"></i>
                </button>
            </div>
            <div id="chatbot-status" class="chatbot-status">
                <small class="text-muted">Connecting to HR assistant...</small>
            </div>
        </div>
    </div>
</div>

<style>
.chatbot-widget {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 1050;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.chatbot-toggle {
    width: 60px;
    height: 60px;
    background: linear-gradient(135deg, #007bff, #0056b3);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    cursor: pointer;
    box-shadow: 0 4px 20px rgba(0, 123, 255, 0.3);
    transition: all 0.3s ease;
    position: relative;
    border: none;
}

.chatbot-toggle:hover {
    transform: scale(1.1);
    box-shadow: 0 6px 25px rgba(0, 123, 255, 0.4);
}

.chatbot-toggle i {
    font-size: 24px;
}

.chatbot-badge {
    position: absolute;
    top: -5px;
    right: -5px;
    background: #dc3545;
    color: white;
    border-radius: 50%;
    width: 20px;
    height: 20px;
    font-size: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
}

.chatbot-container {
    position: absolute;
    bottom: 70px;
    right: 0;
    width: 380px;
    height: 550px;
    background: white;
    border-radius: 15px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.15);
    display: flex;
    flex-direction: column;
    overflow: hidden;
    border: 1px solid #e9ecef;
}

.chatbot-header {
    background: linear-gradient(135deg, #007bff, #0056b3);
    color: white;
    padding: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.chatbot-title {
    display: flex;
    align-items: center;
}

.chatbot-messages {
    flex: 1;
    padding: 20px;
    overflow-y: auto;
    background: #f8f9fa;
    max-height: 400px;
}

.message {
    margin-bottom: 20px;
    display: flex;
    align-items: flex-start;
}

.message-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 12px;
    flex-shrink: 0;
}

.bot-message .message-avatar {
    background: #007bff;
    color: white;
}

.user-message .message-avatar {
    background: #6c757d;
    color: white;
    order: 2;
    margin-right: 0;
    margin-left: 12px;
}

.message-content {
    padding: 12px 16px;
    border-radius: 18px;
    max-width: 280px;
    word-wrap: break-word;
    line-height: 1.4;
    font-size: 14px;
}

.bot-message .message-content {
    background: white;
    color: #333;
    border: 1px solid #e9ecef;
}

.user-message {
    flex-direction: row-reverse;
}

.user-message .message-content {
    background: #007bff;
    color: white;
}

.message-sources {
    margin-top: 8px;
    padding: 8px 12px;
    background: #e3f2fd;
    border-radius: 12px;
    font-size: 12px;
    color: #1976d2;
}

.chatbot-input {
    padding: 20px;
    border-top: 1px solid #e9ecef;
    background: white;
}

.chatbot-status {
    margin-top: 8px;
    text-align: center;
}

.typing-indicator {
    display: flex;
    align-items: center;
    padding: 12px 16px;
    background: white;
    border-radius: 18px;
    border: 1px solid #e9ecef;
    max-width: 280px;
}

.typing-dots {
    display: flex;
    gap: 4px;
}

.typing-dots span {
    width: 6px;
    height: 6px;
    background: #6c757d;
    border-radius: 50%;
    animation: typing 1.4s infinite ease-in-out;
}

.typing-dots span:nth-child(1) { animation-delay: -0.32s; }
.typing-dots span:nth-child(2) { animation-delay: -0.16s; }

@keyframes typing {
    0%, 80%, 100% { transform: scale(0.8); opacity: 0.5; }
    40% { transform: scale(1); opacity: 1; }
}

.error-message {
    background: #f8d7da !important;
    color: #721c24 !important;
    border: 1px solid #f5c6cb !important;
}

@media (max-width: 768px) {
    .chatbot-container {
        width: 320px;
        height: 500px;
        bottom: 80px;
        right: 10px;
    }
    
    .chatbot-widget {
        bottom: 10px;
        right: 10px;
    }
    
    .message-content {
        max-width: 220px;
    }
}

/* Scrollbar styling */
.chatbot-messages::-webkit-scrollbar {
    width: 6px;
}

.chatbot-messages::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 3px;
}

.chatbot-messages::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 3px;
}

.chatbot-messages::-webkit-scrollbar-thumb:hover {
    background: #a8a8a8;
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
    const status = document.getElementById('chatbot-status');
    const badge = document.getElementById('chatbot-badge');
    
    let conversationId = null;
    let isOpen = false;
    let isConfigured = false;

    // Check chatbot status on load
    checkStatus();

    // Toggle chatbot
    toggle.addEventListener('click', function() {
        isOpen = !isOpen;
        container.style.display = isOpen ? 'flex' : 'none';
        if (isOpen) {
            input.focus();
            badge.style.display = 'none';
        }
    });

    // Close chatbot
    close.addEventListener('click', function() {
        isOpen = false;
        container.style.display = 'none';
    });

    // Send message on Enter
    input.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Send message on button click
    send.addEventListener('click', sendMessage);

    function checkStatus() {
        fetch('/chatbot/status', {
            method: 'GET',
            headers: {
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            }
        })
        .then(response => response.json())
        .then(data => {
            isConfigured = data.configured;
            
            if (isConfigured) {
                input.disabled = false;
                send.disabled = false;
                status.innerHTML = '<small class="text-success"><i class="fas fa-circle me-1"></i>HR Assistant is ready</small>';
            } else {
                status.innerHTML = '<small class="text-warning"><i class="fas fa-exclamation-triangle me-1"></i>HR Assistant is not configured</small>';
            }
        })
        .catch(error => {
            console.error('Status check error:', error);
            status.innerHTML = '<small class="text-danger"><i class="fas fa-times-circle me-1"></i>Connection error</small>';
        });
    }

    function sendMessage() {
        const message = input.value.trim();
        if (!message || !isConfigured) return;

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
                addMessage(data.error || 'Sorry, I encountered an error. Please try again.', 'bot', true);
            }
        })
        .catch(error => {
            hideTyping();
            addMessage('Sorry, I encountered a connection error. Please try again.', 'bot', true);
            console.error('Error:', error);
        });
    }

    function addMessage(content, type, isError = false) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}-message`;
        
        const avatarDiv = document.createElement('div');
        avatarDiv.className = 'message-avatar';
        avatarDiv.innerHTML = type === 'bot' ? '<i class="fas fa-robot"></i>' : '<i class="fas fa-user"></i>';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = `message-content ${isError ? 'error-message' : ''}`;
        contentDiv.textContent = content;
        
        messageDiv.appendChild(avatarDiv);
        messageDiv.appendChild(contentDiv);
        messages.appendChild(messageDiv);
        
        // Scroll to bottom
        messages.scrollTop = messages.scrollHeight;
        
        // Show badge if chatbot is closed
        if (!isOpen && type === 'bot') {
            badge.style.display = 'flex';
        }
    }

    function addSources(sources) {
        if (sources.length === 0) return;
        
        const lastMessage = messages.lastElementChild;
        const sourcesDiv = document.createElement('div');
        sourcesDiv.className = 'message-sources';
        sourcesDiv.innerHTML = `
            <strong>Sources:</strong><br>
            ${sources.map(source => `• ${source.title || source.excerpt || 'Document reference'}`).join('<br>')}
        `;
        
        lastMessage.querySelector('.message-content').appendChild(sourcesDiv);
        messages.scrollTop = messages.scrollHeight;
    }

    function showTyping() {
        const typingDiv = document.createElement('div');
        typingDiv.id = 'typing-indicator';
        typingDiv.className = 'message bot-message';
        typingDiv.innerHTML = `
            <div class="message-avatar">
                <i class="fas fa-robot"></i>
            </div>
            <div class="typing-indicator">
                <div class="typing-dots">
                    <span></span>
                    <span></span>
                    <span></span>
                </div>
            </div>
        `;
        
        messages.appendChild(typingDiv);
        messages.scrollTop = messages.scrollHeight;
    }

    function hideTyping() {
        const typing = document.getElementById('typing-indicator');
        if (typing) {
            typing.remove();
        }
    }

    // Close chatbot when clicking outside
    document.addEventListener('click', function(e) {
        if (isOpen && !container.contains(e.target) && !toggle.contains(e.target)) {
            isOpen = false;
            container.style.display = 'none';
        }
    });
});
</script>
