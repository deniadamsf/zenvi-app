<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->boolean('is_qris_enabled')->default(true)->after('require_schedule');
            $table->boolean('is_transfer_enabled')->default(true)->after('is_qris_enabled');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->string('payment_method')->default('cash')->after('total_amount'); // 'cash', 'qris', 'transfer'
            $table->decimal('cash_received', 12, 2)->nullable()->after('payment_method');
            $table->decimal('cash_change', 12, 2)->nullable()->after('cash_received');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['is_qris_enabled', 'is_transfer_enabled']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['payment_method', 'cash_received', 'cash_change']);
        });
    }
};
