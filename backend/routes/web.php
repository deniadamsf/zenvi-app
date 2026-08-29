<?php

use App\Http\Controllers\PublicMenuController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

Route::view('/', 'welcome');

// Privacy Policy & Google Play Compliance Routes
Route::view('/privacy-policy', 'privacy_policy')->name('privacy.policy');

Route::view('/kebijakan-privasi', 'privacy_policy')->name('privacy.policy.id');

Route::view('/privacy', 'privacy_policy');

Route::view('/delete-account', 'privacy_policy')->name('account.deletion');

Route::view('/hapus-akun', 'privacy_policy');

// Fallback when APP_URL contains /api prefix
Route::view('/api/privacy-policy', 'privacy_policy');
Route::view('/api/kebijakan-privasi', 'privacy_policy');
Route::view('/api/delete-account', 'privacy_policy');

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

// Disclaimer / Penafian Routes
Route::view('/disclaimer', 'disclaimer')->name('disclaimer');

Route::view('/penafian', 'disclaimer');

Route::view('/api/disclaimer', 'disclaimer');

// Store Portal Landing Page (e.g. zenvi.cellanoma.my.id/toko-kopi)
Route::get('/{slug}', [PublicMenuController::class, 'show'])->where('slug', '^(?!api|storage|build|css|js|images|vendor|privacy-policy|kebijakan-privasi|privacy|delete-account|hapus-akun|disclaimer|penafian|favicon\.ico|robots\.txt).*$')->name('public.store');


