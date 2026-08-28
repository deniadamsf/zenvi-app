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
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'client_order_id')) {
                $table->string('client_order_id', 64)->nullable()->after('company_id');
                $table->unique(['company_id', 'client_order_id'], 'orders_company_client_order_unique');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'client_order_id')) {
                $table->dropUnique('orders_company_client_order_unique');
                $table->dropColumn('client_order_id');
            }
        });
    }
};
