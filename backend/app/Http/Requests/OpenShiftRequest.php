<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class OpenShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->company_id !== null;
    }

    public function rules(): array
    {
        return [
            'opening_balance' => 'required|numeric|min:0',
        ];
    }
}
