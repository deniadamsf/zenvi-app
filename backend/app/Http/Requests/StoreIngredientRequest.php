<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreIngredientRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        if (!$user || !$user->company_id) {
            return false;
        }
        return $user->role === 'Owner' || $user->hasPermission('can_access_stock');
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'unit' => 'required|string|max:50',
            'stock_qty' => 'required|numeric|min:0',
            'tolerance_percent' => 'nullable|numeric|min:0|max:100',
            'price' => 'nullable|numeric|min:0',
            'branch_id' => 'nullable|exists:branches,id',
        ];
    }
}
