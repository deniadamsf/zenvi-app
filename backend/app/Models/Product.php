<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'name',
        'category',
        'price',
        'cost_price',
        'is_active',
        'image_path',
        'discount_nominal',
        'discount_percent',
    ];

    protected $appends = ['image_url'];

    protected $casts = [
        'is_active' => 'boolean',
        'cost_price' => 'decimal:2',
    ];

    public function calculateCogs()
    {
        if ($this->relationLoaded('ingredients') && $this->ingredients->isNotEmpty()) {
            $totalCogs = 0.0;
            foreach ($this->ingredients as $ingredient) {
                $amount = (float) ($ingredient->pivot->amount_needed ?? 0);
                $costPerUnit = (float) ($ingredient->cost_per_unit ?? 0);
                $totalCogs += ($amount * $costPerUnit);
            }
            if ($totalCogs > 0) {
                return $totalCogs;
            }
        }

        return (float) ($this->cost_price ?? 0);
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function ingredients()
    {
        return $this->belongsToMany(Ingredient::class, 'product_ingredients')
                    ->withPivot('amount_needed')
                    ->withTimestamps();
    }

    public function getImageUrlAttribute()
    {
        if ($this->image_path) {
            // Check if it's the old format (products/...)
            if (str_starts_with($this->image_path, 'products/')) {
                return url('storage/' . $this->image_path);
            }
            return url($this->image_path);
        }
        return null;
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function memberPromos()
    {
        return $this->belongsToMany(MemberPromo::class, 'member_promo_products')
                    ->withTimestamps();
    }
}
