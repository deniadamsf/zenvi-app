<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IngredientHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'branch_id',
        'ingredient_id',
        'user_id',
        'type',
        'qty_change',
        'notes',
    ];

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }
}
