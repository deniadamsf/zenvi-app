<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InAppNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'user_id',
        'target_role',
        'title',
        'body',
        'type',
        'data_payload',
        'is_read',
        'read_at',
    ];

    protected $casts = [
        'data_payload' => 'array',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
    ];

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
