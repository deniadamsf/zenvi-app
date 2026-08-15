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
            if (!Schema::hasColumn('companies', 'require_cash_drawer_balance')) {
                $table->boolean('require_cash_drawer_balance')->default(true)->after('require_opname_on_shift_close');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            if (Schema::hasColumn('companies', 'require_cash_drawer_balance')) {
                $table->dropColumn('require_cash_drawer_balance');
            }
        });
    }
};
