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
        Schema::table('ingredients', function (Blueprint $table) {
            if (!Schema::hasColumn('ingredients', 'cost_per_unit')) {
                $table->decimal('cost_per_unit', 15, 2)->default(0)->after('stock_qty');
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'cost_price')) {
                $table->decimal('cost_price', 15, 2)->default(0)->after('price');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ingredients', function (Blueprint $table) {
            if (Schema::hasColumn('ingredients', 'cost_per_unit')) {
                $table->dropColumn('cost_per_unit');
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'cost_price')) {
                $table->dropColumn('cost_price');
            }
        });
    }
};
