<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\BranchIngredient;
use App\Models\Ingredient;
use App\Models\IngredientHistory;
use App\Models\Expense;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockManagementController extends Controller
{
    private function checkStockAccess(Request $request)
    {
        $user = $request->user();
        if ($user->role === 'Owner') {
            return;
        }

        if (!$user->hasPermission('can_access_stock')) {
            abort(403, 'Anda tidak memiliki hak akses untuk mengelola stok bahan.');
        }
    }

    private function getTargetBranchId(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner' && $user->branch_id) {
            return $user->branch_id;
        }
        if ($request->filled('branch_id') && $request->branch_id !== 'all' && $request->branch_id !== '0') {
            return (int) $request->branch_id;
        }
        return null;
    }

    public function restock(Request $request)
    {
        $this->checkStockAccess($request);

        $request->validate([
            'ingredient_id' => 'required|exists:ingredients,id',
            'branch_id' => 'nullable|exists:branches,id',
            'qty' => 'required|numeric|min:0.01',
            'total_price' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();
        $companyId = $user->company_id;
        $branchId = $this->getTargetBranchId($request);

        DB::beginTransaction();
        try {
            $ingredient = Ingredient::where('company_id', $companyId)->findOrFail($request->ingredient_id);

            $unitCost = ($request->qty > 0) ? ($request->total_price / $request->qty) : 0;
            if ($unitCost > 0) {
                $ingredient->cost_per_unit = $unitCost;
            }

            if ($branchId) {
                $branchStock = BranchIngredient::firstOrCreate(
                    ['branch_id' => $branchId, 'ingredient_id' => $ingredient->id],
                    ['stock_qty' => $ingredient->stock_qty ?? 0, 'min_stock' => $ingredient->min_stock ?? 5]
                );
                $branchStock->increment('stock_qty', $request->qty);
                $ingredient->stock_qty = $branchStock->fresh()->stock_qty;
            } else {
                $ingredient->increment('stock_qty', $request->qty);
            }
            $ingredient->save();

            $branch = $branchId ? Branch::find($branchId) : null;
            $branchSuffix = $branch ? " ({$branch->name})" : '';

            IngredientHistory::create([
                'company_id' => $companyId,
                'branch_id' => $branchId,
                'ingredient_id' => $ingredient->id,
                'user_id' => $user->id,
                'type' => 'restock',
                'qty_change' => $request->qty,
                'notes' => ($request->notes ?? 'Restock via Admin Stock') . $branchSuffix,
            ]);

            Expense::create([
                'company_id' => $companyId,
                'user_id' => $user->id,
                'expense_type' => 'ingredient_restock',
                'amount' => $request->total_price,
                'description' => 'Pembelian bahan baku: ' . $ingredient->name . ' (' . $request->qty . ' ' . $ingredient->unit . ')' . $branchSuffix,
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Restock berhasil.',
                'data' => $ingredient->fresh()
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal melakukan restock.', 'error' => $e->getMessage()], 500);
        }
    }

    public function wastage(Request $request)
    {
        $this->checkStockAccess($request);

        $request->validate([
            'ingredient_id' => 'required|exists:ingredients,id',
            'branch_id' => 'nullable|exists:branches,id',
            'qty' => 'required|numeric|min:0.01',
            'notes' => 'required|string',
        ]);

        $user = $request->user();
        $companyId = $user->company_id;
        $branchId = $this->getTargetBranchId($request);

        DB::beginTransaction();
        try {
            $ingredient = Ingredient::where('company_id', $companyId)->findOrFail($request->ingredient_id);
            $currentStock = $branchId ? $ingredient->getStockForBranch($branchId) : $ingredient->stock_qty;

            if ($currentStock < $request->qty) {
                return response()->json(['message' => 'Stok tidak mencukupi untuk wastage.'], 400);
            }

            if ($branchId) {
                $branchStock = BranchIngredient::firstOrCreate(
                    ['branch_id' => $branchId, 'ingredient_id' => $ingredient->id],
                    ['stock_qty' => $ingredient->stock_qty ?? 0, 'min_stock' => $ingredient->min_stock ?? 5]
                );
                $branchStock->decrement('stock_qty', $request->qty);
                $freshStock = $branchStock->fresh()->stock_qty;
                $minStock = $branchStock->min_stock ?? 5;
            } else {
                $ingredient->decrement('stock_qty', $request->qty);
                $freshStock = $ingredient->fresh()->stock_qty;
                $minStock = $ingredient->min_stock ?? 5;
            }

            $branch = $branchId ? Branch::find($branchId) : null;
            $branchSuffix = $branch ? " ({$branch->name})" : '';

            IngredientHistory::create([
                'company_id' => $companyId,
                'branch_id' => $branchId,
                'ingredient_id' => $ingredient->id,
                'user_id' => $user->id,
                'type' => 'wastage',
                'qty_change' => -$request->qty,
                'notes' => $request->notes . $branchSuffix,
            ]);

            DB::commit();

            if ($freshStock <= $minStock) {
                try {
                    $branchLabel = $branch ? " di Cabang {$branch->name}" : '';
                    FirebaseNotificationService::sendToCompany(
                        $companyId,
                        'Peringatan Stok Rendah!',
                        "Bahan '{$ingredient->name}'{$branchLabel} tersisa {$freshStock} {$ingredient->unit} setelah pencatatan wastage. Segera lakukan restock!",
                        'stock',
                        ['ingredient_id' => $ingredient->id, 'type' => 'low_stock', 'route' => '/stock']
                    );
                } catch (\Exception $e) {
                    \Log::warning('Low stock notification failed: ' . $e->getMessage());
                }
            }

            $fresh = $ingredient->fresh();
            $fresh->stock_qty = $freshStock;

            return response()->json([
                'message' => 'Wastage berhasil dicatat.',
                'data' => $fresh
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal mencatat wastage.', 'error' => $e->getMessage()], 500);
        }
    }

    public function opname(Request $request)
    {
        $this->checkStockAccess($request);

        $request->validate([
            'ingredient_id' => 'required|exists:ingredients,id',
            'branch_id' => 'nullable|exists:branches,id',
            'actual_qty' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();
        $companyId = $user->company_id;
        $branchId = $this->getTargetBranchId($request);

        DB::beginTransaction();
        try {
            $ingredient = Ingredient::where('company_id', $companyId)->findOrFail($request->ingredient_id);
            $systemQty = $branchId ? $ingredient->getStockForBranch($branchId) : $ingredient->stock_qty;
            $actualQty = (float) $request->actual_qty;
            $diff = $actualQty - $systemQty;

            if ($diff == 0) {
                return response()->json(['message' => 'Stok fisik sama dengan sistem. Tidak ada penyesuaian.']);
            }

            $tolerance = $ingredient->tolerance_percent ?? 0;
            $isWithinTolerance = false;
            
            if ($systemQty > 0) {
                $diffPercent = abs($diff) / $systemQty * 100;
                if ($diffPercent <= $tolerance) {
                    $isWithinTolerance = true;
                }
            } else {
                if ($diff > 0) {
                     $isWithinTolerance = true;
                }
            }
            
            $branch = $branchId ? Branch::find($branchId) : null;
            $branchSuffix = $branch ? " ({$branch->name})" : '';
            $notePrefix = $isWithinTolerance ? '[Auto-Adjustment - Toleransi] ' : '[Penyesuaian Manual] ';
            $finalNotes = $notePrefix . ($request->notes ?? 'Selisih opname') . $branchSuffix;

            if ($branchId) {
                $branchStock = BranchIngredient::firstOrCreate(
                    ['branch_id' => $branchId, 'ingredient_id' => $ingredient->id],
                    ['stock_qty' => $actualQty, 'min_stock' => $ingredient->min_stock ?? 5]
                );
                $branchStock->update(['stock_qty' => $actualQty]);
                $minStock = $branchStock->min_stock ?? 5;
            } else {
                $ingredient->update(['stock_qty' => $actualQty]);
                $minStock = $ingredient->min_stock ?? 5;
            }

            IngredientHistory::create([
                'company_id' => $companyId,
                'branch_id' => $branchId,
                'ingredient_id' => $ingredient->id,
                'user_id' => $user->id,
                'type' => 'opname',
                'qty_change' => $diff,
                'notes' => $finalNotes,
            ]);

            DB::commit();

            if ($actualQty <= $minStock) {
                try {
                    $branchLabel = $branch ? " di Cabang {$branch->name}" : '';
                    FirebaseNotificationService::sendToCompany(
                        $companyId,
                        'Peringatan Stok Rendah!',
                        "Bahan '{$ingredient->name}'{$branchLabel} tersisa {$actualQty} {$ingredient->unit} setelah stock opname. Segera lakukan restock!",
                        'stock',
                        ['ingredient_id' => $ingredient->id, 'type' => 'low_stock', 'route' => '/stock']
                    );
                } catch (\Exception $e) {
                    \Log::warning('Low stock notification failed: ' . $e->getMessage());
                }
            }

            $fresh = $ingredient->fresh();
            $fresh->stock_qty = $actualQty;

            return response()->json([
                'message' => 'Stock opname berhasil dicatat.',
                'data' => $fresh
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal melakukan stock opname.', 'error' => $e->getMessage()], 500);
        }
    }

    public function history(Request $request)
    {
        $this->checkStockAccess($request);

        $user = $request->user();
        $query = IngredientHistory::where('company_id', $user->company_id)
            ->with(['user:id,name', 'ingredient:id,name,unit', 'branch:id,name']);

        if ($user->role !== 'Owner' && $user->branch_id) {
            $query->where('branch_id', $user->branch_id);
        } elseif ($request->filled('branch_id') && $request->branch_id !== 'all' && $request->branch_id !== '0') {
            $query->where('branch_id', $request->branch_id);
        }

        $histories = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'message' => 'Stock histories retrieved',
            'data' => $histories
        ]);
    }
}
