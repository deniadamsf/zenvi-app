<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'sender_id',
        'receiver_id',
        'message',
    ];

    protected $with = ['sender'];

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }
}
