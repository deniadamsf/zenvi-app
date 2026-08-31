<?php

namespace App\Http\Middleware;

use App\Support\Entitlements;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Mengunci sebuah route kalau paket toko tidak mencakup fiturnya.
 *
 * Dipakai: ->middleware('feature:kds')
 *
 * Ini penegakan yang sebenarnya. Toggle fitur di aplikasi Flutter murni untuk
 * tampilan - sebelum middleware ini ada, siapa pun yang memegang token bisa
 * memanggil endpoint fitur berbayar walau paketnya gratis.
 */
class EnsureFeatureEnabled
{
    public function handle(Request $request, Closure $next, string $feature): Response
    {
        $entitlements = Entitlements::for($request->user()?->company);

        if ($entitlements->hasFeature($feature)) {
            return $next($request);
        }

        $featureLabel = config('plans.features.' . $feature, $feature);

        // 403 dengan body bertipe, bukan 402: secara semantik 402 Payment Required
        // memang lebih tepat, tapi sebagian proxy dan klien HTTP menanganinya
        // dengan tidak konsisten. Field `error` yang eksplisit tidak pernah ambigu.
        return response()->json([
            'error'         => 'feature_locked',
            'feature'       => $feature,
            'required_plan' => Entitlements::planRequiredFor($feature),
            'current_plan'  => $entitlements->planCode(),
            'message'       => "Fitur {$featureLabel} tidak tersedia di paket Anda saat ini.",
        ], 403);
    }
}
