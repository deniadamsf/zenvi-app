<?php

namespace App\Support;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * Satu-satunya sumber kebenaran soal "paket ini boleh apa".
 *
 * Dipakai oleh middleware, controller, dan serialisasi Company. Jangan pernah
 * membaca `plan_code` mentah dari model untuk mengambil keputusan izin - paket
 * yang sudah kedaluwarsa masih menyimpan kode paket lamanya di kolom itu.
 * Selalu lewat kelas ini, karena `planCode()` sudah memperhitungkan kedaluwarsa
 * dan masa tenggang.
 */
class Entitlements
{
    public function __construct(private ?Company $company)
    {
    }

    public static function for(?Company $company): self
    {
        return new self($company);
    }

    /**
     * Paket yang BERLAKU saat ini, bukan sekadar isi kolom `plan_code`.
     *
     * Toko tanpa perusahaan, paket kedaluwarsa yang sudah lewat masa tenggang,
     * atau kode paket yang tidak dikenal - semuanya jatuh ke 'free'.
     */
    public function planCode(): string
    {
        $company = $this->company;
        if (!$company) {
            return 'free';
        }

        $code = $company->plan_code ?: 'free';
        if ($code === 'free' || !array_key_exists($code, config('plans.plans', []))) {
            return 'free';
        }

        // NULL = tanpa kedaluwarsa (founding member).
        if ($company->plan_expires_at === null) {
            return $code;
        }

        $expiresAt = $company->plan_expires_at instanceof Carbon
            ? $company->plan_expires_at
            : Carbon::parse($company->plan_expires_at);

        if (now()->lessThan($expiresAt->copy()->addDays((int) config('plans.grace_days', 3)))) {
            return $code;
        }

        return 'free';
    }

    public function onGrace(): bool
    {
        $company = $this->company;
        if (!$company || $company->plan_expires_at === null) {
            return false;
        }

        $expiresAt = $company->plan_expires_at instanceof Carbon
            ? $company->plan_expires_at
            : Carbon::parse($company->plan_expires_at);

        return now()->greaterThanOrEqualTo($expiresAt)
            && $this->planCode() !== 'free';
    }

    public function isPremium(): bool
    {
        return $this->planCode() !== 'free';
    }

    public function hasFeature(string $feature): bool
    {
        $plan = config('plans.plans.' . $this->planCode(), []);

        return in_array($feature, $plan['features'] ?? [], true);
    }

    /**
     * Batas untuk paket berlaku. `null` berarti tak terbatas.
     */
    public function limit(string $key): ?int
    {
        $limits = config('plans.plans.' . $this->planCode() . '.limits', []);
        $value = $limits[$key] ?? null;

        return $value === null ? null : (int) $value;
    }

    /**
     * Pemakaian saat ini untuk sebuah batas. Sengaja query terpisah dan hanya
     * dipanggil saat batas benar-benar perlu dicek (saat membuat data baru),
     * bukan di setiap request.
     */
    public function usage(string $key): int
    {
        $company = $this->company;
        if (!$company) {
            return 0;
        }

        return match ($key) {
            'products'  => Product::where('company_id', $company->id)->count(),
            'branches'  => Branch::where('company_id', $company->id)->count(),
            // Owner tidak menghabiskan kuota; yang menunggu persetujuan juga belum.
            'employees' => User::where('company_id', $company->id)
                ->where('is_approved', true)
                ->where('role', '!=', 'Owner')
                ->count(),
            default     => 0,
        };
    }

    /**
     * Apakah masih boleh menambah satu data lagi untuk batas ini.
     */
    public function canAdd(string $key): bool
    {
        $max = $this->limit($key);

        return $max === null || $this->usage($key) < $max;
    }

    /**
     * Batas rentang riwayat yang boleh dilihat, dalam hari. `null` = penuh.
     */
    public function historyDays(): ?int
    {
        return $this->limit('history_days');
    }

    /**
     * Paket TERMURAH yang membuka sebuah fitur, dikirim ke aplikasi sebagai
     * `required_plan` supaya layar upsell tahu harus menawarkan paket yang mana.
     */
    public static function planRequiredFor(string $feature): ?string
    {
        $plans = config('plans.plans', []);
        uasort($plans, fn ($a, $b) => ($a['rank'] ?? 0) <=> ($b['rank'] ?? 0));

        foreach ($plans as $code => $plan) {
            if (in_array($feature, $plan['features'] ?? [], true)) {
                return $code;
            }
        }

        return null;
    }

    /**
     * Paket termurah yang batasnya lebih longgar dari paket sekarang.
     */
    public static function planRequiredForLimit(string $key, ?int $currentMax): ?string
    {
        $plans = config('plans.plans', []);
        uasort($plans, fn ($a, $b) => ($a['rank'] ?? 0) <=> ($b['rank'] ?? 0));

        foreach ($plans as $code => $plan) {
            $max = $plan['limits'][$key] ?? null;
            if ($max === null || $currentMax === null || $max > $currentMax) {
                return $code;
            }
        }

        return null;
    }

    /**
     * Ringkasan paket untuk dikirim ke aplikasi. Murni dari config, nol query,
     * jadi aman ditempelkan ke setiap serialisasi Company.
     */
    public function summary(): array
    {
        $code = $this->planCode();
        $plan = config('plans.plans.' . $code, []);
        $company = $this->company;

        return [
            'code'               => $code,
            'name'               => $plan['name'] ?? 'Gratis',
            'status'             => $this->onGrace() ? 'grace' : ($company->plan_status ?? 'active'),
            'expires_at'         => $company?->plan_expires_at,
            'is_founding_member' => (bool) ($company->is_founding_member ?? false),
            'features'           => $plan['features'] ?? [],
            'limits'             => $plan['limits'] ?? [],
        ];
    }
}
