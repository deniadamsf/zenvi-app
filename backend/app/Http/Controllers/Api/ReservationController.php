<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reservation;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ReservationController extends Controller
{
    /**
     * Display a listing of the reservations for the authenticated company.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->company_id) {
            return response()->json(['message' => 'User does not belong to any company'], 403);
        }

        $query = Reservation::where('company_id', $user->company_id)
            ->with(['branch', 'creator:id,name,role']);

        // Filter by branch if user is assigned to a branch or specific filter
        if ($user->branch_id) {
            $query->where(function ($q) use ($user) {
                $q->where('branch_id', $user->branch_id)
                  ->orWhereNull('branch_id');
            });
        } elseif ($request->filled('branch_id')) {
            $query->where('branch_id', $request->branch_id);
        }

        // Filter by date
        if ($request->filled('date')) {
            $dateParam = $request->date;
            if ($dateParam === 'today') {
                $query->whereDate('reservation_date', Carbon::today());
            } elseif ($dateParam === 'upcoming') {
                $query->whereDate('reservation_date', '>=', Carbon::today());
            } elseif ($dateParam === 'past') {
                $query->whereDate('reservation_date', '<', Carbon::today());
            } else {
                $query->whereDate('reservation_date', $dateParam);
            }
        }

        // Filter by status
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        // Search by customer name or phone
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('customer_name', 'like', "%{$search}%")
                  ->orWhere('customer_phone', 'like', "%{$search}%")
                  ->orWhere('service_names', 'like', "%{$search}%");
            });
        }

        $reservations = $query->orderBy('reservation_date', 'asc')
            ->orderBy('reservation_time', 'asc')
            ->get();

        return response()->json([
            'data' => $reservations
        ]);
    }

    /**
     * Store a newly created reservation (e.g. from cashier/owner manual entry).
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user->company_id) {
            return response()->json(['message' => 'User does not belong to any company'], 403);
        }

        $validated = $request->validate([
            'customer_name' => 'required|string|max:255',
            'customer_phone' => 'required|string|max:50',
            'reservation_date' => 'required|date_format:Y-m-d',
            'reservation_time' => 'required|string|max:10',
            'number_of_people' => 'nullable|integer|min:1',
            'service_names' => 'nullable|string',
            'notes' => 'nullable|string',
            'branch_id' => 'nullable|integer',
            'status' => 'nullable|in:pending,confirmed,completed,cancelled',
        ]);

        $reservation = Reservation::create([
            'company_id' => $user->company_id,
            'branch_id' => $validated['branch_id'] ?? $user->branch_id,
            'customer_name' => $validated['customer_name'],
            'customer_phone' => $validated['customer_phone'],
            'reservation_date' => $validated['reservation_date'],
            'reservation_time' => $validated['reservation_time'],
            'number_of_people' => $validated['number_of_people'] ?? 1,
            'service_names' => $validated['service_names'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'status' => $validated['status'] ?? 'confirmed', // manual entry by cashier is usually confirmed
            'created_by_user_id' => $user->id,
        ]);

        // Push Notification to Company (exclude creator)
        try {
            $tgl = Carbon::parse($reservation->reservation_date)->format('d M Y');
            $time = substr($reservation->reservation_time, 0, 5);
            $people = $reservation->number_of_people ?? 1;
            FirebaseNotificationService::sendToCompany(
                $user->company_id,
                'Reservasi Ditambahkan 📅',
                "Reservasi {$reservation->customer_name} ({$tgl} {$time}, {$people} org) dicatat oleh {$user->name}.",
                'reservation',
                ['reservation_id' => $reservation->id, 'type' => 'reservation_created', 'route' => '/reservations'],
                $user->id
            );
        } catch (\Exception $e) {
            \Log::warning('Reservation store notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'message' => 'Reservasi berhasil dibuat',
            'data' => $reservation->load(['branch', 'creator:id,name,role'])
        ], 201);
    }

    /**
     * Display the specified reservation.
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $reservation = Reservation::where('company_id', $user->company_id)
            ->with(['branch', 'creator:id,name,role'])
            ->findOrFail($id);

        return response()->json(['data' => $reservation]);
    }

    /**
     * Update the specified reservation.
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();
        $reservation = Reservation::where('company_id', $user->company_id)->findOrFail($id);

        $validated = $request->validate([
            'customer_name' => 'sometimes|string|max:255',
            'customer_phone' => 'sometimes|string|max:50',
            'reservation_date' => 'sometimes|date_format:Y-m-d',
            'reservation_time' => 'sometimes|string|max:10',
            'number_of_people' => 'sometimes|integer|min:1',
            'service_names' => 'sometimes|nullable|string',
            'notes' => 'sometimes|nullable|string',
            'branch_id' => 'sometimes|nullable|integer',
            'status' => 'sometimes|in:pending,confirmed,completed,cancelled',
        ]);

        $reservation->update($validated);

        return response()->json([
            'message' => 'Reservasi berhasil diperbarui',
            'data' => $reservation->load(['branch', 'creator:id,name,role'])
        ]);
    }

    /**
     * Update status of reservation (quick action from UI).
     */
    public function updateStatus(Request $request, $id)
    {
        $user = $request->user();
        $reservation = Reservation::where('company_id', $user->company_id)->findOrFail($id);

        $validated = $request->validate([
            'status' => 'required|in:pending,confirmed,completed,cancelled'
        ]);

        $reservation->update([
            'status' => $validated['status']
        ]);

        // Push Notification to Company (exclude current user)
        try {
            $statusLabels = [
                'pending' => 'Menunggu Konfirmasi',
                'confirmed' => 'Dikonfirmasi',
                'completed' => 'Selesai',
                'cancelled' => 'Dibatalkan',
            ];
            $statusStr = $statusLabels[$reservation->status] ?? $reservation->status;
            FirebaseNotificationService::sendToCompany(
                $user->company_id,
                'Status Reservasi Diperbarui 🔔',
                "Reservasi {$reservation->customer_name} diubah menjadi: {$statusStr}.",
                'reservation',
                ['reservation_id' => $reservation->id, 'type' => 'reservation_status_updated', 'route' => '/reservations'],
                $user->id
            );
        } catch (\Exception $e) {
            \Log::warning('Reservation status notification failed: ' . $e->getMessage());
        }

        return response()->json([
            'message' => 'Status reservasi berhasil diubah',
            'data' => $reservation->load(['branch', 'creator:id,name,role'])
        ]);
    }

    /**
     * Remove the specified reservation.
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $reservation = Reservation::where('company_id', $user->company_id)->findOrFail($id);
        $reservation->delete();

        return response()->json([
            'message' => 'Reservasi berhasil dihapus'
        ]);
    }
}
