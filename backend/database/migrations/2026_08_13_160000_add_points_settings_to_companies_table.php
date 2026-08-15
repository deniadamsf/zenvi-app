<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->boolean('is_points_enabled')->default(true)->after('default_member_discount_percent');
            $table->decimal('point_earning_amount', 12, 2)->default(1000.00)->after('is_points_enabled');
        });
    }

    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['is_points_enabled', 'point_earning_amount']);
        });
    }
};
