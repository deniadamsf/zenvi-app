<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shift;
use Illuminate\Http\Request;
use Carbon\Carbon;
use App\Models\Ingredient;
use App\Models\IngredientHistory;
use App\Services\FirebaseNotificationService;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class ShiftController extends Controller
{
    /**
     * Distance calculation using Haversine formula
     * Returns distance in meters
     */
    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // Radius of the earth in meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c; // Distance in meters
    }

    /**
     * Passive task: Auto-close stale shifts and delete old selfies
     */
    private function runPassiveTasks($companyId)
    {
        // Tugas ini menghapus file selfie satu per satu; operasi filesystem di
        // shared hosting lambat dan dulu ditanggung oleh setiap request shift.
        // Cache::add() bersifat atomik: baris ini hanya lolos sekali per jam per
        // perusahaan, request lain langsung lewat tanpa biaya.
        if (!Cache::add('passive_tasks_ran_' . $companyId, true, now()->addHour())) {
            return;
        }

        // 1. Auto close shifts older than 12 hours
        Shift::where('company_id', $companyId)
            ->where('status', 'active')
            ->where('start_time', '<', Carbon::now()->subHours(12))
            ->update([
                'status' => 'auto_closed',
                'end_time' => DB::raw('DATE_ADD(start_time, INTERVAL 12 HOUR)') // mock end time
            ]);

        // 2. Delete selfies older than 7 days
        $oldShifts = Shift::where('company_id', $companyId)
            ->whereNotNull('selfie_path')
            ->where('start_time', '<', Carbon::now()->subDays(7))
            ->get();

        foreach ($oldShifts as $s) {
            if ($s->selfie_path && file_exists(public_path($s->selfie_path))) {
                @unlink(public_path($s->selfie_path));
            }
            if ($s->selfie_path && Storage::disk('public')->exists($s->selfie_path)) {
                Storage::disk('public')->delete($s->selfie_path);
            }
            $s->update(['selfie_path' => null]);
        }
    }

    /**
     * List all shifts for owner (Log Shift)
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $this->runPassiveTasks($user->company_id);

        $query = Shift::where('company_id', $user->company_id)
            ->with(['user:id,name', 'branch:id,name', 'orders']);

        if ($request->has('date')) {
            $query->whereDate('start_time', $request->date);
        }
        
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('branch_id') && $request->branch_id && $request->branch_id !== 'all') {
            $query->where('branch_id', $request->branch_id);
        }

        $shifts = $query->orderBy('start_time', 'desc')->get();

        $company = \App\Models\Company::find($user->company_id);
        
        // Calculate revenue breakdown for each shift
        $shifts->transform(function ($shift) use ($company) {
            $orders = $shift->orders->where('status', '!=', 'voided');
            $cashRevenue = (float) $orders->where('payment_method', 'cash')->sum('total_amount');
            $qrisRevenue = (float) $orders->where('payment_method', 'qris')->sum('total_amount');
            $transferRevenue = (float) $orders->where('payment_method', 'transfer')->sum('total_amount');
            $totalRevenue = (float) $orders->sum('total_amount');

            $shift->cash_revenue = $cashRevenue;
            $shift->qris_revenue = $qrisRevenue;
            $shift->transfer_revenue = $transferRevenue;
            $shift->total_revenue = $totalRevenue;
            $shift->expected_cash_balance = (float) $shift->opening_balance + $cashRevenue;
            
            if ($shift->selfie_path) {
                $shift->selfie_url = str_starts_with($shift->selfie_path, 'http') ? $shift->selfie_path : url($shift->selfie_path);
            }
            
            if ($company && $company->require_schedule && $shift->end_time && $company->shift_schedules) {
                $schedules = $company->shift_schedules;
                if (is_array($schedules) && count($schedules) > 0) {
                    $actualStart = \Carbon\Carbon::parse($shift->start_time);
                    $actualEnd = \Carbon\Carbon::parse($shift->end_time);
                    
                    // Find the schedule that minimizes the difference with actual start time
                    $bestSchedule = $schedules[0];
                    $minDiff = PHP_INT_MAX;
                    
                    foreach ($schedules as $schedule) {
                        if (isset($schedule['start'])) {
                            $schedStart = \Carbon\Carbon::parse($actualStart->format('Y-m-d') . ' ' . $schedule['start']);
                            $diff = abs($actualStart->diffInMinutes($schedStart));
                            if ($diff < $minDiff) {
                                $minDiff = $diff;
                                $bestSchedule = $schedule;
                            }
                        }
                    }
                    
                    if (isset($bestSchedule['start']) && isset($bestSchedule['end'])) {
                        $shift->total_work_hours = $actualEnd->diffInMinutes($actualStart) / 60;
                        
                        $schedStart = \Carbon\Carbon::parse($actualStart->format('Y-m-d') . ' ' . $bestSchedule['start']);
                        $schedEnd = \Carbon\Carbon::parse($actualStart->format('Y-m-d') . ' ' . $bestSchedule['end']);
                        
                        // Handle overnight shifts (e.g. 16:00 - 02:00)
                        if ($schedEnd->lessThan($schedStart)) {
                            $schedEnd->addDay();
                        }
                        
                        // Overtime
                        if ($actualEnd->greaterThan($schedEnd)) {
                            $shift->overtime_hours = $actualEnd->diffInMinutes($schedEnd) / 60;
                        } else {
                            $shift->overtime_hours = 0;
                        }
                        
                        // Late
                        $tolerance = $company->late_tolerance_minutes ?? 0;
                        if ($actualStart->greaterThan($schedStart->copy()->addMinutes($tolerance))) {
                            $shift->late_minutes = $actualStart->diffInMinutes($schedStart);
                        } else {
                            $shift->late_minutes = 0;
                        }
                        
                        $shift->shift_name = $bestSchedule['name'] ?? 'Shift';
                    }
                }
            }
            
            return $shift;
        });

        return response()->json([
            'message' => 'Shift logs retrieved',
            'data' => $shifts
        ]);
    }

    /**
     * Get active shift for current user
     */
    public function active(Request $request)
    {
        $this->runPassiveTasks($request->user()->company_id);

        $activeShift = Shift::where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->with('orders')
            ->first();

        if ($activeShift) {
            $orders = $activeShift->orders->where('status', '!=', 'voided');
            $cashRevenue = (float) $orders->where('payment_method', 'cash')->sum('total_amount');
            $qrisRevenue = (float) $orders->where('payment_method', 'qris')->sum('total_amount');
            $transferRevenue = (float) $orders->where('payment_method', 'transfer')->sum('total_amount');
            $totalRevenue = (float) $orders->sum('total_amount');

            $activeShift->cash_revenue = $cashRevenue;
            $activeShift->qris_revenue = $qrisRevenue;
            $activeShift->transfer_revenue = $transferRevenue;
            $activeShift->total_revenue = $totalRevenue;
            $activeShift->expected_cash_balance = (float) $activeShift->opening_balance + $cashRevenue;
        }

        return response()->json([
            'data' => $activeShift
        ]);
    }

    /**
     * Open a new shift
     */
    public function open(Request $request)
    {
        $user = $request->user();
        
        $this->runPassiveTasks($user->company_id);

        // Check if there's already an active shift for this user
        $activeShift = Shift::where('user_id', $user->id)
            ->where('status', 'active')
            ->first();

        if ($activeShift) {
            return response()->json([
                'message' => 'Anda masih memiliki shift yang aktif.',
                'data' => $activeShift
            ], 400);
        }

        $company = $user->company;
        $requireAttendance = $company->require_attendance ?? true;
        $hasPosAccess = $user->role === 'Owner' || $user->hasPermission('can_access_pos');
        $requireCashDrawer = ($company->require_cash_drawer_balance ?? true) && $hasPosAccess;

        $rules = [
            'opening_balance' => $requireCashDrawer ? 'required|numeric|min:0' : 'nullable|numeric|min:0',
        ];

        if ($requireAttendance) {
            $rules['latitude'] = 'nullable|numeric';
            $rules['longitude'] = 'nullable|numeric';
            $rules['selfie'] = 'required|image|max:5120';
        }

        $request->validate($rules);

        $branches = \App\Models\Branch::where('company_id', $company->id)->get();
        $validBranchId = null;

        if ($requireAttendance && $branches->isNotEmpty()) {
            if (!$request->latitude || !$request->longitude) {
                return response()->json(['message' => 'Akses lokasi (GPS) dibutuhkan untuk absensi di toko ini.'], 400);
            }

            $minDistance = PHP_INT_MAX;
            foreach ($branches as $branch) {
                $distance = $this->calculateDistance(
                    $branch->latitude, $branch->longitude,
                    $request->latitude, $request->longitude
                );
                
                if ($distance <= $branch->radius_meters && $distance < $minDistance) {
                    $minDistance = $distance;
                    $validBranchId = $branch->id;
                }
            }

            if (!$validBranchId) {
                return response()->json([
                    'message' => 'Anda berada di luar jangkauan absensi semua cabang toko.'
                ], 403);
            }
        }

        $path = null;
        if ($requireAttendance && $request->hasFile('selfie')) {
            $image = $request->file('selfie');
            $filename = 'selfie_' . $user->id . '_' . time() . '.' . $image->getClientOriginalExtension();
            $path = 'uploads/selfies/' . $filename;
            
            $destinationPath = public_path('uploads/selfies');
            if (!file_exists($destinationPath)) {
                mkdir($destinationPath, 0775, true);
            }
            $image->move($destinationPath, $filename);
        }

        $shift = Shift::create([
            'company_id' => $user->company_id,
            'user_id' => $user->id,
            'branch_id' => $validBranchId,
            'opening_balance' => $request->opening_balance ?? 0,
            'start_time' => \Carbon\Carbon::now(),
            'selfie_path' => $path,
            'status' => 'active',
        ]);

        // Push Notification to Owner
        try {
            $branchName = $shift->branch ? $shift->branch->name : 'Cabang Utama';
            $kasFormatted = 'Rp ' . number_format($shift->opening_balance, 0, ',', '.');
            FirebaseNotificationService::sendToOwner(
                $user->company_id,
                'Shift Baru Dimulai',
                "{$user->name} telah membuka shift di {$branchName}. Kas awal: {$kasFormatted}.",
                'shift',
                ['shift_id' => $shift->id, 'type' => 'shift_open', 'route' => '/shifts']
            );
        } catch (\Exception $e) {
            \Log::warning('Shift open notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'message' => 'Shift berhasil dimulai.',
            'data' => $shift
        ], 201);
    }

    /**
     * Close an active shift (Blind close)
     */
    public function close(Request $request)
    {
        $user = $request->user();
        $company = $user->company;
        $hasPosAccess = $user->role === 'Owner' || $user->hasPermission('can_access_pos');
        $requireCashDrawer = ($company->require_cash_drawer_balance ?? true) && $hasPosAccess;

        $request->validate([
            'shift_id' => 'required|exists:shifts,id',
            'closing_balance' => $requireCashDrawer ? 'required|numeric|min:0' : 'nullable|numeric|min:0',
            'opname_data' => 'nullable|array',
            'opname_data.*.ingredient_id' => 'required_with:opname_data|exists:ingredients,id',
            'opname_data.*.actual_qty' => 'required_with:opname_data|numeric|min:0',
        ]);

        $shift = Shift::where('company_id', $user->company_id)
            ->where('user_id', $user->id)
            ->findOrFail($request->shift_id);

        if ($shift->status !== 'active') {
            return response()->json(['message' => 'Shift ini sudah ditutup.'], 400);
        }

        DB::beginTransaction();
        try {
            $closingBalance = $request->closing_balance;
            if ($closingBalance === null) {
                if ($hasPosAccess) {
                    $cashSales = \App\Models\Order::where('shift_id', $shift->id)->where('status', '!=', 'voided')->where('payment_method', 'cash')->sum('total_amount');
                    $closingBalance = (float) $shift->opening_balance + (float) $cashSales;
                } else {
                    $closingBalance = (float) $shift->opening_balance;
                }
            }

            $shift->update([
                'closing_balance' => $closingBalance,
                'end_time' => Carbon::now(),
                'status' => 'closed',
            ]);

            if ($request->has('opname_data')) {
                $branchId = $shift->branch_id;
                foreach ($request->opname_data as $data) {
                    $ingredient = Ingredient::where('company_id', $request->user()->company_id)
                        ->find($data['ingredient_id']);
                    
                    if ($ingredient) {
                        $systemQty = $branchId ? $ingredient->getStockForBranch($branchId) : $ingredient->stock_qty;
                        $actualQty = (float) $data['actual_qty'];
                        $diff = $actualQty - $systemQty;

                        if ($diff != 0) {
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

                            if ($branchId) {
                                $branchStock = \App\Models\BranchIngredient::firstOrCreate(
                                    ['branch_id' => $branchId, 'ingredient_id' => $ingredient->id],
                                    ['stock_qty' => $ingredient->stock_qty ?? 0, 'min_stock' => $ingredient->min_stock ?? 5]
                                );
                                $branchStock->update(['stock_qty' => $actualQty]);
                            } else {
                                $ingredient->update(['stock_qty' => $actualQty]);
                            }

                            $branch = $branchId ? \App\Models\Branch::find($branchId) : null;
                            $branchSuffix = $branch ? " ({$branch->name})" : '';

                            IngredientHistory::create([
                                'company_id' => $request->user()->company_id,
                                'branch_id' => $branchId,
                                'ingredient_id' => $ingredient->id,
                                'user_id' => $request->user()->id,
                                'type' => 'opname',
                                'qty_change' => $diff,
                                'notes' => 'Opname Akhir Shift' . $branchSuffix,
                                'is_suspicious' => !$isWithinTolerance,
                            ]);
                        }
                    }
                }
            }

            DB::commit();

            // Push Notification to Owner
            try {
                $employeeName = $request->user()->name;
                $kasAkhir = 'Rp ' . number_format($shift->closing_balance ?? 0, 0, ',', '.');
                FirebaseNotificationService::sendToOwner(
                    $request->user()->company_id,
                    'Shift Telah Ditutup',
                    "{$employeeName} telah menutup shift. Saldo kas akhir: {$kasAkhir}.",
                    'shift',
                    ['shift_id' => $shift->id, 'type' => 'shift_close', 'route' => '/shifts']
                );
            } catch (\Exception $e) {
                \Log::warning('Shift close notification failed: ' . $e->getMessage());
            }

            return response()->json([
                'message' => 'Shift berhasil diakhiri.',
                'data' => $shift
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal mengakhiri shift', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Get today's shift summary (Owner only)
     */
    public function summary(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $query = Shift::where('company_id', $user->company_id)
            ->whereDate('start_time', Carbon::today())
            ->with(['user:id,name', 'branch:id,name', 'orders']);

        if ($request->has('branch_id') && $request->branch_id && $request->branch_id !== 'all') {
            $query->where('branch_id', $request->branch_id);
        }

        $shifts = $query->get();

        $summary = $shifts->map(function ($shift) {
            $orders = $shift->orders->where('status', '!=', 'voided');
            $cashRevenue = (float) $orders->where('payment_method', 'cash')->sum('total_amount');
            $qrisRevenue = (float) $orders->where('payment_method', 'qris')->sum('total_amount');
            $transferRevenue = (float) $orders->where('payment_method', 'transfer')->sum('total_amount');
            $totalRevenue = (float) $orders->sum('total_amount');

            return [
                'shift_id' => $shift->id,
                'employee_name' => $shift->user ? $shift->user->name : 'Kasir',
                'branch_name' => $shift->branch ? $shift->branch->name : 'Cabang Utama',
                'branch_id' => $shift->branch_id,
                'status' => $shift->status,
                'start_time' => $shift->start_time ? $shift->start_time->format('H:i') : null,
                'end_time' => $shift->end_time ? $shift->end_time->format('H:i') : null,
                'opening_balance' => (float) $shift->opening_balance,
                'closing_balance' => $shift->closing_balance !== null ? (float) $shift->closing_balance : null,
                'revenue' => $totalRevenue,
                'cash_revenue' => $cashRevenue,
                'qris_revenue' => $qrisRevenue,
                'transfer_revenue' => $transferRevenue,
                'orders_count' => $orders->count(),
                'expected_cash_balance' => (float) $shift->opening_balance + $cashRevenue,
            ];
        });

        return response()->json([
            'message' => 'Ringkasan shift hari ini',
            'data' => $summary,
            'total_revenue' => $summary->sum('revenue')
        ]);
    }
}
