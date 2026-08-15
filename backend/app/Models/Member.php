<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Member extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'member_code',
        'name',
        'phone',
        'email',
        'address',
        'birth_date',
        'points',
        'total_spend',
        'total_transactions',
        'custom_discount_percent',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'points' => 'integer',
        'total_spend' => 'double',
        'total_transactions' => 'integer',
        'custom_discount_percent' => 'double',
        'is_active' => 'boolean',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($member) {
            if (empty($member->member_code)) {
                // Auto generate unique member code per company e.g. MB-0001
                $count = static::where('company_id', $member->company_id)->count();
                $code = 'MB-' . str_pad($count + 1, 4, '0', STR_PAD_LEFT);
                while (static::where('company_id', $member->company_id)->where('member_code', $code)->exists()) {
                    $count++;
                    $code = 'MB-' . str_pad($count + 1, 4, '0', STR_PAD_LEFT);
                }
                $member->member_code = $code;
            }
        });
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
