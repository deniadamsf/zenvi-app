<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\JoinCompanyRequest;
use App\Http\Requests\StoreCompanyRequest;
use App\Models\Branch;
use App\Models\Company;
use App\Models\InAppNotification;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class CompanyController extends Controller
{
    /**
     * Get current user's company
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->company_id) {
            return response()->json(['message' => 'Anda belum bergabung dengan perusahaan manapun.'], 404);
        }

        return response()->json([
            'data' => $user->load('company')->company
        ]);
    }

    public function publicList()
    {
        // Publicly list companies (id and name only) for dropdown selection
        $companies = Company::select('id', 'name')->get();
        return response()->json($companies);
    }

    /**
     * Lookup company and branches by unique company code (e.g. ZNV-XXXX)
     */
    public function lookupByCode(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $code = strtoupper(trim($request->code));
        $company = Company::with('branches')->where('code', $code)->first();

        if (!$company) {
            return response()->json([
                'status' => 'error',
                'message' => 'Toko dengan kode "' . $code . '" tidak ditemukan. Harap tanyakan kode toko ke Owner Anda.'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'id' => $company->id,
                'name' => $company->name,
                'code' => $company->code,
                'logo_url' => $company->logo_url,
                'branches' => $company->branches,
            ]
        ]);
    }

    /**
     * Store a newly created company in storage.
     */
    public function store(StoreCompanyRequest $request)
    {
        $user = $request->user();

        // Generate unique code like ZNV-8829
        $code = 'ZNV-' . strtoupper(Str::random(4));
        while (Company::where('code', $code)->exists()) {
            $code = 'ZNV-' . strtoupper(Str::random(4));
        }

        $company = Company::create([
            'name' => $request->name,
            'code' => $code,
            'is_kds_enabled' => $request->boolean('is_kds_enabled', false),
        ]);

        // Automatically assign user to this company as Owner and approved
        $user->update([
            'company_id' => $company->id,
            'role' => 'Owner',
            'is_approved' => true,
        ]);

        return response()->json([
            'message' => 'Perusahaan berhasil dibuat.',
            'data' => $company
        ], 201);
    }

    /**
     * Join an existing company using company_id and branch_id
     */
    public function join(JoinCompanyRequest $request)
    {
        $user = $request->user();
        
        $company = Company::where('id', $request->company_id)->first();
        if (!$company) {
            return response()->json(['message' => 'Perusahaan tidak ditemukan.'], 404);
        }

        $branch = Branch::where('id', $request->branch_id)->where('company_id', $company->id)->first();
        $branchName = $branch ? $branch->name : 'Utama';

        // Join as Employee (Cashier), pending approval
        $user->update([
            'company_id' => $company->id,
            'branch_id' => $request->branch_id,
            'role' => 'Employee',
            'is_approved' => false,
        ]);

        // Send In-App notification to Owner
        try {
            InAppNotification::create([
                'company_id' => $company->id,
                'target_role' => 'Owner',
                'title' => 'Pendaftar Karyawan Baru',
                'body' => $user->name . ' mengajukan bergabung di cabang ' . $branchName . '. Buka menu Kelola Tim untuk verifikasi.',
                'type' => 'employee_pending',
                'data_payload' => [
                    'user_id' => $user->id,
                    'user_name' => $user->name,
                    'branch_id' => $request->branch_id,
                    'branch_name' => $branchName,
                ],
                'is_read' => false,
            ]);
        } catch (\Exception $e) {
            Log::error('Gagal membuat in-app notification pendaftar baru: ' . $e->getMessage());
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Berhasil mengajukan bergabung dengan ' . $company->name . '. Menunggu persetujuan Owner.',
            'data' => [
                'company' => $company,
                'user' => $user->fresh(['company', 'branch']),
            ]
        ]);
    }

    /**
     * Cancel pending join request for employee
     */
    public function cancelJoin(Request $request)
    {
        $user = $request->user();
        
        if ($user->role === 'Owner') {
            return response()->json([
                'status' => 'error',
                'message' => 'Owner tidak dapat membatalkan status toko.'
            ], 403);
        }

        $user->update([
            'company_id' => null,
            'branch_id' => null,
            'is_approved' => false,
            'role' => 'Employee',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Pendaftaran berhasil dibatalkan. Anda dapat memilih peran atau toko lain.',
            'data' => [
                'user' => $user->fresh(['company', 'branch']),
            ]
        ]);
    }

    public function updateLocation(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius_meters' => 'required|integer|min:10',
        ]);

        $company = $user->company;
        $company->update([
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'radius_meters' => $request->radius_meters,
        ]);

        return response()->json([
            'message' => 'Lokasi toko berhasil diperbarui.',
            'data' => $company
        ]);
    }

    public function updateSettings(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'require_opname_on_shift_close' => 'sometimes|boolean',
            'require_attendance' => 'sometimes|boolean',
            'require_schedule' => 'sometimes|boolean',
            'require_cash_drawer_balance' => 'sometimes|boolean',
            'is_qris_enabled' => 'sometimes|boolean',
            'is_transfer_enabled' => 'sometimes|boolean',
            'late_tolerance_minutes' => 'sometimes|integer',
            'shift_schedules' => 'sometimes|array',
            'is_qr_menu_enabled' => 'sometimes|boolean',
            'is_reservation_enabled' => 'sometimes|boolean',
            'is_membership_enabled' => 'sometimes|boolean',
            'default_member_discount_percent' => 'sometimes|numeric|min:0|max:100',
            'is_points_enabled' => 'sometimes|boolean',
            'point_earning_amount' => 'sometimes|numeric|min:1',
            'point_redeem_rate' => 'sometimes|numeric|min:0.01',
            'slug' => 'sometimes|nullable|string|max:100',
            'qr_menu_description' => 'sometimes|nullable|string|max:1000',
            'reservation_description' => 'sometimes|nullable|string|max:1000',
            'is_kds_enabled' => 'sometimes|boolean',
            'is_product_image_enabled' => 'sometimes|boolean',
            'default_language' => 'sometimes|string|in:id,en',
        ]);

        $company = $user->company;
        
        $updates = [];
        if ($request->has('require_opname_on_shift_close')) {
            $updates['require_opname_on_shift_close'] = $request->require_opname_on_shift_close;
        }
        if ($request->has('require_attendance')) {
            $updates['require_attendance'] = $request->require_attendance;
        }
        if ($request->has('require_schedule')) {
            $updates['require_schedule'] = $request->require_schedule;
        }
        if ($request->has('require_cash_drawer_balance')) {
            $updates['require_cash_drawer_balance'] = $request->require_cash_drawer_balance;
        }
        if ($request->has('is_qris_enabled')) {
            $updates['is_qris_enabled'] = $request->is_qris_enabled;
        }
        if ($request->has('is_transfer_enabled')) {
            $updates['is_transfer_enabled'] = $request->is_transfer_enabled;
        }
        if ($request->has('late_tolerance_minutes')) {
            $updates['late_tolerance_minutes'] = $request->late_tolerance_minutes;
        }
        if ($request->has('shift_schedules')) {
            $updates['shift_schedules'] = $request->shift_schedules;
        }
        if ($request->has('is_membership_enabled')) {
            $updates['is_membership_enabled'] = $request->is_membership_enabled;
        }
        if ($request->has('default_member_discount_percent')) {
            $updates['default_member_discount_percent'] = $request->default_member_discount_percent;
        }
        if ($request->has('is_points_enabled')) {
            $updates['is_points_enabled'] = $request->is_points_enabled;
        }
        if ($request->has('point_earning_amount')) {
            $updates['point_earning_amount'] = $request->point_earning_amount;
        }
        if ($request->has('point_redeem_rate')) {
            $updates['point_redeem_rate'] = $request->point_redeem_rate;
        }
        if ($request->has('is_kds_enabled')) {
            $updates['is_kds_enabled'] = $request->is_kds_enabled;
        }
        if ($request->has('is_product_image_enabled')) {
            $updates['is_product_image_enabled'] = $request->is_product_image_enabled;
        }
        if ($request->has('is_qr_menu_enabled')) {
            $updates['is_qr_menu_enabled'] = $request->is_qr_menu_enabled;
            if ($request->is_qr_menu_enabled && empty($company->slug) && !$request->has('slug')) {
                $baseSlug = Str::slug($company->name) ?: 'toko';
                $slug = $baseSlug;
                $count = 1;
                while (Company::where('slug', $slug)->where('id', '!=', $company->id)->exists()) {
                    $slug = $baseSlug . '-' . $count;
                    $count++;
                }
                $updates['slug'] = $slug;
            }
        }
        if ($request->has('is_reservation_enabled')) {
            $updates['is_reservation_enabled'] = $request->is_reservation_enabled;
            if ($request->is_reservation_enabled && empty($company->slug) && !$request->has('slug') && !isset($updates['slug'])) {
                $baseSlug = Str::slug($company->name) ?: 'toko';
                $slug = $baseSlug;
                $count = 1;
                while (Company::where('slug', $slug)->where('id', '!=', $company->id)->exists()) {
                    $slug = $baseSlug . '-' . $count;
                    $count++;
                }
                $updates['slug'] = $slug;
            }
        }
        if ($request->has('slug')) {
            $newSlug = Str::slug($request->slug);
            if (!empty($newSlug)) {
                // Ensure uniqueness
                $slug = $newSlug;
                $count = 1;
                while (Company::where('slug', $slug)->where('id', '!=', $company->id)->exists()) {
                    $slug = $newSlug . '-' . $count;
                    $count++;
                }
                $updates['slug'] = $slug;
            }
        }
        if ($request->has('qr_menu_description')) {
            $updates['qr_menu_description'] = $request->qr_menu_description;
        }
        if ($request->has('reservation_description')) {
            $updates['reservation_description'] = $request->reservation_description;
        }
        if ($request->has('name')) {
            $updates['name'] = $request->name;
        }
        if ($request->has('default_language')) {
            $updates['default_language'] = $request->default_language;
        }
        
        $company->update($updates);

        return response()->json([
            'message' => 'Pengaturan toko berhasil diperbarui.',
            'data' => $company
        ]);
    }

    public function pendingEmployees(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $pendingUsers = User::where('company_id', $user->company_id)
            ->where('is_approved', false)
            ->where('id', '!=', $user->id)
            ->get();

        return response()->json($pendingUsers);
    }

    public function activeEmployees(Request $request)
    {
        $user = $request->user();
        $activeUsers = User::where('company_id', $user->company_id)
            ->where(function($q) {
                $q->where('is_approved', true)->orWhere('role', 'Owner');
            })
            ->where('id', '!=', $user->id)
            ->get();

        foreach ($activeUsers as $employee) {
            $lastMessage = \App\Models\Message::where(function($q) use ($user, $employee) {
                $q->where('sender_id', $user->id)->where('receiver_id', $employee->id);
            })->orWhere(function($q) use ($user, $employee) {
                $q->where('sender_id', $employee->id)->where('receiver_id', $user->id);
            })->orderBy('created_at', 'desc')->first();

            $employee->last_message = $lastMessage ? $lastMessage->message : 'Mulai percakapan';
            $employee->last_message_time = $lastMessage ? $lastMessage->created_at : null;
        }

        return response()->json($activeUsers);
    }

    public function approveEmployee(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'job_title' => 'sometimes|nullable|string|max:100',
            'permissions' => 'sometimes|nullable|array',
        ]);

        $employee = User::where('company_id', $user->company_id)->findOrFail($id);
        
        $updates = ['is_approved' => true];
        if ($request->has('job_title')) {
            $updates['job_title'] = $request->job_title;
        }
        if ($request->has('permissions')) {
            $updates['permissions'] = $request->permissions;
        }

        $employee->update($updates);

        return response()->json([
            'message' => 'Karyawan berhasil disetujui.',
            'data' => $employee
        ]);
    }

    public function updateEmployeePermissions(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'job_title' => 'sometimes|nullable|string|max:100',
            'permissions' => 'required|array',
        ]);

        $employee = User::where('company_id', $user->company_id)->findOrFail($id);
        
        $updates = [
            'permissions' => $request->permissions,
        ];
        if ($request->has('job_title')) {
            $updates['job_title'] = $request->job_title;
        }

        $employee->update($updates);

        return response()->json([
            'message' => 'Hak akses karyawan berhasil diperbarui.',
            'data' => $employee
        ]);
    }

    public function removeEmployee(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $employee = User::where('company_id', $user->company_id)->findOrFail($id);
        
        // Don't allow owner to remove themselves
        if ($employee->id === $user->id) {
            return response()->json(['message' => 'Anda tidak bisa menghapus diri sendiri.'], 400);
        }

        // Auto-close any active shift the employee has
        $activeShift = \App\Models\Shift::where('user_id', $employee->id)
            ->where('status', 'active')
            ->first();
        
        if ($activeShift) {
            $activeShift->update([
                'status' => 'closed',
                'end_time' => now(),
                'closing_balance' => $activeShift->opening_balance, // Default to opening
            ]);
        }

        // Revoke all API tokens so the fired employee is immediately logged out
        $employee->tokens()->delete();

        // Also clean up FCM device tokens
        \App\Models\UserDevice::where('user_id', $employee->id)->delete();

        $employee->update([
            'company_id' => null,
            'branch_id' => null,
            'role' => 'Employee',
            'job_title' => 'Kasir',
            'permissions' => null,
            'is_approved' => false
        ]);

        return response()->json(['message' => 'Karyawan berhasil dihapus dari perusahaan.']);
    }

    public function uploadLogo(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $company = $user->company;
        if (!$company) {
            return response()->json(['message' => 'Perusahaan tidak ditemukan.'], 404);
        }

        if ($request->boolean('remove_logo') || $request->has('remove_logo')) {
            if ($company->logo_path && file_exists(public_path($company->logo_path))) {
                @unlink(public_path($company->logo_path));
            }
            $company->update(['logo_path' => null]);
            return response()->json([
                'message' => 'Logo toko berhasil dihapus.',
                'data' => $company->fresh()
            ]);
        }

        $request->validate([
            'logo' => 'required|image|mimes:jpeg,png,jpg,webp|max:3072',
        ]);

        if ($request->hasFile('logo')) {
            $image = $request->file('logo');
            $filename = 'logo_' . $company->id . '_' . time() . '.' . $image->getClientOriginalExtension();
            $path = 'uploads/logos/' . $filename;

            $manager = new ImageManager(new Driver());
            $img = $manager->read($image);
            $img->cover(400, 400);

            $destinationPath = public_path('uploads/logos');
            if (!file_exists($destinationPath)) {
                mkdir($destinationPath, 0755, true);
            }
            $img->save(public_path($path));

            // Delete previous logo file if exists
            if ($company->logo_path && file_exists(public_path($company->logo_path))) {
                @unlink(public_path($company->logo_path));
            }

            $company->update(['logo_path' => $path]);

            return response()->json([
                'message' => 'Logo toko berhasil diperbarui.',
                'data' => $company->fresh()
            ]);
        }

        return response()->json(['message' => 'Tidak ada file logo yang diunggah.'], 422);
    }
}
