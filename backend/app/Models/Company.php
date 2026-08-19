<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Company extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'default_language',
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
        'late_tolerance_minutes',
        'shift_schedules',
    ];

    protected $casts = [
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
