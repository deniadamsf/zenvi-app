<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     *
     * Route API tidak pernah di-redirect: kembalikan null supaya Laravel membalas
     * 401 JSON. Sebelumnya request tanpa header Accept: application/json memicu
     * route('login') yang tidak ada, sehingga balasannya 500, bukan 401.
     */
    protected function redirectTo(Request $request): ?string
    {
        if ($request->expectsJson() || $request->is('api/*')) {
            return null;
        }

        return Route::has('login') ? route('login') : '/';
    }
}
