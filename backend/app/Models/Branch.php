<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Branch extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'name',
        'latitude',
        'longitude',
        'radius_meters',
    ];

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class);
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    public function branchIngredients()
    {
        return $this->hasMany(BranchIngredient::class);
    }

    public function ingredientHistories()
    {
        return $this->hasMany(IngredientHistory::class);
    }
}
