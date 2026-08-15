<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InAppNotification;
use App\Models\UserDevice;
use Carbon\Carbon;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Store or update device FCM token for authenticated user
     */
    public function storeToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
            'platform' => 'nullable|string|max:50',
            'device_name' => 'nullable|string|max:255',
        ]);

        $user = $request->user();

        $device = UserDevice::updateOrCreate(
            [
                'user_id' => $user->id,
                'fcm_token' => $request->fcm_token,
            ],
            [
                'platform' => $request->platform ?? 'android',
                'device_name' => $request->device_name ?? 'Mobile Device',
                'last_active_at' => Carbon::now(),
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'FCM token berhasil didaftarkan',
            'data' => $device,
        ]);
    }

    /**
     * Remove FCM token on user logout
     */
    public function removeToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        UserDevice::where('user_id', $request->user()->id)
            ->where('fcm_token', $request->fcm_token)
            ->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'FCM token berhasil dihapus',
        ]);
    }

    /**
     * List in-app notifications for authenticated user
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->company_id) {
            return response()->json(['data' => [], 'unread_count' => 0]);
        }

        $query = InAppNotification::where('company_id', $user->company_id)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhere(function ($sub) use ($user) {
                      $sub->whereNull('user_id')
                          ->where(function ($roleQuery) use ($user) {
                              $roleQuery->whereNull('target_role')
                                        ->orWhere('target_role', $user->role);
                          });
                  });
            });

        if ($request->filled('type') && $request->type !== 'all') {
            $query->where('type', $request->type);
        }

        if ($request->has('unread_only') && filter_var($request->unread_only, FILTER_VALIDATE_BOOLEAN)) {
            $query->where('is_read', false);
        }

        $unreadCount = (clone $query)->where('is_read', false)->count();
        $notifications = $query->orderBy('created_at', 'desc')->paginate($request->per_page ?? 30);

        return response()->json([
            'status' => 'success',
            'unread_count' => $unreadCount,
            'data' => $notifications->items(),
            'current_page' => $notifications->currentPage(),
            'last_page' => $notifications->lastPage(),
            'total' => $notifications->total(),
        ]);
    }

    /**
     * Mark single notification as read
     */
    public function markAsRead(Request $request, $id)
    {
        $user = $request->user();
        $notification = InAppNotification::where('company_id', $user->company_id)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhereNull('user_id');
            })
            ->findOrFail($id);

        $notification->update([
            'is_read' => true,
            'read_at' => Carbon::now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Notifikasi ditandai sebagai dibaca',
            'data' => $notification,
        ]);
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request)
    {
        $user = $request->user();
        InAppNotification::where('company_id', $user->company_id)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhereNull('user_id');
            })
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => Carbon::now(),
            ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Semua notifikasi ditandai sebagai dibaca',
        ]);
    }

    /**
     * Delete notification
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $notification = InAppNotification::where('company_id', $user->company_id)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhereNull('user_id');
            })
            ->findOrFail($id);

        $notification->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Notifikasi berhasil dihapus',
        ]);
    }
}
