<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->string('kds_status')->default('pending')->after('subtotal');
        });

        // Sync existing order_items with their parent order's kds_status if orders table exists
        if (Schema::hasColumn('orders', 'kds_status')) {
            DB::statement("
                UPDATE order_items
                INNER JOIN orders ON orders.id = order_items.order_id
                SET order_items.kds_status = orders.kds_status
                WHERE orders.kds_status IS NOT NULL
            ");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->dropColumn('kds_status');
        });
    }
};
