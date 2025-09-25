<?php

namespace App\Http\Controllers;

use App\Services\QBusinessService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;

class ChatbotController extends Controller
{
    private $qBusinessService;

    public function __construct(QBusinessService $qBusinessService)
    {
        $this->qBusinessService = $qBusinessService;
    }

    public function sendMessage(Request $request)
    {
        // Rate limiting
        $key = 'chatbot:' . ($request->ip() ?? 'unknown');
        if (RateLimiter::tooManyAttempts($key, 10)) {
            return response()->json([
                'success' => false,
                'error' => 'Too many requests. Please wait a moment before sending another message.'
            ], 429);
        }

        RateLimiter::hit($key, 60); // 10 requests per minute

        $request->validate([
            'message' => 'required|string|max:1000',
            'conversation_id' => 'nullable|string|max:255'
        ]);

        // Check if Q Business is configured
        if (!$this->qBusinessService->isConfigured()) {
            return response()->json([
                'success' => false,
                'error' => 'Chatbot service is not configured. Please contact your administrator.'
            ]);
        }

        $userId = Auth::check() ? Auth::user()->email : 'guest-' . $request->ip();
        
        $response = $this->qBusinessService->sendMessage(
            $request->message,
            $request->conversation_id,
            $userId
        );

        return response()->json($response);
    }

    public function getConversations()
    {
        if (!$this->qBusinessService->isConfigured()) {
            return response()->json([]);
        }

        $userId = Auth::check() ? Auth::user()->email : 'guest';
        $conversations = $this->qBusinessService->getConversations($userId);
        
        return response()->json($conversations);
    }

    public function getStatus()
    {
        return response()->json([
            'configured' => $this->qBusinessService->isConfigured(),
            'authenticated' => Auth::check()
        ]);
    }
}
