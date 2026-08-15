<?php

use App\Http\Controllers\PublicMenuController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return view('welcome');
});

// Public Digital Menu, Member & Store Portal Routes
Route::get('/menu/{slug}', [PublicMenuController::class, 'show'])->name('public.menu');
Route::get('/menu/{slug}/json', [PublicMenuController::class, 'apiMenu'])->name('public.menu.json');
Route::post('/public/reservations/{slug}', [PublicMenuController::class, 'submitReservation'])->name('public.reservation.submit');
Route::post('/public/members/{slug}', [PublicMenuController::class, 'registerMember'])->name('public.member.register');
Route::get('/public/members/{slug}/check', [PublicMenuController::class, 'checkMember'])->name('public.member.check');

// Support fallback when APP_URL contains /api
Route::post('/api/public/reservations/{slug}', [PublicMenuController::class, 'submitReservation']);
Route::post('/api/public/members/{slug}', [PublicMenuController::class, 'registerMember']);
Route::get('/api/public/members/{slug}/check', [PublicMenuController::class, 'checkMember']);

// Store Portal Landing Page (e.g. zenvi.cellanoma.my.id/toko-kopi)
Route::get('/{slug}', [PublicMenuController::class, 'show'])->where('slug', '^(?!api|storage|build|css|js|images|vendor|favicon\.ico|robots\.txt).*$')->name('public.store');


