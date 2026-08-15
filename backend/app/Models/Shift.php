<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'user_id',
        'branch_id',
        'opening_balance',
        'closing_balance',
        'start_time',
        'end_time',
        'selfie_path',
        'status',
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
    ];

    protected $appends = [
        'selfie_url',
    ];

    public function getSelfieUrlAttribute()
    {
        if ($this->selfie_path) {
            if (str_starts_with($this->selfie_path, 'uploads/')) {
                return url($this->selfie_path);
            }
            return url('storage/' . $this->selfie_path);
        }
        return null;
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }
}
