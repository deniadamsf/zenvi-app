<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BranchController;
use App\Http\Controllers\Api\CompanyController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\StockManagementController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\EmployeePerformanceController;
use App\Http\Controllers\Api\EmployeePermissionController;
use App\Http\Controllers\Api\ReservationController;
use App\Http\Controllers\Api\MemberController;
use App\Http\Controllers\Api\MemberPromoController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\PublicMenuController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Routes
Route::post('/auth/google', [AuthController::class, 'googleLogin']);
Route::post('/public/reservations/{slug}', [PublicMenuController::class, 'submitReservation']);
Route::post('/public/members/{slug}', [PublicMenuController::class, 'registerMember']);
Route::get('/public/members/{slug}/check', [PublicMenuController::class, 'checkMember']);
Route::get('/branches/public/{companyId}', [BranchController::class, 'publicList']);

// Protected Routes (Require valid Sanctum Token)
Route::middleware('auth:sanctum')->group(function () {
    // Auth & User Profile APIs
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Company & Store Settings APIs
    Route::get('/companies/public', [CompanyController::class, 'publicList']);
    Route::get('/companies/lookup', [CompanyController::class, 'lookupByCode']);
    Route::get('/companies/my', [CompanyController::class, 'index']);
    Route::post('/companies', [CompanyController::class, 'store']);
    Route::post('/companies/join', [CompanyController::class, 'join']);
    Route::post('/companies/cancel-join', [CompanyController::class, 'cancelJoin']);
    Route::post('/companies/location', [CompanyController::class, 'updateLocation']);
    Route::post('/companies/settings', [CompanyController::class, 'updateSettings']);
    Route::post('/companies/logo', [CompanyController::class, 'uploadLogo']);
    Route::get('/companies/employees/pending', [CompanyController::class, 'pendingEmployees']);
    Route::get('/companies/employees/active', [CompanyController::class, 'activeEmployees']);
    Route::post('/companies/employees/{id}/approve', [CompanyController::class, 'approveEmployee']);
    Route::post('/companies/employees/{id}/permissions', [CompanyController::class, 'updateEmployeePermissions']);
    Route::delete('/companies/employees/{id}', [CompanyController::class, 'removeEmployee']);

    // Branch APIs
    Route::apiResource('branches', BranchController::class);

    // Master Data APIs
    Route::apiResource('ingredients', IngredientController::class);
    Route::apiResource('products', ProductController::class);
    Route::post('/products/{id}/image', [ProductController::class, 'uploadImage']);

    // Membership & Promo Member APIs
    Route::apiResource('members', MemberController::class);
    Route::apiResource('member-promos', MemberPromoController::class);

    // Shift APIs
    Route::get('/shifts', [ShiftController::class, 'index']);
    Route::get('/shifts/active', [ShiftController::class, 'active']);
    Route::get('/shifts/summary', [ShiftController::class, 'summary']);
    Route::post('/shifts/open', [ShiftController::class, 'open']);
    Route::post('/shifts/close', [ShiftController::class, 'close']);

    // Order (Sync) APIs
    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/kds', [OrderController::class, 'getKdsOrders']);
    Route::patch('/orders/{id}/kds-status', [OrderController::class, 'updateKdsStatus']);
    Route::patch('/orders/{orderId}/items/{itemId}/kds-status', [OrderController::class, 'updateItemKdsStatus']);
    Route::post('/orders/sync', [OrderController::class, 'sync']);
    Route::post('/orders/{id}/void', [OrderController::class, 'voidOrder']);

    // Stock Management APIs (Owner Only)
    Route::get('/stock/history', [StockManagementController::class, 'history']);
    Route::post('/stock/restock', [StockManagementController::class, 'restock']);
    Route::post('/stock/wastage', [StockManagementController::class, 'wastage']);
    Route::post('/stock/opname', [StockManagementController::class, 'opname']);

    // Expense & Financial APIs
    Route::apiResource('expenses', ExpenseController::class)->only(['index', 'store']);
    Route::get('/reports/financial', [ExpenseController::class, 'financialReport']);
    Route::get('/reports/employee-performance', [EmployeePerformanceController::class, 'index']);

    // Employee Permissions (Izin Libur & Telat Masuk)
    Route::get('/permissions', [EmployeePermissionController::class, 'index']);
    Route::post('/permissions', [EmployeePermissionController::class, 'store']);
    Route::post('/permissions/{id}/approve', [EmployeePermissionController::class, 'approve']);
    Route::post('/permissions/{id}/reject', [EmployeePermissionController::class, 'reject']);
    Route::delete('/permissions/{id}', [EmployeePermissionController::class, 'destroy']);

    // Chat API
    Route::get('/chat', [MessageController::class, 'index']);
    Route::post('/chat', [MessageController::class, 'store']);

    // Reservation APIs (Salon & Table Booking)
    Route::apiResource('reservations', ReservationController::class);
    Route::patch('/reservations/{id}/status', [ReservationController::class, 'updateStatus']);

    // Notifications & Device Tokens
    Route::post('/user/fcm-token', [NotificationController::class, 'storeToken']);
    Route::post('/user/fcm-token/remove', [NotificationController::class, 'removeToken']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
});
