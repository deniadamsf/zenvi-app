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
            if (!Schema::hasColumn('companies', 'point_redeem_rate')) {
                $table->decimal('point_redeem_rate', 12, 2)->default(1.00)->after('point_earning_amount');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'points_redeemed')) {
                $table->integer('points_redeemed')->default(0)->after('member_discount_amount');
            }
            if (!Schema::hasColumn('orders', 'point_redeem_amount')) {
                $table->decimal('point_redeem_amount', 12, 2)->default(0.00)->after('points_redeemed');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            if (Schema::hasColumn('companies', 'point_redeem_rate')) {
                $table->dropColumn('point_redeem_rate');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'points_redeemed')) {
                $table->dropColumn('points_redeemed');
            }
            if (Schema::hasColumn('orders', 'point_redeem_amount')) {
                $table->dropColumn('point_redeem_amount');
            }
        });
    }
};
