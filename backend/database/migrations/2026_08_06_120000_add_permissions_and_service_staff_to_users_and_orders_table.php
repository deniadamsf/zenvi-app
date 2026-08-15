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
        Schema::table('users', function (Blueprint $table) {
            $table->string('job_title')->nullable()->after('role');
            $table->json('permissions')->nullable()->after('job_title');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('serviced_by_user_id')->nullable()->after('user_id')->constrained('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['serviced_by_user_id']);
            $table->dropColumn('serviced_by_user_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['job_title', 'permissions']);
        });
    }
};
