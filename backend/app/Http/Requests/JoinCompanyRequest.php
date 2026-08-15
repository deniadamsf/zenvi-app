<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class JoinCompanyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'company_id' => 'required|integer|exists:companies,id',
            'branch_id' => 'required|integer|exists:branches,id',
        ];
    }

    public function messages(): array
    {
        return [
            'company_id.exists' => 'Perusahaan tidak ditemukan.',
            'branch_id.exists' => 'Cabang tidak ditemukan.',
        ];
    }
}
