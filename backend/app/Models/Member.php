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

    /**
     * Create a member, retrying on the rare case where two requests for the same
     * company generate the same auto member_code at the same time (the count-based
     * generator in boot() isn't safe against true concurrent inserts - the unique
     * (company_id, member_code) DB constraint is what actually catches it here).
     */
    public static function createUnique(array $attributes): self
    {
        $maxAttempts = 5;

        for ($attempt = 1; $attempt <= $maxAttempts; $attempt++) {
            try {
                return static::create($attributes);
            } catch (\Illuminate\Database\QueryException $e) {
                $isDuplicateMemberCode = ($e->errorInfo[1] ?? null) == 1062
                    && str_contains($e->getMessage(), 'member_code');

                if (!$isDuplicateMemberCode || $attempt === $maxAttempts) {
                    throw $e;
                }
                // Let the next attempt's boot() hook recompute member_code against
                // the now-existing colliding row.
            }
        }

        // Unreachable, but keeps static analysis happy about the return type.
        throw new \RuntimeException('Gagal membuat member setelah beberapa percobaan.');
    }
}
