<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'client_order_id',
        'user_id',
        'serviced_by_user_id',
        'member_id',
        'member_name',
        'member_phone',
        'shift_id',
        'total_amount',
        'price_mismatch',
        'price_mismatch_note',
        'payment_method',
        'cash_received',
        'cash_change',
        'member_discount_amount',
        'points_redeemed',
        'point_redeem_amount',
        'status',
        'kds_status',
    ];

    protected $casts = [
        'total_amount' => 'double',
        'price_mismatch' => 'boolean',
        'cash_received' => 'double',
        'cash_change' => 'double',
        'member_discount_amount' => 'double',
        'points_redeemed' => 'integer',
        'point_redeem_amount' => 'double',
    ];

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function member()
    {
        return $this->belongsTo(Member::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function servicedBy()
    {
        return $this->belongsTo(User::class, 'serviced_by_user_id');
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
