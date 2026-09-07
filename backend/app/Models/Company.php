<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Support\Entitlements;
use Illuminate\Support\Str;

class Company extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'default_language',
        'plan_code',
        'plan_status',
        'plan_expires_at',
        'is_founding_member',
        'code',
        'slug',
        'is_qr_menu_enabled',
        'qr_menu_description',
        'is_reservation_enabled',
        'reservation_description',
        'is_membership_enabled',
        'is_kds_enabled',
        'is_product_image_enabled',
        'default_member_discount_percent',
        'is_points_enabled',
        'point_earning_amount',
        'point_redeem_rate',
        'logo_path',
        'latitude',
        'longitude',
        'radius_meters',
        'require_opname_on_shift_close',
        'require_attendance',
        'require_schedule',
        'require_cash_drawer_balance',
        'is_qris_enabled',
        'is_transfer_enabled',
        'qris_image_path',
        'qris_merchant_name',
        'bank_accounts',
        'late_tolerance_minutes',
        'shift_schedules',
    ];

    protected $casts = [
        'plan_expires_at' => 'datetime',
        'is_founding_member' => 'boolean',
        'is_qr_menu_enabled' => 'boolean',
        'is_reservation_enabled' => 'boolean',
        'is_membership_enabled' => 'boolean',
        'is_kds_enabled' => 'boolean',
        'is_product_image_enabled' => 'boolean',
        'default_member_discount_percent' => 'double',
        'is_points_enabled' => 'boolean',
        'point_earning_amount' => 'double',
        'point_redeem_rate' => 'double',
        'is_qris_enabled' => 'boolean',
        'is_transfer_enabled' => 'boolean',
        'bank_accounts' => 'array',
        'require_cash_drawer_balance' => 'boolean',
        'require_opname_on_shift_close' => 'boolean',
        'require_attendance' => 'boolean',
        'require_schedule' => 'boolean',
        'shift_schedules' => 'array',
    ];

    protected $appends = [
        'qr_menu_url',
        'store_url',
        'logo_url',
        'qris_image_url',
        'plan',
    ];

    protected static function boot()
    {
        parent::boot();
        static::saving(function ($company) {
            if (empty($company->code)) {
                $code = 'ZNV-' . strtoupper(Str::random(4));
                while (static::where('code', $code)->where('id', '!=', $company->id ?? 0)->exists()) {
                    $code = 'ZNV-' . strtoupper(Str::random(4));
                }
                $company->code = $code;
            }

            if (empty($company->slug) && !empty($company->name)) {
                $baseSlug = Str::slug($company->name);
                if (empty($baseSlug)) {
                    $baseSlug = 'toko-' . strtolower(Str::random(5));
                }
                $slug = $baseSlug;
                $count = 1;
                while (static::where('slug', $slug)->where('id', '!=', $company->id ?? 0)->exists()) {
                    $slug = $baseSlug . '-' . $count;
                    $count++;
                }
                $company->slug = $slug;
            }
        });
    }

    /**
     * Ringkasan paket yang ikut terbawa ke aplikasi lewat /auth/me.
     *
     * Murni dibaca dari config/plans.php sehingga tidak menambah satu query pun,
     * dan `plan.code` di sini adalah paket YANG BERLAKU - kedaluwarsa serta masa
     * tenggang sudah diperhitungkan, tidak sama dengan kolom `plan_code` mentah.
     */
    public function getPlanAttribute()
    {
        return Entitlements::for($this)->summary();
    }

    /*
    |--------------------------------------------------------------------------
    | Toggle fitur: nilai EFEKTIF
    |--------------------------------------------------------------------------
    |
    | Toggle yang dinyalakan owner hanya berlaku kalau paketnya juga mengizinkan.
    | Digabung di sini, di sumbernya, supaya APK LAMA yang sudah beredar pun ikut
    | benar: aplikasi itu membaca `is_*_enabled` untuk memutuskan menampilkan menu,
    | jadi kalau server mengirim `true` sementara endpointnya dikunci, pengguna
    | melihat menu yang selalu gagal. Dengan digabung di sini, aplikasi versi apa
    | pun menyembunyikan menu yang memang tidak termasuk paketnya.
    |
    | Ini TIDAK menggantikan middleware. Ini hanya menjaga tampilan tetap jujur;
    | penegakan sesungguhnya tetap di `feature:` pada route.
    */
    private function featureAllowed(string $feature): bool
    {
        return Entitlements::for($this)->hasFeature($feature);
    }

    public function getIsMembershipEnabledAttribute($value)
    {
        return (bool) $value && $this->featureAllowed('membership');
    }

    public function getIsPointsEnabledAttribute($value)
    {
        // Default menyala saat nilainya belum pernah diset (kolom baru).
        return ($value === null || (bool) $value) && $this->featureAllowed('points');
    }

    public function getIsKdsEnabledAttribute($value)
    {
        return (bool) $value && $this->featureAllowed('kds');
    }

    public function getIsReservationEnabledAttribute($value)
    {
        return (bool) $value && $this->featureAllowed('reservation');
    }

    public function getIsQrMenuEnabledAttribute($value)
    {
        return (bool) $value && $this->featureAllowed('qr_menu');
    }

    public function getIsProductImageEnabledAttribute($value)
    {
        return ($value === null || (bool) $value) && $this->featureAllowed('product_image');
    }

    public function getQrMenuUrlAttribute()
    {
        $slug = $this->slug ?: Str::slug($this->name);
        return url('/menu/' . $slug);
    }

    public function getStoreUrlAttribute()
    {
        $slug = $this->slug ?: Str::slug($this->name);
        return url('/' . $slug);
    }

    public function getLogoUrlAttribute()
    {
        if ($this->logo_path) {
            if (str_starts_with($this->logo_path, 'logos/')) {
                return url('storage/' . $this->logo_path);
            }
            return url($this->logo_path);
        }
        return null;
    }

    public function getQrisImageUrlAttribute()
    {
        return $this->qris_image_path ? url($this->qris_image_path) : null;
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function ingredients()
    {
        return $this->hasMany(Ingredient::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function branches()
    {
        return $this->hasMany(Branch::class);
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    public function members()
    {
        return $this->hasMany(Member::class);
    }

    public function memberPromos()
    {
        return $this->hasMany(MemberPromo::class);
    }
}
