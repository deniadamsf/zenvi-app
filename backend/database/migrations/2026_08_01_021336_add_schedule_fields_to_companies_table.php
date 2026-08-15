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
            $table->boolean('require_schedule')->default(false);
            $table->integer('late_tolerance_minutes')->default(0);
            $table->text('shift_schedules')->nullable(); // Store array of multiple shifts as JSON
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['require_schedule', 'late_tolerance_minutes', 'shift_schedules']);
        });
    }
};
