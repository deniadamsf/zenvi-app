<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Order;
use App\Models\Shift;
use App\Models\Company;
use App\Models\EmployeePermission;
use Illuminate\Http\Request;
use Carbon\Carbon;

class EmployeePerformanceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner' && $user->role !== 'Admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $companyId = $user->company_id;
        $company = Company::find($companyId);
        $schedules = ($company && is_array($company->shift_schedules)) ? $company->shift_schedules : [];
        $tolerance = ($company && $company->late_tolerance_minutes !== null) ? (int)$company->late_tolerance_minutes : 0;

        $period = $request->get('period', 'this_month');
        $startDate = null;
        $endDate = null;

        $now = Carbon::now();
        switch ($period) {
            case 'today':
                $startDate = $now->copy()->startOfDay();
                $endDate = $now->copy()->endOfDay();
                $periodLabel = 'Hari Ini (' . $startDate->translatedFormat('d M Y') . ')';
                break;
            case '7days':
                $startDate = $now->copy()->subDays(6)->startOfDay();
                $endDate = $now->copy()->endOfDay();
                $periodLabel = '7 Hari Terakhir';
                break;
            case '30days':
                $startDate = $now->copy()->subDays(29)->startOfDay();
                $endDate = $now->copy()->endOfDay();
                $periodLabel = '30 Hari Terakhir';
                break;
            case 'this_month':
                $startDate = $now->copy()->startOfMonth();
                $endDate = $now->copy()->endOfMonth();
                $periodLabel = 'Bulan Ini (' . $now->translatedFormat('F Y') . ')';
                break;
            case 'custom':
                if ($request->has('start_date') && $request->has('end_date')) {
                    $startDate = Carbon::parse($request->start_date)->startOfDay();
                    $endDate = Carbon::parse($request->end_date)->endOfDay();
                    $periodLabel = $startDate->format('d/m/Y') . ' - ' . $endDate->format('d/m/Y');
                } else {
                    $startDate = $now->copy()->startOfMonth();
                    $endDate = $now->copy()->endOfMonth();
                    $periodLabel = 'Bulan Ini';
                }
                break;
            case 'all':
            default:
                $periodLabel = 'Semua Waktu';
                break;
        }

        // Daftar 5 shift terakhir cukup untuk kartu ringkas di dashboard, tapi
        // jadi laporan absensi yang menyesatkan begitu rentangnya lebih dari
        // beberapa hari - karyawan yang masuk 22 kali akan terbaca 5 kali.
        // Ekspor absensi meminta `shift_detail=full` supaya seluruh shift dalam
        // rentang ikut terkirim; dashboard tetap memakai daftar pendeknya.
        $fullShiftDetail = $request->query('shift_detail') === 'full';

        // Get all approved employees in the company
        $employees = User::where('company_id', $companyId)
            ->where('is_approved', true)
            ->get();

        $employeeData = [];
        $outletTotalSales = 0;
        $outletTotalOrders = 0;
        $outletTotalShifts = 0;
        $outletTotalWorkMinutes = 0;

        foreach ($employees as $emp) {
            // 1. Orders statistics — SEPARATED to prevent double-counting
            // 1a. Orders where this employee was the CASHIER (who processed the transaction)
            $cashierOrdersQuery = Order::where('company_id', $companyId)
                ->where('user_id', $emp->id)
                ->where('status', '!=', 'voided');

            // 1b. Orders where this employee was the SERVICE STAFF (kapster/terapis who served)
            //     but someone ELSE was the cashier
            $servicedOrdersQuery = Order::where('company_id', $companyId)
                ->where('serviced_by_user_id', $emp->id)
                ->where('user_id', '!=', $emp->id) // Exclude orders where they're also the cashier
                ->where('status', '!=', 'voided');

            if ($startDate && $endDate) {
                $cashierOrdersQuery->whereBetween('created_at', [$startDate, $endDate]);
                $servicedOrdersQuery->whereBetween('created_at', [$startDate, $endDate]);
            }

            $cashierOrders = $cashierOrdersQuery->get();
            $servicedOrders = $servicedOrdersQuery->get();

            // Cashier-attributed sales (used for outlet totals to prevent double-count)
            $cashierSalesAmount = (float) $cashierOrders->sum('total_amount');
            $cashierOrdersCount = $cashierOrders->count();

            // Service-attributed sales (additional metric for kapster/terapis performance)
            $servicedSalesAmount = (float) $servicedOrders->sum('total_amount');
            $servicedOrdersCount = $servicedOrders->count();

            // Combined view for the employee's total involvement
            $allOrders = $cashierOrders->merge($servicedOrders);
            $totalSales = (float) $allOrders->sum('total_amount');
            $totalOrders = $allOrders->count();
            $averageOrderValue = $totalOrders > 0 ? round($totalSales / $totalOrders) : 0;
            $cashSales = (float) $allOrders->where('payment_method', 'cash')->sum('total_amount');
            $qrisSales = (float) $allOrders->where('payment_method', 'qris')->sum('total_amount');
            $transferSales = (float) $allOrders->where('payment_method', 'transfer')->sum('total_amount');

            // 2. Approved Permissions
            $permissionsQuery = EmployeePermission::where('company_id', $companyId)
                ->where('user_id', $emp->id)
                ->where('status', 'approved');

            if ($startDate && $endDate) {
                $permissionsQuery->whereBetween('permission_date', [$startDate->format('Y-m-d'), $endDate->format('Y-m-d')]);
            }
            $approvedPermissions = $permissionsQuery->get();
            $approvedLeavesCount = $approvedPermissions->where('type', 'leave')->count();

            // 3. Shifts, Attendance, Punctuality & Working Hours
            $shiftsQuery = Shift::where('company_id', $companyId)
                ->where('user_id', $emp->id);

            if ($startDate && $endDate) {
                $shiftsQuery->whereBetween('start_time', [$startDate, $endDate]);
            }

            $shifts = $shiftsQuery->with('orders')->orderBy('start_time', 'desc')->get();
            $totalShifts = $shifts->count();
            $closedShiftsCount = 0;
            $totalWorkMinutes = 0;
            $totalCashVariance = 0;
            $exactCashShiftsCount = 0;
            $onTimeShiftsCount = 0;
            $lateShiftsCount = 0;
            $excusedLateShiftsCount = 0;
            $totalLateMinutes = 0;

            $recentShiftsList = [];
            foreach ($shifts as $idx => $s) {
                $start = Carbon::parse($s->start_time);
                $end = $s->end_time ? Carbon::parse($s->end_time) : Carbon::now();
                $workMinutes = max(0, $end->diffInMinutes($start));
                $totalWorkMinutes += $workMinutes;

                // Shift cash variance calculation
                $shiftOrders = $s->orders ? $s->orders->where('status', '!=', 'voided') : collect();
                $shiftCashRevenue = (float) $shiftOrders->where('payment_method', 'cash')->sum('total_amount');
                $expectedCash = (float) $s->opening_balance + $shiftCashRevenue;
                
                $variance = null;
                if ($s->status === 'closed') {
                    $closedShiftsCount++;
                    if ($s->closing_balance !== null) {
                        $variance = (float) $s->closing_balance - $expectedCash;
                        $totalCashVariance += $variance;
                        if (abs($variance) < 100) { // Tolerance Rp 100 for small coin rounding
                            $exactCashShiftsCount++;
                        }
                    } else {
                        // Closed without cash count issue
                        $exactCashShiftsCount++;
                    }
                }

                // Punctuality / Lateness calculation
                $shiftLateMinutes = 0;
                $isLate = false;
                $isExcused = false;
                $shiftName = 'Shift Reguler';

                $shiftDateStr = $start->format('Y-m-d');
                $hasApprovedLatePermit = $approvedPermissions->first(function($p) use ($shiftDateStr) {
                    $pDate = $p->permission_date instanceof Carbon ? $p->permission_date->format('Y-m-d') : substr((string)$p->permission_date, 0, 10);
                    return $p->type === 'late' && $pDate === $shiftDateStr;
                });

                if (!empty($schedules)) {
                    // Find closest matching schedule
                    $bestSchedule = $schedules[0];
                    $minDiff = PHP_INT_MAX;

                    foreach ($schedules as $schedule) {
                        if (isset($schedule['start'])) {
                            $schedStart = Carbon::parse($start->format('Y-m-d') . ' ' . $schedule['start']);
                            $diff = abs($start->diffInMinutes($schedStart));
                            if ($diff < $minDiff) {
                                $minDiff = $diff;
                                $bestSchedule = $schedule;
                            }
                        }
                    }

                    if (isset($bestSchedule['start'])) {
                        $shiftName = $bestSchedule['name'] ?? 'Shift';
                        $schedStart = Carbon::parse($start->format('Y-m-d') . ' ' . $bestSchedule['start']);
                        
                        // Strict threshold: if tolerance is 0, any minute past scheduled start is late!
                        if ($start->greaterThan($schedStart->copy()->addMinutes($tolerance))) {
                            $shiftLateMinutes = max(1, $start->diffInMinutes($schedStart));
                            
                            if ($hasApprovedLatePermit) {
                                $isLate = false;
                                $isExcused = true;
                                $excusedLateShiftsCount++;
                                $onTimeShiftsCount++; // Excused late doesn't penalize on-time count
                            } else {
                                $isLate = true;
                                $lateShiftsCount++;
                                $totalLateMinutes += $shiftLateMinutes;
                            }
                        } else {
                            $onTimeShiftsCount++;
                        }
                    } else {
                        $onTimeShiftsCount++;
                    }
                } else {
                    // If no schedules are configured by owner
                    $onTimeShiftsCount++;
                }

                if ($fullShiftDetail || $idx < 5) {
                    $recentShiftsList[] = [
                        'id' => $s->id,
                        'start_time' => $s->start_time ? $s->start_time->toIso8601String() : null,
                        'end_time' => $s->end_time ? $s->end_time->toIso8601String() : null,
                        'shift_name' => $shiftName,
                        'duration_formatted' => floor($workMinutes / 60) . 'j ' . ($workMinutes % 60) . 'm',
                        'opening_balance' => (float) $s->opening_balance,
                        'closing_balance' => $s->closing_balance !== null ? (float) $s->closing_balance : null,
                        'cash_variance' => $variance,
                        'is_late' => $isLate,
                        'is_excused' => $isExcused,
                        'excuse_reason' => $hasApprovedLatePermit ? $hasApprovedLatePermit->reason : null,
                        'late_minutes' => $shiftLateMinutes,
                        'total_revenue' => (float) $shiftOrders->sum('total_amount'),
                        'status' => $s->status,
                    ];
                }
            }

            $totalWorkHours = round($totalWorkMinutes / 60, 1);
            
            // Accuracy %: out of closed shifts (default 100% if no closed shifts yet)
            $accuracyPercentage = $closedShiftsCount > 0 
                ? round(($exactCashShiftsCount / $closedShiftsCount) * 100) 
                : 100;

            // Punctuality %
            $punctualityPercentage = $totalShifts > 0 
                ? round(($onTimeShiftsCount / $totalShifts) * 100) 
                : 100;

            $outletTotalSales += $cashierSalesAmount; // Use cashier-only to prevent double-counting
            $outletTotalOrders += $cashierOrdersCount;
            $outletTotalShifts += $totalShifts;
            $outletTotalWorkMinutes += $totalWorkMinutes;

            $approvedLeavesList = $approvedPermissions->where('type', 'leave')->map(function($p) {
                return [
                    'id' => $p->id,
                    'date' => $p->permission_date instanceof Carbon ? $p->permission_date->format('Y-m-d') : substr((string)$p->permission_date, 0, 10),
                    'reason' => $p->reason,
                    'approved_at' => $p->reviewed_at ? $p->reviewed_at->toIso8601String() : null,
                ];
            })->values()->toArray();

            $employeeData[] = [
                'id' => $emp->id,
                'name' => $emp->name,
                'email' => $emp->email,
                'role' => $emp->role,
                'job_title' => $emp->job_title,
                'permissions' => $emp->permissions,
                'total_sales' => $totalSales,
                'total_orders' => $totalOrders,
                'cashier_sales' => $cashierSalesAmount,
                'cashier_orders' => $cashierOrdersCount,
                'serviced_sales' => $servicedSalesAmount,
                'serviced_orders' => $servicedOrdersCount,
                'average_order_value' => $averageOrderValue,
                'cash_sales' => $cashSales,
                'qris_sales' => $qrisSales,
                'transfer_sales' => $transferSales,
                'total_shifts' => $totalShifts,
                'closed_shifts_count' => $closedShiftsCount,
                'total_work_minutes' => $totalWorkMinutes,
                'total_work_hours' => $totalWorkHours,
                'total_cash_variance' => $totalCashVariance,
                'accuracy_percentage' => $accuracyPercentage,
                'punctuality_percentage' => $punctualityPercentage,
                'on_time_shifts_count' => $onTimeShiftsCount,
                'late_shifts_count' => $lateShiftsCount,
                'excused_late_shifts_count' => $excusedLateShiftsCount,
                'approved_leaves_count' => $approvedLeavesCount,
                'approved_leaves' => $approvedLeavesList,
                'total_late_minutes' => $totalLateMinutes,
                'recent_shifts' => $recentShiftsList,
            ];
        }

        // Calculate sales contribution % for each employee
        foreach ($employeeData as &$data) {
            $data['sales_contribution_percent'] = $outletTotalSales > 0 
                ? round(($data['total_sales'] / $outletTotalSales) * 100, 1) 
                : 0.0;
        }
        unset($data);

        // Sort employees by total_sales descending by default
        usort($employeeData, function ($a, $b) {
            if ($b['total_sales'] == $a['total_sales']) {
                return $b['total_orders'] <=> $a['total_orders'];
            }
            return $b['total_sales'] <=> $a['total_sales'];
        });

        // 3. Leaderboard / Performa Terbaik (Top Performers)
        $topSales = null;
        $mostOrders = null;
        $bestAccuracy = null;
        $mostHours = null;
        $mostPunctual = null;

        // 1) Top Sales Champion
        $sortedBySales = $employeeData;
        usort($sortedBySales, fn($a, $b) => $b['total_sales'] <=> $a['total_sales']);
        if (!empty($sortedBySales) && $sortedBySales[0]['total_sales'] > 0) {
            $top = $sortedBySales[0];
            $topSales = [
                'user_id' => $top['id'],
                'name' => $top['name'],
                'role' => $top['role'],
                'badge' => 'Juara Omzet',
                'description' => 'Kontribusi penjualan tertinggi',
                'value' => 'Rp ' . number_format($top['total_sales'], 0, ',', '.'),
                'sub_value' => $top['sales_contribution_percent'] . '% dari total omzet',
            ];
        }

        // 2) Most Orders (Most Productive)
        $sortedByOrders = $employeeData;
        usort($sortedByOrders, fn($a, $b) => $b['total_orders'] <=> $a['total_orders']);
        if (!empty($sortedByOrders) && $sortedByOrders[0]['total_orders'] > 0) {
            $top = $sortedByOrders[0];
            $mostOrders = [
                'user_id' => $top['id'],
                'name' => $top['name'],
                'role' => $top['role'],
                'badge' => 'Paling Produktif',
                'description' => 'Melayani transaksi terbanyak',
                'value' => $top['total_orders'] . ' Transaksi',
                'sub_value' => 'Rata-rata Rp ' . number_format($top['average_order_value'], 0, ',', '.') . '/struk',
            ];
        }

        // 3) Best Accuracy (Most Accurate Cashier)
        $sortedByAccuracy = array_filter($employeeData, fn($e) => $e['total_shifts'] > 0);
        usort($sortedByAccuracy, function ($a, $b) {
            if ($b['accuracy_percentage'] == $a['accuracy_percentage']) {
                return abs($a['total_cash_variance']) <=> abs($b['total_cash_variance']);
            }
            return $b['accuracy_percentage'] <=> $a['accuracy_percentage'];
        });
        $sortedByAccuracy = array_values($sortedByAccuracy);
        if (!empty($sortedByAccuracy)) {
            $top = $sortedByAccuracy[0];
            $varianceText = $top['total_cash_variance'] == 0 
                ? 'Selisih Rp 0 (100% Pas)' 
                : ($top['total_cash_variance'] > 0 ? '+Rp ' . number_format($top['total_cash_variance'], 0, ',', '.') : '-Rp ' . number_format(abs($top['total_cash_variance']), 0, ',', '.'));

            $bestAccuracy = [
                'user_id' => $top['id'],
                'name' => $top['name'],
                'role' => $top['role'],
                'badge' => 'Kasir Paling Akurat',
                'description' => 'Pengelolaan kasir paling presisi',
                'value' => $top['accuracy_percentage'] . '% Akurat',
                'sub_value' => $varianceText . ' (' . $top['total_shifts'] . ' shift)',
            ];
        }

        // 4) Most Dedicated / Working Hours
        $sortedByHours = $employeeData;
        usort($sortedByHours, fn($a, $b) => $b['total_work_minutes'] <=> $a['total_work_minutes']);
        if (!empty($sortedByHours) && $sortedByHours[0]['total_work_minutes'] > 0) {
            $top = $sortedByHours[0];
            $mostHours = [
                'user_id' => $top['id'],
                'name' => $top['name'],
                'role' => $top['role'],
                'badge' => 'Paling Rajin',
                'description' => 'Jam kerja aktif tertinggi',
                'value' => $top['total_work_hours'] . ' Jam Kerja',
                'sub_value' => $top['total_shifts'] . ' total shift selesai',
            ];
        }

        // 5) Most Punctual / Attendance Discipline (Absensi Rutin & Tidak Pernah Telat)
        $sortedByPunctuality = array_filter($employeeData, fn($e) => $e['total_shifts'] > 0);
        usort($sortedByPunctuality, function ($a, $b) {
            if ($b['punctuality_percentage'] == $a['punctuality_percentage']) {
                if ($b['total_shifts'] == $a['total_shifts']) {
                    return $a['total_late_minutes'] <=> $b['total_late_minutes'];
                }
                return $b['total_shifts'] <=> $a['total_shifts'];
            }
            return $b['punctuality_percentage'] <=> $a['punctuality_percentage'];
        });
        $sortedByPunctuality = array_values($sortedByPunctuality);
        if (!empty($sortedByPunctuality)) {
            $top = $sortedByPunctuality[0];
            $lateDetail = $top['late_shifts_count'] == 0 
                ? '0x Telat (' . $top['total_shifts'] . ' Shift Selesai)' 
                : $top['late_shifts_count'] . 'x Telat (Total ' . $top['total_late_minutes'] . ' mnt)';

            $mostPunctual = [
                'user_id' => $top['id'],
                'name' => $top['name'],
                'role' => $top['role'],
                'badge' => 'Paling Tepat Waktu',
                'description' => 'Absensi rutin & selalu on-time',
                'value' => $top['punctuality_percentage'] . '% Tepat Waktu',
                'sub_value' => $lateDetail,
            ];
        }

        return response()->json([
            'status' => 'success',
            'period' => $period,
            'period_label' => $periodLabel,
            'summary' => [
                'total_employees' => count($employees),
                'total_sales' => $outletTotalSales,
                'total_orders' => $outletTotalOrders,
                'total_shifts' => $outletTotalShifts,
                'total_work_hours' => round($outletTotalWorkMinutes / 60, 1),
                'average_order_value' => $outletTotalOrders > 0 ? round($outletTotalSales / $outletTotalOrders) : 0,
            ],
            'top_performers' => [
                'top_sales' => $topSales,
                'most_orders' => $mostOrders,
                'best_accuracy' => $bestAccuracy,
                'most_hours' => $mostHours,
                'most_punctual' => $mostPunctual,
            ],
            'employees' => $employeeData,
        ]);
    }
}
