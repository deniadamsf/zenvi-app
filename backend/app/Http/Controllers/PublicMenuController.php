<?php

namespace App\Http\Controllers;

use App\Models\Company;
use App\Models\Member;
use App\Models\MemberPromo;
use App\Models\Product;
use App\Models\Reservation;
use App\Services\FirebaseNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class PublicMenuController extends Controller
{
    /**
     * Display the public digital QR menu / store portal for a specific store.
     */
    public function show($slug)
    {
        // Find company by slug, code, or ID
        $company = Company::where('slug', $slug)
            ->orWhere('code', $slug)
            ->orWhere('id', is_numeric($slug) ? $slug : 0)
            ->with(['branches'])
            ->first();

        if (!$company) {
            return response()->view('menu.digital_menu', [
                'notFound' => true,
                'slug' => $slug,
                'company' => null,
                'products' => collect(),
                'categories' => collect(),
                'memberPromos' => collect(),
            ], 404);
        }

        // Fetch active products
        $products = Product::where('company_id', $company->id)
            ->where('is_active', true)
            ->with(['variants' => function ($q) {
                $q->where('is_active', true);
            }])
            ->orderBy('name', 'asc')
            ->get();

        $categories = $products->pluck('category')
            ->filter(fn($c) => !empty(trim($c ?? '')))
            ->map(fn($c) => trim($c))
            ->unique()
            ->values();

        // Fetch active member promos
        $memberPromos = MemberPromo::where('company_id', $company->id)
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', now()->toDateString());
            })
            ->get();

        return view('menu.digital_menu', [
            'notFound' => false,
            'company' => $company,
            'products' => $products,
            'categories' => $categories,
            'memberPromos' => $memberPromos,
        ]);
    }

    /**
     * Submit public reservation from store portal
     */
    public function submitReservation(Request $request, $slug)
    {
        $company = Company::where('slug', $slug)
            ->orWhere('code', $slug)
            ->orWhere('id', is_numeric($slug) ? $slug : 0)
            ->first();

        if (!$company) {
            return response()->json(['message' => 'Toko tidak ditemukan'], 404);
        }

        if (!$company->is_reservation_enabled) {
            return response()->json(['message' => 'Fitur reservasi saat ini sedang nonaktif'], 400);
        }

        $validated = $request->validate([
            'customer_name' => 'required|string|max:255',
            'customer_phone' => 'required|string|max:50',
            'reservation_date' => 'required|date|after_or_equal:today',
            'reservation_time' => 'required|string|max:10',
            'number_of_people' => 'nullable|integer|min:1|max:100',
            'service_names' => 'nullable|string|max:1000',
            'notes' => 'nullable|string|max:1000',
            'branch_id' => 'nullable|integer',
        ]);

        $reservation = Reservation::create([
            'company_id' => $company->id,
            'branch_id' => $validated['branch_id'] ?? null,
            'customer_name' => $validated['customer_name'],
            'customer_phone' => $validated['customer_phone'],
            'reservation_date' => $validated['reservation_date'],
            'reservation_time' => $validated['reservation_time'],
            'number_of_people' => $validated['number_of_people'] ?? 1,
            'service_names' => $validated['service_names'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'status' => 'pending',
            'created_by_user_id' => null,
        ]);

        // Push Notification to Company (Owner & Employees)
        try {
            $tgl = Carbon::parse($reservation->reservation_date)->format('d M Y');
            $time = substr($reservation->reservation_time, 0, 5);
            $people = $reservation->number_of_people ?? 1;
            FirebaseNotificationService::sendToCompany(
                $company->id,
                'Reservasi Online Baru! 📅',
                "Pelanggan {$reservation->customer_name} booking untuk {$tgl} pkl {$time} ({$people} org).",
                'reservation',
                ['reservation_id' => $reservation->id, 'type' => 'reservation_created', 'route' => '/reservations']
            );
        } catch (\Exception $e) {
            \Log::warning('Reservation notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Reservasi berhasil dikirim! Pihak toko akan segera mengonfirmasi pesanan Anda.',
            'data' => $reservation,
            'company' => [
                'name' => $company->name,
            ]
        ], 201);
    }

    /**
     * API for live search / async fetching of products
     */
    public function apiMenu($slug)
    {
        $company = Company::where('slug', $slug)
            ->orWhere('code', $slug)
            ->orWhere('id', is_numeric($slug) ? $slug : 0)
            ->first();

        if (!$company) {
            return response()->json(['message' => 'Toko tidak ditemukan'], 404);
        }

        $products = Product::where('company_id', $company->id)
            ->where('is_active', true)
            ->with(['variants' => function ($q) {
                $q->where('is_active', true);
            }])
            ->orderBy('name', 'asc')
            ->get();

        $categories = $products->pluck('category')
            ->filter(fn($c) => !empty(trim($c ?? '')))
            ->map(fn($c) => trim($c))
            ->unique()
            ->values();

        return response()->json([
            'company' => [
                'name' => $company->name,
                'code' => $company->code,
                'slug' => $company->slug,
                'description' => $company->qr_menu_description,
                'is_qr_menu_enabled' => $company->is_qr_menu_enabled,
                'is_reservation_enabled' => $company->is_reservation_enabled,
                'reservation_description' => $company->reservation_description,
            ],
            'categories' => $categories,
            'products' => $products
        ]);
    }

    /**
     * Public Self-Registration for Customer Membership from Store Web Portal
     */
    public function registerMember(Request $request, $slug)
    {
        $company = Company::where('slug', $slug)
            ->orWhere('code', $slug)
            ->orWhere('id', is_numeric($slug) ? $slug : 0)
            ->first();

        if (!$company) {
            return response()->json(['message' => 'Toko tidak ditemukan'], 404);
        }

        if (!$company->is_membership_enabled) {
            return response()->json(['message' => 'Fitur pendaftaran member saat ini sedang nonaktif'], 400);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:50',
            'email' => 'nullable|email|max:255',
            'birth_date' => 'nullable|date',
            'address' => 'nullable|string|max:500',
            'notes' => 'nullable|string|max:500',
        ]);

        // Clean and normalize phone number variations (08..., 628..., 8..., +628...)
        $digits = preg_replace('/[^0-9]/', '', $validated['phone']);
        $standardPhone = $digits;
        if (str_starts_with($digits, '0')) {
            $standardPhone = '62' . substr($digits, 1);
        } elseif (str_starts_with($digits, '8')) {
            $standardPhone = '62' . $digits;
        }

        $variations = [$validated['phone'], $digits, $standardPhone];
        if (str_starts_with($digits, '62')) {
            $variations[] = '0' . substr($digits, 2);
            $variations[] = substr($digits, 2);
        } elseif (str_starts_with($digits, '0')) {
            $variations[] = substr($digits, 1);
        } elseif (str_starts_with($digits, '8')) {
            $variations[] = '0' . $digits;
        }
        $variations = array_values(array_unique(array_filter($variations)));

        // Check if phone already registered in this company
        $existing = Member::where('company_id', $company->id)
            ->where(function ($q) use ($variations, $digits) {
                $q->whereIn('phone', $variations);
                if (strlen($digits) >= 8) {
                    $suffix = substr($digits, -8);
                    $q->orWhere('phone', 'LIKE', "%$suffix");
                }
            })
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'is_existing' => true,
                'message' => 'Nomor WhatsApp Anda sudah terdaftar sebagai Member!',
                'data' => $existing,
                'company' => [
                    'name' => $company->name,
                    'default_discount' => $company->default_member_discount_percent,
                    'logo_url' => $company->logo_url,
                    'is_points_enabled' => (bool)$company->is_points_enabled,
                    'point_earning_amount' => (float)($company->point_earning_amount ?? 1000),
                ]
            ], 200);
        }

        $member = Member::createUnique([
            'company_id' => $company->id,
            'name' => $validated['name'],
            'phone' => $standardPhone,
            'email' => $validated['email'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'address' => $validated['address'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'is_active' => true,
            'points' => 0,
            'total_spend' => 0,
            'total_transactions' => 0,
        ]);

        // Push Notification to Company (Owner / POS Staff)
        try {
            FirebaseNotificationService::sendToCompany(
                $company->id,
                'Member Baru Terdaftar! 💎',
                "Pelanggan {$member->name} ({$member->phone}) baru saja mendaftar via Web Portal Toko.",
                'member',
                ['member_id' => $member->id, 'type' => 'member_registered', 'route' => '/members']
            );
        } catch (\Exception $e) {
            \Log::warning('Member registration notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'is_existing' => false,
            'message' => 'Pendaftaran Member Berhasil! Selamat bergabung sebagai member istimewa kami.',
            'data' => $member,
            'company' => [
                'name' => $company->name,
                'default_discount' => $company->default_member_discount_percent,
                'logo_url' => $company->logo_url,
                'is_points_enabled' => (bool)$company->is_points_enabled,
                'point_earning_amount' => (float)($company->point_earning_amount ?? 1000),
            ]
        ], 201);
    }

    /**
     * Check existing Member Card by Phone Number
     */
    public function checkMember(Request $request, $slug)
    {
        $company = Company::where('slug', $slug)
            ->orWhere('code', $slug)
            ->orWhere('id', is_numeric($slug) ? $slug : 0)
            ->first();

        if (!$company) {
            return response()->json(['message' => 'Toko tidak ditemukan'], 404);
        }

        $rawPhone = $request->get('phone', '');
        $digits = preg_replace('/[^0-9]/', '', $rawPhone);

        if (empty($digits)) {
            return response()->json(['message' => 'Nomor WhatsApp wajib diisi'], 422);
        }

        // Generate variations: 08..., 628..., 8..., +628..., raw
        $variations = [$rawPhone, $digits];
        if (str_starts_with($digits, '62')) {
            $variations[] = '0' . substr($digits, 2);
            $variations[] = substr($digits, 2);
        } elseif (str_starts_with($digits, '0')) {
            $variations[] = '62' . substr($digits, 1);
            $variations[] = substr($digits, 1);
        } elseif (str_starts_with($digits, '8')) {
            $variations[] = '62' . $digits;
            $variations[] = '0' . $digits;
        }
        $variations = array_values(array_unique(array_filter($variations)));

        $member = Member::where('company_id', $company->id)
            ->where(function ($q) use ($variations, $digits) {
                $q->whereIn('phone', $variations);
                if (strlen($digits) >= 8) {
                    $suffix = substr($digits, -8);
                    $q->orWhere('phone', 'LIKE', "%$suffix");
                }
            })
            ->first();

        if (!$member) {
            return response()->json([
                'success' => false,
                'message' => 'Nomor WhatsApp belum terdaftar sebagai member di toko ini.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $member,
            'company' => [
                'name' => $company->name,
                'default_discount' => $company->default_member_discount_percent,
                'logo_url' => $company->logo_url,
                'is_points_enabled' => (bool)$company->is_points_enabled,
                'point_earning_amount' => (float)($company->point_earning_amount ?? 1000),
            ]
        ]);
    }
}
