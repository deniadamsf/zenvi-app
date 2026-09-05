<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\Expense;
use App\Models\Ingredient;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Shift;
use App\Support\Entitlements;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        $expenses = Expense::where('company_id', $request->user()->company_id)
            ->with('user:id,name')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'message' => 'Expenses retrieved successfully',
            'data' => $expenses
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'expense_type' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'ingredient_id' => 'nullable|exists:ingredients,id',
            'qty_added' => 'nullable|numeric|min:0'
        ]);

        $user = $request->user();

        DB::beginTransaction();
        try {
            $expense = Expense::create([
                'company_id' => $user->company_id,
                'user_id' => $user->id,
                'expense_type' => $request->expense_type,
                'amount' => $request->amount,
                'description' => $request->description,
            ]);

            // If it's an ingredient restock, update the stock
            if ($request->expense_type === 'ingredient_restock' && $request->ingredient_id && $request->qty_added) {
                $ingredient = Ingredient::where('id', $request->ingredient_id)
                    ->where('company_id', $user->company_id)
                    ->firstOrFail();

                $ingredient->increment('stock_qty', $request->qty_added);
            }

            DB::commit();

            return response()->json([
                'message' => 'Expense created successfully',
                'data' => $expense
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Failed to create expense: ' . $e->getMessage()
            ], 500);
        }
    }

    public function financialReport(Request $request)
    {
        $companyId = $request->user()->company_id;
        $period = $request->query('period', 'today');
        $branchId = $request->query('branch_id');
        $customDate = $request->query('date');
        $startDateParam = $request->query('start_date');
        $endDateParam = $request->query('end_date');

        $now = \Carbon\Carbon::now();
        $startDate = $now->copy()->startOfDay();
        $endDate = $now->copy()->endOfDay();

        if ($period === 'custom' || $period === 'date') {
            if ($startDateParam && $endDateParam) {
                $startDate = \Carbon\Carbon::parse($startDateParam)->startOfDay();
                $endDate = \Carbon\Carbon::parse($endDateParam)->endOfDay();
            } elseif ($customDate) {
                $startDate = \Carbon\Carbon::parse($customDate)->startOfDay();
                $endDate = \Carbon\Carbon::parse($customDate)->endOfDay();
            }
        } else {
            switch ($period) {
                case 'today':
                    $startDate = $now->copy()->startOfDay();
                    $endDate = $now->copy()->endOfDay();
                    break;
                case '7_days':
                    $startDate = $now->copy()->subDays(6)->startOfDay();
                    $endDate = $now->copy()->endOfDay();
                    break;
                case '30_days':
                    $startDate = $now->copy()->subDays(29)->startOfDay();
                    $endDate = $now->copy()->endOfDay();
                    break;
                case 'this_month':
                    $startDate = $now->copy()->startOfMonth();
                    $endDate = $now->copy()->endOfMonth();
                    break;
                case 'this_year':
                    $startDate = $now->copy()->startOfYear();
                    $endDate = $now->copy()->endOfYear();
                    break;
                default:
                    $startDate = $now->copy()->startOfDay();
                    $endDate = $now->copy()->endOfDay();
                    break;
            }
        }

        // Batas riwayat sesuai paket: rentang yang diminta dipangkas, BUKAN
        // ditolak. Laporan tetap tampil dan tetap benar untuk rentang yang
        // boleh dilihat - menolak seluruh permintaan akan mengosongkan
        // dashboard paket gratis dan membuatnya terasa rusak, bukan terbatas.
        $historyDays = Entitlements::for($request->user()->company)->historyDays();
        if ($historyDays !== null) {
            $earliest = $now->copy()->subDays($historyDays)->startOfDay();
            if ($startDate->lessThan($earliest)) {
                $startDate = $earliest;
            }
        }

        // Base Orders Query
        $orderQuery = Order::where('company_id', $companyId)
            ->where('created_at', '>=', $startDate)
            ->where('created_at', '<=', $endDate)
            ->where('status', '!=', 'voided');

        if ($branchId && $branchId !== 'all' && $branchId !== '0') {
            $orderQuery->whereHas('shift', function ($q) use ($branchId) {
                $q->where('branch_id', $branchId);
            });
        }

        // Base Expenses Query
        $expenseQuery = Expense::where('company_id', $companyId)
            ->where('created_at', '>=', $startDate)
            ->where('created_at', '<=', $endDate);

        $totalSales = (float) (clone $orderQuery)->sum('total_amount');
        $totalOrders = (int) (clone $orderQuery)->count();
        $totalExpenses = (float) (clone $expenseQuery)->sum('amount');
        $avgOrderValue = $totalOrders > 0 ? round($totalSales / $totalOrders, 2) : 0.0;

        // Calculate COGS (HPP) across all orders in period
        $orderIds = (clone $orderQuery)->pluck('id');
        $orderItems = OrderItem::whereIn('order_id', $orderIds)
            ->with(['product.ingredients', 'order:id,created_at'])
            ->get();

        $totalCogs = 0.0;
        $cogsByHour = array_fill(0, 24, 0.0);
        $cogsByDate = [];
        $productCogsMap = []; // product_id => total_cogs

        foreach ($orderItems as $item) {
            $product = $item->product;
            $unitCogs = $product ? $product->calculateCogs() : 0.0;
            $itemCogs = $unitCogs * (int) $item->qty;
            $totalCogs += $itemCogs;

            if ($item->order && $item->order->created_at) {
                $hour = (int) $item->order->created_at->format('H');
                $dateKey = $item->order->created_at->format('Y-m-d');
                $cogsByHour[$hour] = ($cogsByHour[$hour] ?? 0.0) + $itemCogs;
                $cogsByDate[$dateKey] = ($cogsByDate[$dateKey] ?? 0.0) + $itemCogs;
            }

            $productCogsMap[$item->product_id] = ($productCogsMap[$item->product_id] ?? 0.0) + $itemCogs;
        }

        $grossProfit = $totalSales - $totalCogs;
        $grossMarginPercent = $totalSales > 0 ? round(($grossProfit / $totalSales) * 100, 1) : 0.0;
        $netProfit = $grossProfit - $totalExpenses;
        $netMarginPercent = $totalSales > 0 ? round(($netProfit / $totalSales) * 100, 1) : 0.0;

        // Daily / Hourly Periodic Chart Data
        $chartData = [];
        $isSingleDay = $startDate->isSameDay($endDate);

        if ($period === 'today' || $isSingleDay) {
            // For single day, return 24-hour breakdown
            $hourlySalesMap = (clone $orderQuery)
                ->selectRaw('HOUR(created_at) as hour, SUM(total_amount) as total, COUNT(id) as orders_count')
                ->groupBy('hour')
                ->get()
                ->keyBy('hour');

            $hourlyExpenseMap = (clone $expenseQuery)
                ->selectRaw('HOUR(created_at) as hour, SUM(amount) as total')
                ->groupBy('hour')
                ->get()
                ->keyBy('hour');

            for ($h = 0; $h < 24; $h++) {
                $sales = isset($hourlySalesMap[$h]) ? (float)$hourlySalesMap[$h]->total : 0.0;
                $expense = isset($hourlyExpenseMap[$h]) ? (float)$hourlyExpenseMap[$h]->total : 0.0;
                $cogs = (float) ($cogsByHour[$h] ?? 0.0);
                $orders = isset($hourlySalesMap[$h]) ? (int)$hourlySalesMap[$h]->orders_count : 0;
                $gross = $sales - $cogs;
                $net = $gross - $expense;
                $chartData[] = [
                    'date' => sprintf('%02d:00', $h),
                    'label' => sprintf('%02d:00', $h),
                    'sales' => $sales,
                    'cogs' => $cogs,
                    'gross_profit' => $gross,
                    'expense' => $expense,
                    'profit' => $net,
                    'net_profit' => $net,
                    'orders' => $orders,
                ];
            }
        } else {
            // Multi-day aggregation
            $salesByDate = (clone $orderQuery)
                ->selectRaw('DATE(created_at) as date, SUM(total_amount) as total, COUNT(id) as orders_count')
                ->groupBy('date')
                ->get()
                ->keyBy('date');

            $expensesByDate = (clone $expenseQuery)
                ->selectRaw('DATE(created_at) as date, SUM(amount) as total')
                ->groupBy('date')
                ->get()
                ->keyBy('date');

            $currentDate = clone $startDate;
            $loopEndDate = min($endDate, \Carbon\Carbon::today()->endOfDay());

            while ($currentDate <= $loopEndDate) {
                $dateString = $currentDate->format('Y-m-d');
                $dailySales = isset($salesByDate[$dateString]) ? (float)$salesByDate[$dateString]->total : 0.0;
                $dailyExpense = isset($expensesByDate[$dateString]) ? (float)$expensesByDate[$dateString]->total : 0.0;
                $dailyCogs = (float) ($cogsByDate[$dateString] ?? 0.0);
                $dailyOrders = isset($salesByDate[$dateString]) ? (int)$salesByDate[$dateString]->orders_count : 0;
                $dailyGross = $dailySales - $dailyCogs;
                $dailyNet = $dailyGross - $dailyExpense;

                $chartData[] = [
                    'date' => $dateString,
                    'label' => $currentDate->format('d M'),
                    'sales' => $dailySales,
                    'cogs' => $dailyCogs,
                    'gross_profit' => $dailyGross,
                    'expense' => $dailyExpense,
                    'profit' => $dailyNet,
                    'net_profit' => $dailyNet,
                    'orders' => $dailyOrders,
                ];
                $currentDate->addDay();
            }
        }

        // Hourly Sales Breakdown (For peak hour bar chart)
        $hourlySales = [];
        $hourlySalesMap = (clone $orderQuery)
            ->selectRaw('HOUR(created_at) as hour, SUM(total_amount) as total, COUNT(id) as orders_count')
            ->groupBy('hour')
            ->get()
            ->keyBy('hour');

        for ($h = 0; $h <= 23; $h++) {
            $hourlySales[] = [
                'hour' => $h,
                'label' => sprintf('%02d:00', $h),
                'sales' => isset($hourlySalesMap[$h]) ? (float)$hourlySalesMap[$h]->total : 0.0,
                'orders' => isset($hourlySalesMap[$h]) ? (int)$hourlySalesMap[$h]->orders_count : 0,
            ];
        }

        // Payment Methods Breakdown (Donut Chart)
        $paymentMethodsRaw = (clone $orderQuery)
            ->selectRaw('payment_method, SUM(total_amount) as total, COUNT(id) as count')
            ->groupBy('payment_method')
            ->get();

        $paymentMethods = [];
        $pmLabels = ['cash' => 'Tunai', 'qris' => 'QRIS', 'transfer' => 'Transfer', 'other' => 'Lainnya'];
        $pmColors = ['cash' => '#10B981', 'qris' => '#3B82F6', 'transfer' => '#8B5CF6', 'other' => '#F59E0B'];

        foreach ($paymentMethodsRaw as $pm) {
            $key = strtolower($pm->payment_method ?? 'cash');
            $pmTotal = (float) $pm->total;
            $paymentMethods[] = [
                'method' => $key,
                'label' => $pmLabels[$key] ?? ucfirst($key),
                'amount' => $pmTotal,
                'total' => $pmTotal,
                'count' => (int) $pm->count,
                'percent' => $totalSales > 0 ? round(($pmTotal / $totalSales) * 100, 1) : 0,
                'percentage' => $totalSales > 0 ? round(($pmTotal / $totalSales) * 100, 1) : 0,
                'color' => $pmColors[$key] ?? '#6B7280',
            ];
        }

        // Top 5 Best Selling Products (with COGS and Profit Margin)
        $topProducts = OrderItem::whereIn('order_id', $orderIds)
            ->selectRaw('product_id, SUM(qty) as total_qty, SUM(subtotal) as total_revenue')
            ->groupBy('product_id')
            ->orderByDesc('total_revenue')
            ->limit(5)
            ->with('product:id,name,image_path,category,cost_price')
            ->get()
            ->map(function ($item) use ($productCogsMap) {
                $rev = (float) $item->total_revenue;
                $cogs = (float) ($productCogsMap[$item->product_id] ?? 0.0);
                $profit = $rev - $cogs;
                $margin = $rev > 0 ? round(($profit / $rev) * 100, 1) : 0.0;
                return [
                    'product_id' => $item->product_id,
                    'name' => $item->product ? $item->product->name : 'Produk Tidak Dikenal',
                    'category' => $item->product ? $item->product->category : null,
                    'image_url' => $item->product ? $item->product->image_url : null,
                    'qty' => (int) $item->total_qty,
                    'revenue' => $rev,
                    'total' => $rev,
                    'cogs' => $cogs,
                    'profit' => $profit,
                    'margin_percent' => $margin,
                ];
            });

        // Branch Performance Breakdown
        $allBranches = Branch::where('company_id', $companyId)->get();
        $branchPerformance = [];
        foreach ($allBranches as $b) {
            $bOrders = Order::where('company_id', $companyId)
                ->where('created_at', '>=', $startDate)
                ->where('created_at', '<=', $endDate)
                ->where('status', '!=', 'voided')
                ->whereHas('shift', function ($q) use ($b) {
                    $q->where('branch_id', $b->id);
                });

            $bSales = (float) (clone $bOrders)->sum('total_amount');
            $bCount = (int) (clone $bOrders)->count();
            $bActiveShifts = Shift::where('company_id', $companyId)
                ->where('branch_id', $b->id)
                ->where('status', 'active')
                ->count();

            $branchPerformance[] = [
                'branch_id' => $b->id,
                'name' => $b->name,
                'sales' => $bSales,
                'orders' => $bCount,
                'orders_count' => $bCount,
                'active_shifts' => $bActiveShifts,
                'percentage' => $totalSales > 0 ? round(($bSales / $totalSales) * 100, 1) : 0,
            ];
        }

        // Shifts Summary
        $shiftsQuery = Shift::where('company_id', $companyId)
            ->where('start_time', '>=', $startDate)
            ->where('start_time', '<=', $endDate)
            ->with(['user:id,name', 'branch:id,name', 'orders']);

        if ($branchId && $branchId !== 'all' && $branchId !== '0') {
            $shiftsQuery->where('branch_id', $branchId);
        }

        $shiftSummaries = $shiftsQuery->orderBy('start_time', 'desc')->limit(10)->get()->map(function ($s) {
            $orders = $s->orders->where('status', '!=', 'voided');
            $totalRevenue = (float) $orders->sum('total_amount');
            return [
                'id' => $s->id,
                'employee_name' => $s->user ? $s->user->name : 'Kasir',
                'branch_name' => $s->branch ? $s->branch->name : 'Semua Cabang',
                'status' => $s->status,
                'start_time' => $s->start_time ? \Carbon\Carbon::parse($s->start_time)->format('H:i') : '',
                'end_time' => $s->end_time ? \Carbon\Carbon::parse($s->end_time)->format('H:i') : '',
                'revenue' => $totalRevenue,
                'orders_count' => $orders->count(),
            ];
        });

        // Recent Expenses for the selected period
        $recentExpenses = (clone $expenseQuery)
            ->with('user:id,name')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($exp) {
                return [
                    'id' => $exp->id,
                    'expense_type' => $exp->expense_type,
                    'amount' => (float) $exp->amount,
                    'description' => $exp->description,
                    'user_name' => $exp->user ? $exp->user->name : 'Owner',
                    'created_at' => $exp->created_at->toIso8601String(),
                ];
            });

        // Expense by Category Breakdown
        $expenseCategoriesRaw = (clone $expenseQuery)
            ->selectRaw('expense_type, SUM(amount) as total, COUNT(id) as count')
            ->groupBy('expense_type')
            ->get();

        $expenseBreakdown = [];
        $typeLabels = [
            'ingredient_restock' => 'Restock Bahan',
            'salary' => 'Gaji Karyawan',
            'operational' => 'Operasional',
            'other' => 'Lainnya'
        ];
        $typeColors = [
            'ingredient_restock' => '#F59E0B',
            'salary' => '#8B5CF6',
            'operational' => '#3B82F6',
            'other' => '#6B7280'
        ];

        foreach ($expenseCategoriesRaw as $ec) {
            $type = $ec->expense_type ?? 'other';
            $ecTotal = (float) $ec->total;
            $expenseBreakdown[] = [
                'type' => $type,
                'label' => $typeLabels[$type] ?? ucfirst(str_replace('_', ' ', $type)),
                'amount' => $ecTotal,
                'total' => $ecTotal,
                'count' => (int) $ec->count,
                'percent' => $totalExpenses > 0 ? round(($ecTotal / $totalExpenses) * 100, 1) : 0,
                'color' => $typeColors[$type] ?? '#6B7280',
            ];
        }

        return response()->json([
            'message' => 'Financial report generated',
            'data' => [
                'period' => $period,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'total_sales' => $totalSales,
                'total_cogs' => $totalCogs,
                'gross_profit' => $grossProfit,
                'gross_margin_percent' => $grossMarginPercent,
                'total_expenses' => $totalExpenses,
                'net_profit' => $netProfit,
                'net_margin_percent' => $netMarginPercent,
                'total_orders' => $totalOrders,
                'avg_order_value' => $avgOrderValue,
                'average_order_value' => $avgOrderValue,
                'chart_data' => $chartData,
                'hourly_sales' => $hourlySales,
                'payment_methods' => $paymentMethods,
                'top_products' => $topProducts,
                // Dipangkas kalau paket tidak mencakupnya: mengirim data yang
                // tidak berhak ditampilkan hanya memboroskan bandwidth, dan
                // membuat klien yang dimodifikasi tetap bisa melihatnya.
                'branch_performance' => Entitlements::for($request->user()->company)
                    ->hasFeature('consolidated_report') ? $branchPerformance : [],
                'shift_summaries' => $shiftSummaries,
                'recent_expenses' => $recentExpenses,
                'expense_breakdown' => $expenseBreakdown,
            ]
        ]);
    }
}
