<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('member_id')->nullable()->after('serviced_by_user_id')->constrained('members')->nullOnDelete();
            $table->string('member_name')->nullable()->after('member_id');
            $table->string('member_phone')->nullable()->after('member_name');
            $table->decimal('member_discount_amount', 15, 2)->default(0)->after('cash_change');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['member_id']);
            $table->dropColumn(['member_id', 'member_name', 'member_phone', 'member_discount_amount']);
        });
    }
};
