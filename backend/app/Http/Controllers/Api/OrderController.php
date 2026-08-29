<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SyncOrdersRequest;
use App\Models\Company;
use App\Models\Ingredient;
use App\Models\Member;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    /**
     * Get order history (with optional filters for owner dashboard)
     */
    public function index(Request $request)
    {
        $query = Order::with(['items.product', 'user', 'servicedBy', 'shift.branch', 'member'])
            ->where('company_id', $request->user()->company_id);

        // Filter by date
        if ($request->has('date')) {
            $query->whereDate('created_at', $request->date);
        }

        // Filter by member_id
        if ($request->has('member_id')) {
            $query->where('member_id', $request->member_id);
        }

        // Filter by user_id or serviced_by_user_id
        if ($request->has('user_id')) {
            $userId = $request->user_id;
            $query->where(function($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('serviced_by_user_id', $userId);
            });
        }

        // Filter by branch_id (via shift)
        if ($request->has('branch_id')) {
            $query->whereHas('shift', function ($q) use ($request) {
                $q->where('branch_id', $request->branch_id);
            });
        }

        $orders = $query->latest()->get();

        return response()->json(['data' => $orders]);
    }

    /**
     * Recompute what an order's total_amount *should* be from server-side product
     * prices, independent of whatever the offline client calculated. Used to flag
     * (not block) orders whose reported total doesn't match reality - e.g. the
     * product price changed while the order sat offline, or the app/client was
     * tampered with.
     *
     * Returns ['expected_total' => float, 'note' => string|null on mismatch].
     */
    private function calculateExpectedTotal(array $orderData): array
    {
        $expectedSubtotal = 0.0;

        foreach ($orderData['items'] as $itemData) {
            $product = Product::find($itemData['product_id']);
            if (!$product) {
                continue;
            }

            $unitPrice = (float) $product->price;

            if (!empty($itemData['variant_name'])) {
                $variant = ProductVariant::where('product_id', $product->id)
                    ->where('name', $itemData['variant_name'])
                    ->first();
                if ($variant) {
                    $unitPrice = (float) $variant->price;
                }
            } else {
                $afterPercent = $unitPrice - ($unitPrice * ((float) ($product->discount_percent ?? 0)) / 100);
                $afterNominal = $afterPercent - (float) ($product->discount_nominal ?? 0);
                $unitPrice = max($afterNominal, 0);
            }

            $expectedSubtotal += $unitPrice * (int) $itemData['qty'];
        }

        $memberDiscount = (float) ($orderData['member_discount_amount'] ?? 0);
        $pointRedeemAmount = (float) ($orderData['point_redeem_amount'] ?? 0);
        $expectedTotal = max($expectedSubtotal - $memberDiscount - $pointRedeemAmount, 0);

        $submittedTotal = (float) $orderData['total_amount'];
        $tolerance = 2.0; // toleransi pembulatan rupiah
        $note = null;

        if (abs($expectedTotal - $submittedTotal) > $tolerance) {
            $note = sprintf(
                'Total dari kasir Rp%s, seharusnya Rp%s (selisih Rp%s) berdasarkan harga produk saat sinkronisasi.',
                number_format($submittedTotal, 0, ',', '.'),
                number_format($expectedTotal, 0, ',', '.'),
                number_format(abs($expectedTotal - $submittedTotal), 0, ',', '.')
            );
        }

        return ['expected_total' => $expectedTotal, 'note' => $note];
    }

    /**
     * Sync bulk orders from offline-first mobile app
     */
    public function sync(SyncOrdersRequest $request)
    {
        DB::beginTransaction();
        try {
            $companyId = $request->user()->company_id;
            $company = Company::find($companyId);
            $isPointsEnabled = $company ? (bool)$company->is_points_enabled : true;
            $pointEarningAmount = $company && $company->point_earning_amount > 0 ? (float)$company->point_earning_amount : 1000.0;

            $userId = $request->user()->id;
            $syncedOrders = [];
            $lowStockIngredients = [];
            $priceMismatchOrders = [];

            foreach ($request->orders as $orderData) {
                // Idempotency guard: skip orders already synced before (e.g. client retried
                // after a response timeout even though the server had already committed it).
                $clientOrderId = $orderData['client_order_id'] ?? null;
                if ($clientOrderId) {
                    $existingOrder = Order::where('company_id', $companyId)
                        ->where('client_order_id', $clientOrderId)
                        ->first();

                    if ($existingOrder) {
                        \Illuminate\Support\Facades\Log::info("Duplicate order sync ignored for client_order_id {$clientOrderId} (order #{$existingOrder->id}).");
                        $syncedOrders[] = $existingOrder->load(['items', 'user', 'shift.branch', 'member']);
                        continue;
                    }
                }

                // Recompute the total server-side from actual product prices. We still
                // accept the order either way (offline POS can't be blocked on this),
                // but flag it for Owner review when it doesn't line up.
                $priceCheck = $this->calculateExpectedTotal($orderData);

                // Create Order
                $order = Order::create([
                    'company_id' => $companyId,
                    'client_order_id' => $clientOrderId,
                    'user_id' => $userId,
                    'serviced_by_user_id' => $orderData['serviced_by_user_id'] ?? null,
                    'member_id' => $orderData['member_id'] ?? null,
                    'member_name' => $orderData['member_name'] ?? null,
                    'member_phone' => $orderData['member_phone'] ?? null,
                    'member_discount_amount' => $orderData['member_discount_amount'] ?? 0,
                    'points_redeemed' => $orderData['points_redeemed'] ?? 0,
                    'point_redeem_amount' => $orderData['point_redeem_amount'] ?? 0,
                    'shift_id' => $orderData['shift_id'],
                    'total_amount' => $orderData['total_amount'],
                    'price_mismatch' => $priceCheck['note'] !== null,
                    'price_mismatch_note' => $priceCheck['note'],
                    'payment_method' => $orderData['payment_method'] ?? 'cash',
                    'cash_received' => $orderData['cash_received'] ?? null,
                    'cash_change' => $orderData['cash_change'] ?? null,
                    'status' => 'synced',
                ]);

                if ($priceCheck['note'] !== null) {
                    \Illuminate\Support\Facades\Log::warning("Price mismatch on order sync: {$priceCheck['note']}");
                    $priceMismatchOrders[] = $order;
                }

                // Update Member statistics and points if member_id is provided
                if (!empty($orderData['member_id'])) {
                    // Lock the member row so two devices syncing an order for the same
                    // member at the same time can't both read a stale points balance and
                    // push it negative (check-then-decrement race).
                    $member = Member::where('company_id', $companyId)
                        ->where('id', $orderData['member_id'])
                        ->lockForUpdate()
                        ->first();
                    if ($member) {
                        $pointsRedeemed = (int) ($orderData['points_redeemed'] ?? 0);
                        if ($pointsRedeemed > 0) {
                            $member->decrement('points', min($member->points, $pointsRedeemed));
                        }

                        $earnedPoints = 0;
                        if ($isPointsEnabled && $pointEarningAmount > 0) {
                            $earnedPoints = (int) floor($orderData['total_amount'] / $pointEarningAmount);
                        }

                        $member->increment('total_spend', $orderData['total_amount']);
                        $member->increment('total_transactions', 1);
                        if ($earnedPoints > 0) {
                            $member->increment('points', $earnedPoints);
                        }
                    }
                }

                foreach ($orderData['items'] as $itemData) {
                    // Create Order Item
                    $order->items()->create([
                        'product_id' => $itemData['product_id'],
                        'variant_name' => $itemData['variant_name'] ?? null,
                        'qty' => $itemData['qty'],
                        'subtotal' => $itemData['subtotal'],
                        'kds_status' => $itemData['kds_status'] ?? 'pending',
                    ]);

                    // BOM Deduction Logic (Antigravity Core with Branch Support)
                    $product = Product::with('ingredients')->find($itemData['product_id']);
                    if ($product) {
                        $shift = \App\Models\Shift::find($orderData['shift_id']);
                        $branchId = $shift ? $shift->branch_id : null;

                        foreach ($product->ingredients as $ingredientInfo) {
                            $amountToDeduct = $ingredientInfo->pivot->amount_needed * $itemData['qty'];
                            // Lock the ingredient row for the whole check-then-decrement below so
                            // concurrent syncs (e.g. two POS devices reconnecting at once) can't
                            // both read the same stock_qty and both pass the "enough stock" check.
                            $ingredientModel = Ingredient::where('id', $ingredientInfo->id)->lockForUpdate()->first();

                            if ($ingredientModel) {
                                if ($branchId) {
                                    $branchStock = \App\Models\BranchIngredient::where('branch_id', $branchId)
                                        ->where('ingredient_id', $ingredientModel->id)
                                        ->lockForUpdate()
                                        ->first();

                                    if (!$branchStock) {
                                        try {
                                            $branchStock = \App\Models\BranchIngredient::create([
                                                'branch_id' => $branchId,
                                                'ingredient_id' => $ingredientModel->id,
                                                'stock_qty' => $ingredientModel->stock_qty ?? 0,
                                                'min_stock' => $ingredientModel->min_stock ?? 5,
                                            ]);
                                        } catch (\Illuminate\Database\QueryException $e) {
                                            // Another concurrent request created it first (unique
                                            // branch_id+ingredient_id constraint) - re-fetch with the lock.
                                            $branchStock = \App\Models\BranchIngredient::where('branch_id', $branchId)
                                                ->where('ingredient_id', $ingredientModel->id)
                                                ->lockForUpdate()
                                                ->first();
                                        }
                                    }

                                    if ($branchStock->stock_qty >= $amountToDeduct) {
                                        $branchStock->decrement('stock_qty', $amountToDeduct);
                                    } else {
                                        $branchStock->update(['stock_qty' => 0]);
                                        \Illuminate\Support\Facades\Log::warning("Insufficient stock for ingredient {$ingredientModel->id} in branch {$branchId} during order sync.");
                                    }

                                    $freshBranchStock = $branchStock->fresh();
                                    $minStock = $freshBranchStock->min_stock ?? 5;
                                    if ($freshBranchStock->stock_qty <= $minStock) {
                                        $branchName = $shift->branch ? $shift->branch->name : 'Cabang';
                                        $lowStockIngredients[$freshBranchStock->id] = [
                                            'name' => $ingredientModel->name,
                                            'stock_qty' => $freshBranchStock->stock_qty,
                                            'unit' => $ingredientModel->unit,
                                            'branch_name' => $branchName,
                                            'id' => $ingredientModel->id,
                                        ];
                                    }
                                } else {
                                    if ($ingredientModel->stock_qty >= $amountToDeduct) {
                                        $ingredientModel->decrement('stock_qty', $amountToDeduct);
                                    } else {
                                        $ingredientModel->update(['stock_qty' => 0]);
                                        \Illuminate\Support\Facades\Log::warning("Insufficient stock for ingredient {$ingredientModel->id} during order sync.");
                                    }

                                    $freshIngredient = $ingredientModel->fresh();
                                    $minStock = $freshIngredient->min_stock ?? 5;
                                    if ($freshIngredient->stock_qty <= $minStock) {
                                        $lowStockIngredients[$freshIngredient->id] = [
                                            'name' => $freshIngredient->name,
                                            'stock_qty' => $freshIngredient->stock_qty,
                                            'unit' => $freshIngredient->unit,
                                            'branch_name' => null,
                                            'id' => $freshIngredient->id,
                                        ];
                                    }
                                }
                            }
                        }
                    }
                }

                $syncedOrders[] = $order->load(['items', 'user', 'shift.branch', 'member']);
            }

            DB::commit();

            // Notifikasi push dikirim SETELAH respons diterima kasir.
            //
            // Sebelumnya setiap bahan yang stoknya menipis memicu satu panggilan
            // HTTPS ke server Google secara berurutan, di dalam request - jadi
            // kasir menunggu N kali bolak-balik ke Google sebelum transaksinya
            // dianggap selesai. app()->terminating() dipakai (bukan queue)
            // karena server belum punya queue worker maupun cron, sehingga job
            // yang diantrekan tidak akan pernah dieksekusi.
            $lowStockToNotify = $lowStockIngredients;
            $mismatchToNotify = $priceMismatchOrders;

            if (!empty($lowStockToNotify) || !empty($mismatchToNotify)) {
                app()->terminating(function () use ($companyId, $lowStockToNotify, $mismatchToNotify) {
                    // Push Notification for Low Stock (to Owner & Employees)
                    foreach ($lowStockToNotify as $ing) {
                        try {
                            $branchSuffix = !empty($ing['branch_name']) ? " di {$ing['branch_name']}" : '';
                            FirebaseNotificationService::sendToCompany(
                                $companyId,
                                'Peringatan Stok Rendah!',
                                "Bahan '{$ing['name']}'{$branchSuffix} tersisa {$ing['stock_qty']} {$ing['unit']}. Segera lakukan restock!",
                                'stock',
                                ['ingredient_id' => $ing['id'], 'type' => 'low_stock', 'route' => '/stock']
                            );
                        } catch (\Throwable $e) {
                            \Log::warning('Low stock notification failed: ' . $e->getMessage());
                        }
                    }

                    // Push Notification for Price Mismatch (to Owner only - needs review, not a stock-out)
                    foreach ($mismatchToNotify as $mismatchedOrder) {
                        try {
                            FirebaseNotificationService::sendToOwner(
                                $companyId,
                                'Order Perlu Ditinjau',
                                "Total order #{$mismatchedOrder->id} tidak sesuai perhitungan harga saat ini. Cek Log Transaksi untuk detail.",
                                'order',
                                ['order_id' => $mismatchedOrder->id, 'type' => 'price_mismatch', 'route' => '/orders']
                            );
                        } catch (\Throwable $e) {
                            \Log::warning('Price mismatch notification failed: ' . $e->getMessage());
                        }
                    }
                });
            }

            return response()->json([
                'message' => 'Sinkronisasi pesanan berhasil.',
                'data' => $syncedOrders
            ], 201);
            
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Gagal melakukan sinkronisasi pesanan.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Void an order and restore stock
     */
    public function voidOrder($id, Request $request)
    {
        if ($request->user()->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $order = Order::with(['items.product', 'shift'])->where('company_id', $request->user()->company_id)->findOrFail($id);

        if ($order->status === 'voided') {
            return response()->json(['message' => 'Pesanan sudah dibatalkan sebelumnya.'], 400);
        }

        DB::beginTransaction();
        try {
            $order->status = 'voided';
            $order->save();

            // Revert member spend & transactions if applicable
            if ($order->member_id) {
                $member = Member::where('company_id', $request->user()->company_id)->find($order->member_id);
                if ($member) {
                    $company = Company::find($request->user()->company_id);
                    $isPointsEnabled = $company ? (bool)$company->is_points_enabled : true;
                    $pointEarningAmount = $company && $company->point_earning_amount > 0 ? (float)$company->point_earning_amount : 1000.0;
                    
                    $earnedPoints = 0;
                    if ($isPointsEnabled && $pointEarningAmount > 0) {
                        $earnedPoints = (int) floor($order->total_amount / $pointEarningAmount);
                    }

                    $member->decrement('total_spend', min($member->total_spend, $order->total_amount));
                    if ($member->total_transactions > 0) {
                        $member->decrement('total_transactions', 1);
                    }
                    if ($earnedPoints > 0 && $member->points >= $earnedPoints) {
                        $member->decrement('points', $earnedPoints);
                    }
                    // Restore redeemed points back to member
                    if (!empty($order->points_redeemed) && $order->points_redeemed > 0) {
                        $member->increment('points', (int) $order->points_redeemed);
                    }
                }
            }

            // Restore Stock (Branch-aware)
            $branchId = $order->shift ? $order->shift->branch_id : null;
            foreach ($order->items as $item) {
                $product = Product::with('ingredients')->find($item->product_id);
                if ($product) {
                    foreach ($product->ingredients as $ingredientInfo) {
                        $amountToRestore = $ingredientInfo->pivot->amount_needed * $item->qty;
                        $ingredientModel = Ingredient::find($ingredientInfo->id);
                        if ($ingredientModel) {
                            if ($branchId) {
                                $branchStock = \App\Models\BranchIngredient::firstOrCreate(
                                    ['branch_id' => $branchId, 'ingredient_id' => $ingredientModel->id],
                                    ['stock_qty' => $ingredientModel->stock_qty ?? 0, 'min_stock' => $ingredientModel->min_stock ?? 5]
                                );
                                $branchStock->increment('stock_qty', $amountToRestore);
                            } else {
                                $ingredientModel->increment('stock_qty', $amountToRestore);
                            }
                        }
                    }
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Pesanan berhasil dibatalkan dan stok telah dikembalikan.',
                'data' => $order->load(['items', 'user', 'shift.branch', 'member'])
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Gagal membatalkan pesanan.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get orders specifically for Kitchen & Service Display System (KDS)
     */
    public function getKdsOrders(Request $request)
    {
        $query = Order::with(['items.product', 'user', 'servicedBy', 'shift.branch'])
            ->where('company_id', $request->user()->company_id)
            ->where('status', 'synced');

        // Filter by branch if user has branch_id or branch_id param provided
        if ($request->user()->branch_id) {
            $branchId = $request->user()->branch_id;
            $query->whereHas('shift', function ($q) use ($branchId) {
                $q->where('branch_id', $branchId);
            });
        } elseif ($request->has('branch_id')) {
            $branchId = $request->branch_id;
            $query->whereHas('shift', function ($q) use ($branchId) {
                $q->where('branch_id', $branchId);
            });
        }

        // Filter by status if specified
        if ($request->has('status') && $request->status !== 'all') {
            $query->where('kds_status', $request->status);
        } else if (!$request->has('status')) {
            $query->whereIn('kds_status', ['pending', 'preparing']);
        }

        $orders = $query->latest()->get();

        return response()->json(['data' => $orders]);
    }

    /**
     * Batch update the KDS status of an order and all its items
     */
    public function updateKdsStatus($id, Request $request)
    {
        $request->validate([
            'kds_status' => 'required|in:pending,preparing,ready',
        ]);

        $order = Order::where('company_id', $request->user()->company_id)->with('items')->findOrFail($id);
        $order->kds_status = $request->kds_status;
        $order->save();

        // Batch update all child items to match
        $order->items()->update(['kds_status' => $request->kds_status]);

        return response()->json([
            'message' => 'Status antrean pesanan berhasil diperbarui.',
            'data' => $order->load(['items.product', 'user', 'servicedBy', 'shift.branch'])
        ]);
    }

    /**
     * Update the KDS status of a single item in an order
     */
    public function updateItemKdsStatus($orderId, $itemId, Request $request)
    {
        $request->validate([
            'kds_status' => 'required|in:pending,preparing,ready',
        ]);

        $order = Order::where('company_id', $request->user()->company_id)->with('items')->findOrFail($orderId);
        $item = $order->items()->findOrFail($itemId);

        $item->kds_status = $request->kds_status;
        $item->save();

        // Re-evaluate overall order kds_status based on all items
        $allItems = $order->items()->get();
        $allReady = $allItems->every(fn($i) => $i->kds_status === 'ready');
        $allPending = $allItems->every(fn($i) => $i->kds_status === 'pending');

        if ($allReady) {
            $order->kds_status = 'ready';
        } elseif ($allPending) {
            $order->kds_status = 'pending';
        } else {
            $order->kds_status = 'preparing';
        }
        $order->save();

        return response()->json([
            'message' => 'Status item berhasil diperbarui.',
            'data' => $order->load(['items.product', 'user', 'servicedBy', 'shift.branch'])
        ]);
    }
}
