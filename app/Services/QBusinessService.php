<?php

namespace App\Services;

use Aws\QBusiness\QBusinessClient;
use Aws\Exception\AwsException;
use Illuminate\Support\Facades\Log;

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

            Log::info('Sending message to Q Business', ['params' => $params]);

            $result = $this->client->chatSync($params);
            
            return [
                'success' => true,
                'response' => $result['systemMessage'] ?? 'I apologize, but I couldn\'t generate a response. Please try rephrasing your question.',
                'conversationId' => $result['conversationId'] ?? null,
                'sources' => $result['sourceAttributions'] ?? []
            ];
        } catch (AwsException $e) {
            Log::error('Q Business API Error', ['error' => $e->getMessage()]);
            
            return [
                'success' => false,
                'error' => 'I\'m experiencing technical difficulties. Please try again later.',
                'debug' => $e->getMessage()
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
            Log::error('Q Business List Conversations Error', ['error' => $e->getMessage()]);
            return [];
        }
    }

    public function isConfigured()
    {
        return !empty($this->applicationId) && 
               !empty(env('AWS_ACCESS_KEY_ID')) && 
               !empty(env('AWS_SECRET_ACCESS_KEY'));
    }
}
