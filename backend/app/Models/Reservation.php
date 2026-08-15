<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'branch_id',
        'customer_name',
        'customer_phone',
        'reservation_date',
        'reservation_time',
        'number_of_people',
        'service_names',
        'notes',
        'status',
        'created_by_user_id',
    ];

    protected $casts = [
        'reservation_date' => 'date:Y-m-d',
        'number_of_people' => 'integer',
    ];

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
