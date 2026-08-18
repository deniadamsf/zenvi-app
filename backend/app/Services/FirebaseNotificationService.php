<?php

namespace App\Services;

use App\Models\InAppNotification;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseNotificationService
{
    /**
     * Path to Firebase Service Account JSON file.
     * Can be customized in .env: FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json
     */
    protected static function getCredentialsPath(): ?string
    {
        $customPath = env('FIREBASE_CREDENTIALS');
        if ($customPath && file_exists(base_path($customPath))) {
            return base_path($customPath);
        }

        $candidates = [
            storage_path('app/firebase/service-account.json'),
            storage_path('app/firebase-service-account.json'),
            storage_path('app/service-account.json'),
        ];

        foreach ($candidates as $cand) {
            if (file_exists($cand)) {
                return $cand;
            }
        }

        // Auto-detect any firebase json file inside storage/app/ or storage/app/firebase/
        $globFiles = array_merge(
            glob(storage_path('app/*firebase*.json')) ?: [],
            glob(storage_path('app/firebase/*.json')) ?: [],
            glob(storage_path('app/*adminsdk*.json')) ?: []
        );

        foreach ($globFiles as $file) {
            if (is_file($file)) {
                return $file;
            }
        }

        return null;
    }

    /**
     * Generate OAuth2 Access Token using Google Service Account (JWT RS256)
     */
    protected static function getAccessToken(): ?array
    {
        $credPath = self::getCredentialsPath();
        if (!$credPath) {
            Log::info('Firebase Notification: service-account.json not found. Skipping push notification.');
            return null;
        }

        return Cache::remember('fcm_access_token', 3300, function () use ($credPath) {
            try {
                $credentials = json_decode(file_get_contents($credPath), true);
                if (!$credentials || empty($credentials['private_key']) || empty($credentials['client_email']) || empty($credentials['project_id'])) {
                    Log::error('Firebase Notification: Invalid service-account.json structure.');
                    return null;
                }

                $now = time();
                $header = ['alg' => 'RS256', 'typ' => 'JWT'];
                $claim = [
                    'iss' => $credentials['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'exp' => $now + 3600,
                    'iat' => $now,
                ];

                $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($header)));
                $base64UrlClaim = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($claim)));
                $signatureInput = $base64UrlHeader . '.' . $base64UrlClaim;

                $signature = '';
                $privateKey = openssl_pkey_get_private($credentials['private_key']);
                if (!$privateKey) {
                    Log::error('Firebase Notification: Unable to parse private key.');
                    return null;
                }

                openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
                $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
                $jwt = $signatureInput . '.' . $base64UrlSignature;

                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if ($response->successful()) {
                    $tokenData = $response->json();
                    return [
                        'access_token' => $tokenData['access_token'],
                        'project_id' => $credentials['project_id'],
                    ];
                } else {
                    Log::error('Firebase Notification: Failed to obtain access token from Google: ' . $response->body());
                    return null;
                }
            } catch (\Exception $e) {
                Log::error('Firebase Notification Exception: ' . $e->getMessage());
                return null;
            }
        });
    }

    /**
     * Send Push Notification via FCM HTTP v1 to specific device tokens
     */
    protected static function sendFcmToTokens(array $tokens, string $title, string $body, array $data = []): void
    {
        $uniqueTokens = array_values(array_filter(array_unique($tokens)));
        if (empty($uniqueTokens)) {
            return;
        }

        $authInfo = self::getAccessToken();
        if (!$authInfo) {
            return;
        }

        $accessToken = $authInfo['access_token'];
        $projectId = $authInfo['project_id'];
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        // Convert all data values to string for FCM payload compatibility
        $stringData = [];
        foreach ($data as $key => $val) {
            $stringData[(string)$key] = is_array($val) ? json_encode($val) : (string)$val;
        }

        // Fast parallel dispatch using Http::pool
        if (count($uniqueTokens) === 1) {
            $token = $uniqueTokens[0];
            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $stringData,
                    'android' => [
                        'priority' => 'HIGH',
                        'notification' => [
                            'sound' => 'default',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                            'channel_id' => 'zenvi_channel_high_importance',
                            'icon' => 'ic_launcher',
                            'color' => '#00796B',
                        ],
                    ],
                ],
            ];

            try {
                $res = Http::withToken($accessToken)
                    ->timeout(5)
                    ->withHeaders(['Content-Type' => 'application/json; UTF-8'])
                    ->post($url, $payload);

                if ($res->failed()) {
                    $error = $res->json();
                    Log::warning("FCM Send failed for token: {$token}. Error: " . json_encode($error));
                    if (isset($error['error']['status']) && in_array($error['error']['status'], ['NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'])) {
                        UserDevice::where('fcm_token', $token)->delete();
                    }
                }
            } catch (\Exception $e) {
                Log::error('FCM Send exception: ' . $e->getMessage());
            }
        } else {
            try {
                $responses = Http::pool(function ($pool) use ($uniqueTokens, $accessToken, $url, $title, $body, $stringData) {
                    return array_map(function ($token) use ($pool, $accessToken, $url, $title, $body, $stringData) {
                        $payload = [
                            'message' => [
                                'token' => $token,
                                'notification' => [
                                    'title' => $title,
                                    'body' => $body,
                                ],
                                'data' => $stringData,
                                'android' => [
                                    'priority' => 'HIGH',
                                    'notification' => [
                                        'sound' => 'default',
                                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                                        'channel_id' => 'zenvi_channel_high_importance',
                                        'icon' => 'ic_launcher',
                                        'color' => '#00796B',
                                    ],
                                ],
                            ],
                        ];

                        return $pool->withToken($accessToken)
                            ->timeout(5)
                            ->withHeaders(['Content-Type' => 'application/json; UTF-8'])
                            ->post($url, $payload);
                    }, $uniqueTokens);
                });

                foreach ($responses as $index => $res) {
                    if ($res instanceof \Illuminate\Http\Client\Response && $res->failed()) {
                        $error = $res->json();
                        $token = $uniqueTokens[$index] ?? null;
                        if ($token && isset($error['error']['status']) && in_array($error['error']['status'], ['NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'])) {
                            UserDevice::where('fcm_token', $token)->delete();
                        }
                    }
                }
            } catch (\Exception $e) {
                Log::error('FCM Pool Send exception: ' . $e->getMessage());
            }
        }
    }

    /**
     * Send notification to a specific user
     */
    public static function sendToUser(User|int $user, string $title, string $body, string $type = 'general', array $data = []): void
    {
        $userId = is_numeric($user) ? $user : $user->id;
        $userModel = is_numeric($user) ? User::find($user) : $user;

        if (!$userModel) return;

        // 1. Record in-app notification
        InAppNotification::create([
            'company_id' => $userModel->company_id,
            'user_id' => $userId,
            'target_role' => $userModel->role,
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'data_payload' => $data,
            'is_read' => false,
        ]);

        // 2. Fetch user's active device tokens
        $tokens = UserDevice::where('user_id', $userId)->pluck('fcm_token')->toArray();

        // 3. Send Push Notification
        self::sendFcmToTokens($tokens, $title, $body, array_merge($data, ['type' => $type]));
    }

    /**
     * Send notification to Owner(s) of a company
     */
    public static function sendToOwner(int $companyId, string $title, string $body, string $type = 'general', array $data = []): void
    {
        $owners = User::where('company_id', $companyId)
            ->where(function ($q) {
                $q->where('role', 'Owner')->orWhere('role', 'Admin');
            })
            ->get();

        if ($owners->isEmpty()) return;

        // 1. Record in-app notification
        foreach ($owners as $owner) {
            InAppNotification::create([
                'company_id' => $companyId,
                'user_id' => $owner->id,
                'target_role' => 'Owner',
                'title' => $title,
                'body' => $body,
                'type' => $type,
                'data_payload' => $data,
                'is_read' => false,
            ]);
        }

        // 2. Get tokens
        $tokens = UserDevice::whereIn('user_id', $owners->pluck('id'))->pluck('fcm_token')->toArray();

        // 3. Send FCM
        self::sendFcmToTokens($tokens, $title, $body, array_merge($data, ['type' => $type]));
    }

    /**
     * Send notification to all active Employees of a company
     */
    public static function sendToEmployees(int $companyId, string $title, string $body, string $type = 'general', array $data = [], ?int $excludeUserId = null): void
    {
        $query = User::where('company_id', $companyId)
            ->where('role', '!=', 'Owner')
            ->where('is_approved', true);

        if ($excludeUserId) {
            $query->where('id', '!=', $excludeUserId);
        }

        $employees = $query->get();
        if ($employees->isEmpty()) return;

        // 1. Record in-app notification
        foreach ($employees as $emp) {
            InAppNotification::create([
                'company_id' => $companyId,
                'user_id' => $emp->id,
                'target_role' => 'Employee',
                'title' => $title,
                'body' => $body,
                'type' => $type,
                'data_payload' => $data,
                'is_read' => false,
            ]);
        }

        // 2. Get tokens
        $tokens = UserDevice::whereIn('user_id', $employees->pluck('id'))->pluck('fcm_token')->toArray();

        // 3. Send FCM
        self::sendFcmToTokens($tokens, $title, $body, array_merge($data, ['type' => $type]));
    }

    /**
     * Send notification to everyone in company (Owner + Employees)
     */
    public static function sendToCompany(int $companyId, string $title, string $body, string $type = 'general', array $data = [], ?int $excludeUserId = null): void
    {
        $query = User::where('company_id', $companyId)->where('is_approved', true);
        if ($excludeUserId) {
            $query->where('id', '!=', $excludeUserId);
        }

        $users = $query->get();
        if ($users->isEmpty()) return;

        // 1. Record in-app notification
        foreach ($users as $user) {
            InAppNotification::create([
                'company_id' => $companyId,
                'user_id' => $user->id,
                'target_role' => $user->role,
                'title' => $title,
                'body' => $body,
                'type' => $type,
                'data_payload' => $data,
                'is_read' => false,
            ]);
        }

        // 2. Get tokens
        $tokens = UserDevice::whereIn('user_id', $users->pluck('id'))->pluck('fcm_token')->toArray();

        // 3. Send FCM
        self::sendFcmToTokens($tokens, $title, $body, array_merge($data, ['type' => $type]));
    }
}
