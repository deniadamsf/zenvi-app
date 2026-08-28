<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncOrdersRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->company_id !== null;
    }

    public function rules(): array
    {
        return [
            'orders' => 'required|array',
            'orders.*.client_order_id' => 'nullable|string|max:64',
            'orders.*.shift_id' => 'required|exists:shifts,id',
            'orders.*.serviced_by_user_id' => 'nullable|exists:users,id',
            'orders.*.member_id' => 'nullable|exists:members,id',
            'orders.*.member_name' => 'nullable|string|max:255',
            'orders.*.member_phone' => 'nullable|string|max:50',
            'orders.*.member_discount_amount' => 'nullable|numeric|min:0',
            'orders.*.points_redeemed' => 'nullable|integer|min:0',
            'orders.*.point_redeem_amount' => 'nullable|numeric|min:0',
            'orders.*.total_amount' => 'required|numeric|min:0',
            'orders.*.payment_method' => 'nullable|string|in:cash,qris,transfer',
            'orders.*.cash_received' => 'nullable|numeric|min:0',
            'orders.*.cash_change' => 'nullable|numeric|min:0',
            'orders.*.items' => 'required|array|min:1',
            'orders.*.items.*.product_id' => 'required|exists:products,id',
            'orders.*.items.*.qty' => 'required|integer|min:1',
            'orders.*.items.*.subtotal' => 'required|numeric|min:0',
        ];
    }
}
