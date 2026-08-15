<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmployeePermission;
use App\Models\User;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class EmployeePermissionController extends Controller
{
    /**
     * Clean up attachments older than 3 days to preserve server storage
     */
    private function cleanExpiredAttachments($companyId = null)
    {
        try {
            $threeDaysAgo = Carbon::now()->subDays(3);
            $query = EmployeePermission::whereNotNull('attachment_path')
                ->where(function($q) use ($threeDaysAgo) {
                    $q->where('created_at', '<=', $threeDaysAgo)
                      ->orWhere(function($sub) use ($threeDaysAgo) {
                          $sub->where('status', 'approved')
                              ->where('reviewed_at', '<=', $threeDaysAgo);
                      });
                });

            if ($companyId) {
                $query->where('company_id', $companyId);
            }

            $expiredPermits = $query->get();

            foreach ($expiredPermits as $permit) {
                if ($permit->attachment_path && file_exists(public_path($permit->attachment_path))) {
                    @unlink(public_path($permit->attachment_path));
                }
                $permit->update([
                    'attachment_path' => null,
                    'attachment_deleted_at' => Carbon::now(),
                ]);
            }
        } catch (\Exception $e) {
            \Log::error('Failed to clean expired permit attachments: ' . $e->getMessage());
        }
    }

    /**
     * List permissions
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->company_id) {
            return response()->json(['message' => 'User tidak terdaftar dalam perusahaan'], 400);
        }

        // Run auto-cleanup for attachments older than 3 days
        $this->cleanExpiredAttachments($user->company_id);

        $query = EmployeePermission::where('company_id', $user->company_id)
            ->with(['user:id,name,email,role', 'reviewer:id,name']);

        // Non-owner/admin can only see their own permissions
        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            $query->where('user_id', $user->id);
        } else {
            if ($request->has('user_id') && !empty($request->user_id)) {
                $query->where('user_id', $request->user_id);
            }
        }

        // Status filter
        if ($request->has('status') && in_array($request->status, ['pending', 'approved', 'rejected'])) {
            $query->where('status', $request->status);
        }

        // Type filter
        if ($request->has('type') && in_array($request->type, ['leave', 'late'])) {
            $query->where('type', $request->type);
        }

        $permissions = $query->orderBy('created_at', 'desc')->get();

        // Calculate counts (scoped to user if employee, or whole company if Owner/Admin)
        $countQuery = EmployeePermission::where('company_id', $user->company_id);
        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            $countQuery->where('user_id', $user->id);
        }

        $pendingCount = (clone $countQuery)->where('status', 'pending')->count();
        $approvedCount = (clone $countQuery)->where('status', 'approved')->count();
        $rejectedCount = (clone $countQuery)->where('status', 'rejected')->count();

        return response()->json([
            'status' => 'success',
            'pending_count' => $pendingCount,
            'approved_count' => $approvedCount,
            'rejected_count' => $rejectedCount,
            'data' => $permissions,
        ]);
    }

    /**
     * Submit a new permission request with evidence attachment (Staff/Karyawan only)
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role === 'Owner') {
            return response()->json(['message' => 'Owner tidak perlu mengajukan izin kerja'], 400);
        }
        if (!$user->company_id) {
            return response()->json(['message' => 'User tidak memiliki perusahaan'], 400);
        }

        $request->validate([
            'type' => 'required|in:leave,late',
            'permission_date' => 'required|date',
            'estimated_arrival_time' => 'nullable|string|max:10',
            'reason' => 'required|string|max:1000',
            'attachment' => 'required|image|mimes:jpeg,png,jpg,webp|max:5120', // Evidence photo is mandatory
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $image = $request->file('attachment');
            $filename = 'permit_' . $user->id . '_' . time() . '_' . rand(100, 999) . '.' . $image->getClientOriginalExtension();
            $attachmentPath = 'uploads/permits/' . $filename;

            $destinationPath = public_path('uploads/permits');
            if (!file_exists($destinationPath)) {
                mkdir($destinationPath, 0775, true);
            }

            try {
                $manager = new ImageManager(new Driver());
                $img = $manager->read($image);
                $img->scaleDown(1200, 1200); // Scale down to reasonable max dimensions
                $img->save(public_path($attachmentPath));
            } catch (\Exception $e) {
                // Fallback to direct move if image intervention fails
                $image->move($destinationPath, $filename);
            }
        }

        $permission = EmployeePermission::create([
            'company_id' => $user->company_id,
            'user_id' => $user->id,
            'type' => $request->type,
            'permission_date' => $request->permission_date,
            'estimated_arrival_time' => $request->type === 'late' ? $request->estimated_arrival_time : null,
            'reason' => $request->reason,
            'attachment_path' => $attachmentPath,
            'status' => 'pending',
        ]);

        // Push Notification to Owner
        try {
            $typeLabel = $permission->type === 'leave' ? 'Cuti / Izin Libur' : 'Izin Telat Masuk';
            $tgl = Carbon::parse($permission->permission_date)->format('d M Y');
            FirebaseNotificationService::sendToOwner(
                $user->company_id,
                'Pengajuan Izin Karyawan Baru',
                "{$user->name} mengajukan {$typeLabel} untuk tanggal {$tgl}.",
                'leave',
                ['permission_id' => $permission->id, 'type' => 'permission_created', 'route' => '/permissions']
            );
        } catch (\Exception $e) {
            \Log::warning('Permission submit notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Pengajuan izin berhasil dikirim dan menunggu persetujuan owner.',
            'data' => $permission->load(['user:id,name,email,role']),
        ], 201);
    }

    /**
     * Approve permission (Owner/Admin only)
     */
    public function approve(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $permission = EmployeePermission::where('company_id', $user->company_id)->findOrFail($id);
        
        $permission->update([
            'status' => 'approved',
            'reviewed_by' => $user->id,
            'reviewed_at' => Carbon::now(),
            'rejection_note' => null,
        ]);

        // Push Notification to Employee
        try {
            $tgl = Carbon::parse($permission->permission_date)->format('d M Y');
            FirebaseNotificationService::sendToUser(
                $permission->user_id,
                'Izin Kerja Disetujui ✅',
                "Pengajuan izin Anda untuk tanggal {$tgl} telah DISETUJUI oleh Owner.",
                'leave',
                ['permission_id' => $permission->id, 'type' => 'permission_approved', 'route' => '/permissions']
            );
        } catch (\Exception $e) {
            \Log::warning('Permission approve notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Izin karyawan telah disetujui.',
            'data' => $permission->fresh(['user:id,name,email,role', 'reviewer:id,name']),
        ]);
    }

    /**
     * Reject permission (Owner/Admin only)
     */
    public function reject(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'rejection_note' => 'nullable|string|max:500',
        ]);

        $permission = EmployeePermission::where('company_id', $user->company_id)->findOrFail($id);
        
        $permission->update([
            'status' => 'rejected',
            'reviewed_by' => $user->id,
            'reviewed_at' => Carbon::now(),
            'rejection_note' => $request->rejection_note,
        ]);

        // Push Notification to Employee
        try {
            $tgl = Carbon::parse($permission->permission_date)->format('d M Y');
            $note = $permission->rejection_note ? " Catatan: {$permission->rejection_note}" : '';
            FirebaseNotificationService::sendToUser(
                $permission->user_id,
                'Izin Kerja Ditolak ❌',
                "Pengajuan izin Anda untuk tanggal {$tgl} DITOLAK oleh Owner.{$note}",
                'leave',
                ['permission_id' => $permission->id, 'type' => 'permission_rejected', 'route' => '/permissions']
            );
        } catch (\Exception $e) {
            \Log::warning('Permission reject notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Pengajuan izin karyawan ditolak.',
            'data' => $permission->fresh(['user:id,name,email,role', 'reviewer:id,name']),
        ]);
    }

    /**
     * Delete / Cancel pending permission
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $query = EmployeePermission::where('company_id', $user->company_id);

        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            $query->where('user_id', $user->id)->where('status', 'pending');
        }

        $permission = $query->findOrFail($id);

        if ($permission->attachment_path && file_exists(public_path($permission->attachment_path))) {
            @unlink(public_path($permission->attachment_path));
        }

        $permission->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Pengajuan izin berhasil dihapus.',
        ]);
    }
}
