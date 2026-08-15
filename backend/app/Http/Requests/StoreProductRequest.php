<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->company_id !== null;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'category' => 'nullable|string|max:100',
            'price' => 'required|numeric|min:0',
            'is_active' => 'boolean',
            'ingredients' => 'nullable|array',
            'ingredients.*.ingredient_id' => 'required|exists:ingredients,id',
            'ingredients.*.amount_needed' => 'required|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'discount_nominal' => 'nullable|numeric|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
        ];
    }
}
