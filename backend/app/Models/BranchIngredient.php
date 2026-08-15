<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BranchIngredient extends Model
{
    use HasFactory;

    protected $fillable = [
        'branch_id',
        'ingredient_id',
        'stock_qty',
        'min_stock',
    ];

    protected $casts = [
        'stock_qty' => 'double',
        'min_stock' => 'double',
    ];

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }
}
