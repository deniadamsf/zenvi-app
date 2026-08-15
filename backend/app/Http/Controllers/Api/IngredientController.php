<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIngredientRequest;
use App\Models\Branch;
use App\Models\BranchIngredient;
use App\Models\Ingredient;
use App\Models\Expense;
use App\Models\IngredientHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class IngredientController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $companyId = $user->company_id;
        $branchId = null;

        if ($user->role !== 'Owner' && $user->branch_id) {
            $branchId = $user->branch_id;
        } elseif ($request->filled('branch_id') && $request->branch_id !== 'all' && $request->branch_id !== '0') {
            $branchId = (int) $request->branch_id;
        }

        $ingredients = Ingredient::where('company_id', $companyId)->get();

        if ($branchId) {
            $branch = Branch::where('company_id', $companyId)->find($branchId);
            $branchName = $branch ? $branch->name : null;

            foreach ($ingredients as $ing) {
                // Get or create branch ingredient stock
                $branchStock = BranchIngredient::firstOrCreate(
                    [
                        'branch_id' => $branchId,
                        'ingredient_id' => $ing->id,
                    ],
                    [
                        'stock_qty' => $ing->stock_qty ?? 0,
                        'min_stock' => $ing->min_stock ?? 5,
                    ]
                );

                $ing->stock_qty = (float) $branchStock->stock_qty;
                $ing->min_stock = (float) $branchStock->min_stock;
                $ing->branch_id = $branchId;
                $ing->branch_name = $branchName;
            }
        } else {
            // For overall view (Owner "All Branches" or company without branches)
            $branchesCount = Branch::where('company_id', $companyId)->count();
            if ($branchesCount > 0) {
                foreach ($ingredients as $ing) {
                    $totalBranchStock = BranchIngredient::where('ingredient_id', $ing->id)->sum('stock_qty');
                    // If no branch_ingredients exist yet, fallback to master stock_qty
                    $hasAnyBranchStock = BranchIngredient::where('ingredient_id', $ing->id)->exists();
                    $ing->stock_qty = $hasAnyBranchStock ? (float) $totalBranchStock : (float) $ing->stock_qty;
                    $ing->branch_id = null;
                    $ing->branch_name = 'Semua Cabang';
                }
            }
        }

        return response()->json(['data' => $ingredients]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreIngredientRequest $request)
    {
        DB::beginTransaction();
            $costPerUnit = ($request->filled('cost_per_unit'))
                ? (float) $request->cost_per_unit
                : (($request->filled('price') && $request->stock_qty > 0) ? ((float) $request->price / (float) $request->stock_qty) : 0.0);

            $ingredient = Ingredient::create([
                'company_id' => $companyId,
                'name' => $request->name,
                'unit' => $request->unit,
                'stock_qty' => $request->stock_qty,
                'cost_per_unit' => $costPerUnit,
                'tolerance_percent' => $request->tolerance_percent ?? 0,
            ]);

            // Sync to all branches or specific branch
            $branches = Branch::where('company_id', $companyId)->get();
            $targetBranchId = $request->branch_id ?: ($user->branch_id ?: null);

            if ($branches->isNotEmpty()) {
                foreach ($branches as $branch) {
                    $initialQty = ($targetBranchId && $targetBranchId == $branch->id) ? $request->stock_qty : ($targetBranchId ? 0 : $request->stock_qty);
                    BranchIngredient::create([
                        'branch_id' => $branch->id,
                        'ingredient_id' => $ingredient->id,
                        'stock_qty' => $initialQty,
                        'min_stock' => 5,
                    ]);
                }
            }

            if ($request->stock_qty > 0) {
                IngredientHistory::create([
                    'company_id' => $companyId,
                    'branch_id' => $targetBranchId,
                    'ingredient_id' => $ingredient->id,
                    'user_id' => $user->id,
                    'type' => 'restock',
                    'qty_change' => $request->stock_qty,
                    'notes' => 'Stok Awal' . ($targetBranchId ? ' (Cabang)' : ''),
                ]);
            }

            if ($request->filled('price') && $request->price > 0 && $request->stock_qty > 0) {
                Expense::create([
                    'company_id' => $companyId,
                    'user_id' => $user->id,
                    'expense_type' => 'Restock Bahan Baku',
                    'amount' => $request->price,
                    'description' => 'Pembelian Awal: ' . $ingredient->name,
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Bahan baku berhasil ditambahkan.',
                'data' => $ingredient
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal menambahkan bahan baku', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(StoreIngredientRequest $request, $id)
    {
        $ingredient = Ingredient::where('company_id', $request->user()->company_id)->findOrFail($id);
        
        $ingredient->update($request->validated());

        return response()->json([
            'message' => 'Bahan baku berhasil diperbarui.',
            'data' => $ingredient
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        if ($user->role !== 'Owner' && !$user->hasPermission('can_access_stock')) {
            abort(403, 'Anda tidak memiliki hak akses untuk menghapus bahan baku.');
        }

        $ingredient = Ingredient::where('company_id', $user->company_id)->findOrFail($id);
        $ingredient->delete();

        return response()->json([
            'message' => 'Bahan baku berhasil dihapus.'
        ]);
    }
}
