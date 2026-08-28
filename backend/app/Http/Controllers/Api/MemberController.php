<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Member;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    /**
     * Display a listing of members with search and stats
     */
    public function index(Request $request)
    {
        $companyId = $request->user()->company_id;
        $query = Member::where('company_id', $companyId);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('member_code', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        $sort = $request->get('sort', 'latest');
        if ($sort === 'top_spend') {
            $query->orderBy('total_spend', 'desc');
        } elseif ($sort === 'top_transactions') {
            $query->orderBy('total_transactions', 'desc');
        } elseif ($sort === 'name_asc') {
            $query->orderBy('name', 'asc');
        } else {
            $query->latest();
        }

        $members = $query->get();

        // Calculate summary stats
        $totalMembers = Member::where('company_id', $companyId)->count();
        $activeMembers = Member::where('company_id', $companyId)->where('is_active', true)->count();
        $totalSpendSum = Member::where('company_id', $companyId)->sum('total_spend');
        $totalTransactionsSum = Member::where('company_id', $companyId)->sum('total_transactions');

        return response()->json([
            'data' => $members,
            'summary' => [
                'total_members' => $totalMembers,
                'active_members' => $activeMembers,
                'total_member_sales' => (float) $totalSpendSum,
                'total_member_transactions' => (int) $totalTransactionsSum,
            ]
        ]);
    }

    /**
     * Store a newly created member
     */
    public function store(Request $request)
    {
        $companyId = $request->user()->company_id;

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:50',
            'email' => 'nullable|email|max:255',
            'member_code' => 'nullable|string|max:50',
            'address' => 'nullable|string',
            'birth_date' => 'nullable|date',
            'custom_discount_percent' => 'nullable|numeric|min:0|max:100',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        // Clean & normalize phone number (08123 -> 628123)
        $phone = preg_replace('/[^0-9]/', '', $validated['phone']);
        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        } elseif (str_starts_with($phone, '8')) {
            $phone = '62' . $phone;
        }
        $validated['phone'] = $phone;

        // Check if phone or member_code already exists for this company
        $existingPhone = Member::where('company_id', $companyId)
            ->where('phone', $validated['phone'])
            ->first();
        if ($existingPhone) {
            return response()->json([
                'message' => "Nomor telepon ({$validated['phone']}) sudah terdaftar untuk member {$existingPhone->name} ({$existingPhone->member_code})."
            ], 422);
        }

        if (!empty($validated['member_code'])) {
            $existingCode = Member::where('company_id', $companyId)
                ->where('member_code', $validated['member_code'])
                ->first();
            if ($existingCode) {
                return response()->json([
                    'message' => "Kode member {$validated['member_code']} sudah digunakan."
                ], 422);
            }
        }

        $validated['company_id'] = $companyId;
        $member = Member::createUnique($validated);

        return response()->json([
            'message' => 'Member berhasil didaftarkan.',
            'data' => $member
        ], 201);
    }

    /**
     * Display the specified member with recent order history
     */
    public function show($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $member = Member::where('company_id', $companyId)->findOrFail($id);

        $recentOrders = $member->orders()
            ->with(['items.product', 'user', 'servicedBy'])
            ->latest()
            ->take(10)
            ->get();

        return response()->json([
            'data' => $member,
            'recent_orders' => $recentOrders
        ]);
    }

    /**
     * Update the specified member
     */
    public function update($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $member = Member::where('company_id', $companyId)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:50',
            'email' => 'nullable|email|max:255',
            'member_code' => 'nullable|string|max:50',
            'address' => 'nullable|string',
            'birth_date' => 'nullable|date',
            'points' => 'nullable|integer|min:0',
            'custom_discount_percent' => 'nullable|numeric|min:0|max:100',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        if (isset($validated['phone'])) {
            $phone = preg_replace('/[^0-9]/', '', $validated['phone']);
            if (str_starts_with($phone, '0')) {
                $phone = '62' . substr($phone, 1);
            } elseif (str_starts_with($phone, '8')) {
                $phone = '62' . $phone;
            }
            $validated['phone'] = $phone;

            $existingPhone = Member::where('company_id', $companyId)
                ->where('phone', $validated['phone'])
                ->where('id', '!=', $member->id)
                ->first();
            if ($existingPhone) {
                return response()->json([
                    'message' => "Nomor telepon ({$validated['phone']}) sudah terdaftar untuk member {$existingPhone->name} ({$existingPhone->member_code})."
                ], 422);
            }
        }

        if (!empty($validated['member_code']) && $validated['member_code'] !== $member->member_code) {
            $existingCode = Member::where('company_id', $companyId)
                ->where('member_code', $validated['member_code'])
                ->where('id', '!=', $member->id)
                ->first();
            if ($existingCode) {
                return response()->json([
                    'message' => "Kode member {$validated['member_code']} sudah digunakan."
                ], 422);
            }
        }

        $member->update($validated);

        return response()->json([
            'message' => 'Data member berhasil diperbarui.',
            'data' => $member
        ]);
    }

    /**
     * Remove the specified member
     */
    public function destroy($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $member = Member::where('company_id', $companyId)->findOrFail($id);

        $member->delete();

        return response()->json([
            'message' => 'Member berhasil dihapus.'
        ]);
    }
}
