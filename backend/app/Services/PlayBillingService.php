<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Memverifikasi pembelian langganan langsung ke Google Play Developer API.
 *
 * Alur OAuth2-nya sengaja menyalin FirebaseNotificationService::getAccessToken()
 * yang sudah terbukti jalan di server ini - JWT RS256 dirakit manual dengan
 * openssl_sign lalu ditukar di oauth2.googleapis.com. Yang berbeda hanya scope.
 * Menyalin pola ini menghindari penambahan paket google/apiclient beserta
 * puluhan dependensinya hanya untuk satu panggilan HTTP.
 */
class PlayBillingService
{
    private const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
    private const CACHE_KEY = 'play_billing_access_token';

    /**
     * Lokasi kredensial service account.
     *
     * Dibaca lewat config(), BUKAN env() - env() di luar folder config/ selalu
     * mengembalikan null setelah `php artisan config:cache`, dan deploy di
     * project ini selalu diakhiri config:cache.
     */
    protected static function credentialsPath(): ?string
    {
        $custom = config('services.play.credentials');
        if ($custom && file_exists(base_path($custom))) {
            return base_path($custom);
        }

        foreach ([
            storage_path('app/play-service-account.json'),
            storage_path('app/google-play-service-account.json'),
        ] as $candidate) {
            if (file_exists($candidate)) {
                return $candidate;
            }
        }

        return null;
    }

    public static function isConfigured(): bool
    {
        return self::credentialsPath() !== null;
    }

    protected static function accessToken(): ?string
    {
        $path = self::credentialsPath();
        if (!$path) {
            Log::warning('PlayBilling: service account belum dipasang di server.');
            return null;
        }

        return Cache::remember(self::CACHE_KEY, 3300, function () use ($path) {
            try {
                $cred = json_decode(file_get_contents($path), true);
                if (empty($cred['private_key']) || empty($cred['client_email'])) {
                    Log::error('PlayBilling: struktur service account tidak valid.');
                    return null;
                }

                $now = time();
                $encode = fn ($data) => str_replace(
                    ['+', '/', '='],
                    ['-', '_', ''],
                    base64_encode(json_encode($data))
                );

                $input = $encode(['alg' => 'RS256', 'typ' => 'JWT']) . '.' . $encode([
                    'iss'   => $cred['client_email'],
                    'scope' => self::SCOPE,
                    'aud'   => 'https://oauth2.googleapis.com/token',
                    'exp'   => $now + 3600,
                    'iat'   => $now,
                ]);

                $key = openssl_pkey_get_private($cred['private_key']);
                if (!$key) {
                    Log::error('PlayBilling: private key tidak bisa dibaca.');
                    return null;
                }

                $signature = '';
                openssl_sign($input, $signature, $key, OPENSSL_ALGO_SHA256);
                $jwt = $input . '.' . str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion'  => $jwt,
                ]);

                if (!$response->successful()) {
                    Log::error('PlayBilling: gagal menukar JWT: ' . $response->body());
                    return null;
                }

                return $response->json()['access_token'] ?? null;
            } catch (\Throwable $e) {
                Log::error('PlayBilling exception saat mengambil token: ' . $e->getMessage());
                return null;
            }
        });
    }

    /**
     * Menanyakan status langganan ke Google.
     *
     * Mengembalikan null kalau tidak bisa diverifikasi - dan null HARUS
     * diperlakukan sebagai penolakan, bukan sebagai "anggap saja benar".
     */
    public static function fetchSubscription(string $purchaseToken): ?array
    {
        $token = self::accessToken();
        if (!$token) {
            return null;
        }

        $package = config('services.play.package_name');
        if (!$package) {
            Log::error('PlayBilling: services.play.package_name belum diisi.');
            return null;
        }

        $url = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
            . $package . "/purchases/subscriptionsv2/tokens/" . urlencode($purchaseToken);

        $response = Http::withToken($token)->get($url);

        if (!$response->successful()) {
            Log::warning('PlayBilling: Google menolak verifikasi: ' . $response->body());
            return null;
        }

        return $response->json();
    }

    /**
     * Memetakan status langganan Google ke plan_status internal.
     *
     * Nilai subscriptionState dari Google:
     *   ACTIVE, IN_GRACE_PERIOD, ON_HOLD, PAUSED, CANCELED, EXPIRED, PENDING
     *
     * CANCELED tetap dianggap aktif selama belum lewat tanggal berakhir -
     * pelanggan yang membatalkan tetap berhak memakai sampai periode yang sudah
     * dibayarnya habis. Memutus aksesnya seketika sama dengan mengambil kembali
     * sesuatu yang sudah dibayar.
     */
    public static function mapState(?string $state): string
    {
        return match ($state) {
            'SUBSCRIPTION_STATE_ACTIVE'          => 'active',
            'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' => 'grace',
            'SUBSCRIPTION_STATE_CANCELED'        => 'active',
            'SUBSCRIPTION_STATE_ON_HOLD',
            'SUBSCRIPTION_STATE_PAUSED',
            'SUBSCRIPTION_STATE_EXPIRED'         => 'expired',
            default                              => 'expired',
        };
    }

    /**
     * Kode paket dari product id Play.
     */
    public static function planCodeFor(string $productId): ?string
    {
        if (str_starts_with($productId, 'zenvi_premium_')) {
            return 'premium';
        }
        if (str_starts_with($productId, 'zenvi_business_')) {
            return 'business';
        }
        return null;
    }
}
