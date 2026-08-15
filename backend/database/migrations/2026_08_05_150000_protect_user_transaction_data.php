<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Protect transaction data from being cascade-deleted when a user is removed.
 * 
 * Before: DELETE user → all orders, shifts, expenses, histories, messages CASCADE deleted
 * After:  DELETE user → BLOCKED if they have orders/shifts (restrict)
 *         Messages & expenses → user_id set to NULL (preserve data, remove reference)
 *         Soft-delete is the recommended way to "delete" users
 */
return new class extends Migration
{
    public function up(): void
    {
        // 1. orders.user_id: CASCADE → RESTRICT
        // User with orders cannot be hard-deleted
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('restrict');
        });

        // 2. shifts.user_id: CASCADE → RESTRICT  
        // User with shifts cannot be hard-deleted
        Schema::table('shifts', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('restrict');
        });

        // 3. expenses.user_id: CASCADE → SET NULL
        // Expense records preserved, user reference cleared
        Schema::table('expenses', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->unsignedBigInteger('user_id')->nullable()->change();
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('set null');
        });

        // 4. ingredient_histories.user_id: CASCADE → SET NULL
        // History preserved for audit trail
        Schema::table('ingredient_histories', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->unsignedBigInteger('user_id')->nullable()->change();
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('set null');
        });

        // 5. messages.sender_id: CASCADE → SET NULL
        // Chat history preserved
        Schema::table('messages', function (Blueprint $table) {
            $table->dropForeign(['sender_id']);
            $table->unsignedBigInteger('sender_id')->nullable()->change();
            $table->foreign('sender_id')
                ->references('id')->on('users')
                ->onDelete('set null');
        });

        // 6. messages.receiver_id: CASCADE → SET NULL (if FK exists)
        Schema::table('messages', function (Blueprint $table) {
            try {
                $table->dropForeign(['receiver_id']);
            } catch (\Exception $e) {
                // FK might not exist, skip
            }
            $table->unsignedBigInteger('receiver_id')->nullable()->change();
            $table->foreign('receiver_id')
                ->references('id')->on('users')
                ->onDelete('set null');
        });

        // 7. Add soft-delete column to users table
        Schema::table('users', function (Blueprint $table) {
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        // Remove soft-deletes
        Schema::table('users', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });

        // Revert orders FK
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });

        // Revert shifts FK
        Schema::table('shifts', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });

        // Revert expenses FK
        Schema::table('expenses', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->unsignedBigInteger('user_id')->nullable(false)->change();
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });

        // Revert ingredient_histories FK
        Schema::table('ingredient_histories', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->unsignedBigInteger('user_id')->nullable(false)->change();
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });

        // Revert messages sender FK
        Schema::table('messages', function (Blueprint $table) {
            $table->dropForeign(['sender_id']);
            $table->unsignedBigInteger('sender_id')->nullable(false)->change();
            $table->foreign('sender_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });

        // Revert messages receiver FK
        Schema::table('messages', function (Blueprint $table) {
            $table->dropForeign(['receiver_id']);
            $table->foreign('receiver_id')
                ->references('id')->on('users')
                ->onDelete('cascade');
        });
    }
};
