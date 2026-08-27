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

// Privacy Policy & Google Play Compliance Routes
Route::get('/privacy-policy', function () {
    return view('privacy_policy');
})->name('privacy.policy');

Route::get('/kebijakan-privasi', function () {
    return view('privacy_policy');
})->name('privacy.policy.id');

Route::get('/privacy', function () {
    return view('privacy_policy');
});

Route::get('/delete-account', function () {
    return view('privacy_policy');
})->name('account.deletion');

Route::get('/hapus-akun', function () {
    return view('privacy_policy');
});

// Fallback when APP_URL contains /api prefix
Route::get('/api/privacy-policy', function () {
    return view('privacy_policy');
});
Route::get('/api/kebijakan-privasi', function () {
    return view('privacy_policy');
});
Route::get('/api/delete-account', function () {
    return view('privacy_policy');
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
Route::get('/{slug}', [PublicMenuController::class, 'show'])->where('slug', '^(?!api|storage|build|css|js|images|vendor|privacy-policy|kebijakan-privasi|privacy|delete-account|hapus-akun|favicon\.ico|robots\.txt).*$')->name('public.store');


