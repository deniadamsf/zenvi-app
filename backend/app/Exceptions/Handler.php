<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Route;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    /**
     * Balas 401 JSON untuk request yang tidak terautentikasi.
     *
     * Perilaku bawaan Laravel adalah redirect ke route('login') kalau request
     * tidak mengirim Accept: application/json. Aplikasi ini API-only dan tidak
     * punya route bernama 'login', sehingga fallback itu melempar
     * RouteNotFoundException dan balasannya jadi 500, bukan 401.
     */
    protected function unauthenticated($request, AuthenticationException $exception)
    {
        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json(['message' => $exception->getMessage()], 401);
        }

        return Route::has('login')
            ? redirect()->guest(route('login'))
            : response()->json(['message' => $exception->getMessage()], 401);
    }
}
