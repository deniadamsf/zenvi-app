<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MemberPromo;
use Illuminate\Http\Request;

class MemberPromoController extends Controller
{
    /**
     * Display a listing of member promos with associated products
     */
    public function index(Request $request)
    {
        $companyId = $request->user()->company_id;
        $query = MemberPromo::with(['products'])->where('company_id', $companyId);

        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        $promos = $query->latest()->get();

        return response()->json([
            'data' => $promos
        ]);
    }

    /**
     * Store a newly created member promo with specific products
     */
    public function store(Request $request)
    {
        $companyId = $request->user()->company_id;

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'discount_type' => 'required|in:percent,nominal,fixed_price',
            'discount_value' => 'required|numeric|min:0',
            'min_purchase' => 'nullable|numeric|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_active' => 'nullable|boolean',
            'product_ids' => 'nullable|array',
            'product_ids.*' => 'exists:products,id',
        ]);

        $promoData = $validated;
        unset($promoData['product_ids']);
        $promoData['company_id'] = $companyId;

        $promo = MemberPromo::create($promoData);

        if (!empty($validated['product_ids'])) {
            $promo->products()->sync($validated['product_ids']);
        }

        $promo->load('products');

        return response()->json([
            'message' => 'Promo khusus member berhasil dibuat.',
            'data' => $promo
        ], 201);
    }

    /**
     * Display the specified member promo
     */
    public function show($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $promo = MemberPromo::with('products')->where('company_id', $companyId)->findOrFail($id);

        return response()->json([
            'data' => $promo
        ]);
    }

    /**
     * Update the specified member promo
     */
    public function update($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $promo = MemberPromo::where('company_id', $companyId)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'discount_type' => 'sometimes|required|in:percent,nominal,fixed_price',
            'discount_value' => 'sometimes|required|numeric|min:0',
            'min_purchase' => 'nullable|numeric|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_active' => 'nullable|boolean',
            'product_ids' => 'nullable|array',
            'product_ids.*' => 'exists:products,id',
        ]);

        $promoData = $validated;
        if (isset($promoData['product_ids'])) {
            $productIds = $promoData['product_ids'];
            unset($promoData['product_ids']);
            $promo->products()->sync($productIds);
        }

        $promo->update($promoData);
        $promo->load('products');

        return response()->json([
            'message' => 'Promo khusus member berhasil diperbarui.',
            'data' => $promo
        ]);
    }

    /**
     * Remove the specified member promo
     */
    public function destroy($id, Request $request)
    {
        $companyId = $request->user()->company_id;
        $promo = MemberPromo::where('company_id', $companyId)->findOrFail($id);

        $promo->delete();

        return response()->json([
            'message' => 'Promo khusus member berhasil dihapus.'
        ]);
    }
}
