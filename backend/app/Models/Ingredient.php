<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ingredient extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'name',
        'unit',
        'stock_qty',
        'cost_per_unit',
        'min_stock',
        'tolerance_percent',
    ];

    protected $casts = [
        'stock_qty' => 'decimal:2',
        'cost_per_unit' => 'decimal:2',
        'min_stock' => 'decimal:2',
        'tolerance_percent' => 'decimal:2',
    ];

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function branchStocks()
    {
        return $this->hasMany(BranchIngredient::class);
    }

    public function getStockForBranch($branchId)
    {
        if (!$branchId) {
            return $this->stock_qty;
        }

        $branchStock = $this->branchStocks()->where('branch_id', $branchId)->first();
        return $branchStock ? $branchStock->stock_qty : $this->stock_qty;
    }
}
