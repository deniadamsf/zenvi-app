<?php

namespace App\Http\Middleware;

use App\Support\Entitlements;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Menolak pembuatan data baru kalau kuota paket sudah penuh.
 *
 * Dipakai: ->middleware('plan.limit:products')
 *
 * Sengaja hanya dipasang di route pembuatan (store), bukan di seluruh resource:
 * toko yang turun paket tetap boleh melihat dan mengubah data yang sudah ada.
 * Membatasi baca akan membuat data mereka seolah hilang, dan itu alasan sah
 * untuk berhenti memakai aplikasi.
 */
class EnsurePlanLimit
{
    public function handle(Request $request, Closure $next, string $limitKey): Response
    {
        $entitlements = Entitlements::for($request->user()?->company);

        if ($entitlements->canAdd($limitKey)) {
            return $next($request);
        }

        $max = $entitlements->limit($limitKey);

        return response()->json([
            'error'         => 'plan_limit_reached',
            'limit'         => $limitKey,
            'current'       => $entitlements->usage($limitKey),
            'max'           => $max,
            'required_plan' => Entitlements::planRequiredForLimit($limitKey, $max),
            'current_plan'  => $entitlements->planCode(),
            'message'       => "Batas paket Anda sudah tercapai ({$max}). Tingkatkan paket untuk menambah lagi.",
        ], 403);
    }
}
