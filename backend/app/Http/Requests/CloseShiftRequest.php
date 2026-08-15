<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CloseShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->company_id !== null;
    }

    public function rules(): array
    {
        return [
            'shift_id' => 'required|exists:shifts,id',
            'closing_balance' => 'required|numeric|min:0',
        ];
    }
}
