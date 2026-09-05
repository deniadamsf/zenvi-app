<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PlayBillingService;
use App\Support\Entitlements;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class BillingController extends Controller
{
    /**
     * Memverifikasi pembelian Google Play lalu mengaktifkan paket.
     *
     * Ini satu-satunya jalan `companies.plan_code` boleh berubah karena
     * pembelian. Aplikasi hanya mengirimkan purchaseToken; yang menentukan
     * paketnya adalah balasan Google, bukan apa pun yang dikirim klien.
     * Klien yang dimodifikasi bisa mengirim product_id apa saja - product_id
     * yang dipakai untuk menentukan paket diambil dari data terverifikasi.
     */
    public function verifyPlay(Request $request)
    {
        $request->validate([
            'product_id'     => 'required|string|max:64',
            'purchase_token' => 'required|string',
        ]);

        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json([
                'message' => 'Hanya pemilik toko yang dapat mengelola langganan.',
            ], 403);
        }

        $company = $user->company;
        if (!$company) {
            return response()->json(['message' => 'Perusahaan tidak ditemukan.'], 404);
        }

        if (!PlayBillingService::isConfigured()) {
            Log::error('PlayBilling: verifikasi diminta tapi service account belum dipasang.');
            return response()->json([
                'message' => 'Verifikasi pembelian belum aktif. Hubungi dukungan Zenvi.',
            ], 503);
        }

        $token = $request->purchase_token;
        $payload = PlayBillingService::fetchSubscription($token);

        // null berarti Google tidak mengonfirmasi. Ini HARUS ditolak - menganggap
        // "mungkin benar" akan memberi paket berbayar kepada token palsu.
        if (!$payload) {
            return response()->json([
                'message' => 'Pembelian tidak dapat diverifikasi ke Google Play.',
            ], 422);
        }

        $planCode = PlayBillingService::planCodeFor($request->product_id);
        if (!$planCode) {
            return response()->json([
                'message' => 'Produk langganan tidak dikenali.',
            ], 422);
        }

        $status = PlayBillingService::mapState($payload['subscriptionState'] ?? null);
        $expiry = $this->expiryFrom($payload);
        $tokenHash = hash('sha256', $token);

        DB::transaction(function () use ($company, $request, $token, $tokenHash, $planCode, $status, $expiry, $payload) {
            // updateOrCreate pada token_hash yang unik: token yang sama dikirim
            // ulang hanya memperbarui baris yang ada, tidak pernah menambah
            // pembelian baru.
            DB::table('subscription_purchases')->updateOrInsert(
                ['token_hash' => $tokenHash],
                [
                    'company_id'     => $company->id,
                    'product_id'     => $request->product_id,
                    'purchase_token' => $token,
                    'order_id'       => $payload['latestOrderId'] ?? null,
                    'plan_code'      => $planCode,
                    'status'         => $status,
                    'expiry_time'    => $expiry,
                    'verified_at'    => now(),
                    'raw_payload'    => json_encode($payload),
                    'updated_at'     => now(),
                    'created_at'     => now(),
                ]
            );

            // Toko founding member tidak pernah diturunkan oleh pembelian:
            // plan_expires_at mereka NULL (tanpa kedaluwarsa), dan menimpanya
            // dengan tanggal berakhir Google akan mencabut hak seumur hidup
            // yang sudah dijanjikan.
            if ($company->is_founding_member) {
                return;
            }

            $company->update([
                'plan_code'       => $status === 'expired' ? 'free' : $planCode,
                'plan_status'     => $status,
                'plan_expires_at' => $expiry,
            ]);
        });

        $company->refresh();

        return response()->json([
            'message' => 'Langganan berhasil diaktifkan.',
            'data'    => Entitlements::for($company)->summary(),
        ]);
    }

    /**
     * Status langganan toko saat ini, dipakai halaman Paket.
     */
    public function status(Request $request)
    {
        $company = $request->user()->company;

        return response()->json([
            'data' => [
                'plan'              => Entitlements::for($company)->summary(),
                'billing_available' => PlayBillingService::isConfigured(),
            ],
        ]);
    }

    /**
     * Google mengirim waktu berakhir sebagai RFC3339 di dalam lineItems.
     * Diambil yang paling jauh, karena satu langganan bisa punya beberapa item.
     */
    private function expiryFrom(array $payload): ?Carbon
    {
        $latest = null;
        foreach ($payload['lineItems'] ?? [] as $item) {
            if (empty($item['expiryTime'])) {
                continue;
            }
            try {
                $time = Carbon::parse($item['expiryTime']);
            } catch (\Throwable $e) {
                continue;
            }
            if (!$latest || $time->greaterThan($latest)) {
                $latest = $time;
            }
        }

        return $latest;
    }
}
