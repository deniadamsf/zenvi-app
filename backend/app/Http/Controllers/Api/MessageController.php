<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index(Request $request)
    {
        $companyId = $request->user()->company_id;
        $userId = $request->user()->id;
        $receiverId = $request->query('receiver_id');
        
        $query = Message::where('company_id', $companyId);
        
        if ($receiverId) {
            // Private chat between auth user and receiverId
            $query->where(function ($q) use ($userId, $receiverId) {
                $q->where(function ($q1) use ($userId, $receiverId) {
                    $q1->where('sender_id', $userId)->where('receiver_id', $receiverId);
                })->orWhere(function ($q2) use ($userId, $receiverId) {
                    $q2->where('sender_id', $receiverId)->where('receiver_id', $userId);
                });
            });
        } else {
            // Group chat
            $query->whereNull('receiver_id');
        }

        $messages = $query->orderBy('created_at', 'asc')->get();
            
        return response()->json($messages);
    }

    public function store(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $message = Message::create([
            'company_id' => $request->user()->company_id,
            'sender_id' => $request->user()->id,
            'receiver_id' => $request->receiver_id, // can be null for group chat
            'message' => $request->message,
        ]);

        // Eager load sender so the frontend gets the name and role
        $message->load('sender');

        // Push Notification
        try {
            $senderName = $request->user()->name;
            $snippet = mb_strimwidth($message->message, 0, 100, '...');
            
            if ($message->receiver_id) {
                // Private chat
                FirebaseNotificationService::sendToUser(
                    $message->receiver_id,
                    "Pesan dari {$senderName}",
                    $snippet,
                    'chat',
                    [
                        'sender_id' => $request->user()->id,
                        'message_id' => $message->id,
                        'type' => 'chat_private',
                        'route' => '/chat'
                    ]
                );
            } else {
                // Group chat: send to everyone in company except sender
                FirebaseNotificationService::sendToCompany(
                    $request->user()->company_id,
                    "Chat Toko: {$senderName}",
                    $snippet,
                    'chat',
                    [
                        'sender_id' => $request->user()->id,
                        'message_id' => $message->id,
                        'type' => 'chat_group',
                        'route' => '/chat'
                    ],
                    $request->user()->id
                );
            }
        } catch (\Exception $e) {
            \Log::warning('Chat push notification failed: ' . $e->getMessage());
        }

        return response()->json($message, 201);
    }
}
