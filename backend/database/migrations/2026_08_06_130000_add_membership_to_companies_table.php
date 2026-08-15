<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->boolean('is_membership_enabled')->default(false)->after('is_reservation_enabled');
            $table->decimal('default_member_discount_percent', 5, 2)->default(0.00)->after('is_membership_enabled');
        });
    }

    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['is_membership_enabled', 'default_member_discount_percent']);
        });
    }
};
