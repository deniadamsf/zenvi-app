<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\Entitlements;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    /**
     * Katalog paket untuk halaman "Paket Langganan" di aplikasi.
     *
     * Disajikan dari config/plans.php supaya katalognya tidak perlu digandakan
     * di sisi Dart - kalau digandakan, daftar fitur di aplikasi akan menyimpang
     * dari yang benar-benar ditegakkan server begitu salah satunya diubah.
     *
     * HARGA SENGAJA TIDAK ADA DI SINI. Pembayaran memakai Google Play Billing,
     * jadi harga datang dari Play Console lewat plugin in_app_purchase. Kalau
     * harga juga dikirim dari sini, aplikasi bisa menampilkan angka yang berbeda
     * dari yang benar-benar ditagih Google.
     */
    public function index(Request $request)
    {
        $entitlements = Entitlements::for($request->user()?->company);
        $featureLabels = config('plans.features', []);

        $plans = collect(config('plans.plans', []))
            ->map(function ($plan, $code) use ($featureLabels) {
                return [
                    'code'     => $code,
                    'name'     => $plan['name'] ?? $code,
                    'rank'     => $plan['rank'] ?? 0,
                    'limits'   => $plan['limits'] ?? [],
                    'features' => collect($plan['features'] ?? [])
                        ->map(fn ($f) => [
                            'key'   => $f,
                            'label' => $featureLabels[$f] ?? $f,
                        ])
                        ->values(),
                ];
            })
            ->sortBy('rank')
            ->values();

        return response()->json([
            'data' => [
                'current_plan' => $entitlements->planCode(),
                'plans'        => $plans,
                'usage'        => [
                    'products'  => $entitlements->usage('products'),
                    'employees' => $entitlements->usage('employees'),
                    'branches'  => $entitlements->usage('branches'),
                ],
            ],
        ]);
    }
}
