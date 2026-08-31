<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Status langganan disimpan sebagai kolom di `companies`, bukan tabel terpisah.
 *
 * Alasannya: `AuthController@me` sudah mengembalikan `$user->load('company')`,
 * sehingga status paket otomatis terbawa ke aplikasi di setiap pemuatan profil -
 * tanpa join, tanpa query tambahan, dan tanpa endpoint baru.
 *
 * Migration ini sekaligus MENANDAI SELURUH TOKO YANG SUDAH ADA sebagai founding
 * member: paket Bisnis dengan `plan_expires_at = NULL` (tanpa kedaluwarsa).
 * Momen migration dijalankan di produksi ITULAH tanggal cutoff grandfathering -
 * lebih tepat daripada tanggal yang di-hardcode, yang selalu meleset dari waktu
 * deploy sebenarnya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->string('plan_code', 32)->default('free')->after('default_language');
            // trialing | active | grace | expired
            $table->string('plan_status', 16)->default('active')->after('plan_code');
            // NULL = tanpa kedaluwarsa (founding member / grandfathered)
            $table->timestamp('plan_expires_at')->nullable()->after('plan_status');
            $table->boolean('is_founding_member')->default(false)->after('plan_expires_at');

            $table->index(['plan_status', 'plan_expires_at'], 'companies_plan_status_expires_idx');
        });

        // Grandfather permanen untuk semua toko yang terdaftar sebelum fitur ini hidup.
        DB::table('companies')->update([
            'plan_code'          => 'business',
            'plan_status'        => 'active',
            'plan_expires_at'    => null,
            'is_founding_member' => true,
        ]);
    }

    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropIndex('companies_plan_status_expires_idx');
            $table->dropColumn([
                'plan_code',
                'plan_status',
                'plan_expires_at',
                'is_founding_member',
            ]);
        });
    }
};
