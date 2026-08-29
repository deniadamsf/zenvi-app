<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Menambah index gabungan yang cocok dengan pola filter+urut yang benar-benar
 * dipakai endpoint terpanas.
 *
 * `foreignId()->constrained()` sudah membuat index satu kolom untuk company_id,
 * tapi index itu melemah begitu satu perusahaan punya ratusan ribu baris:
 * MySQL masih harus memindai & mengurutkan seluruh baris milik perusahaan itu.
 * Index gabungan di bawah dipilih dari query nyata, bukan menebak:
 *
 *  - orders(company_id, created_at)   -> ExpenseController::financialReport
 *                                        (jalan tiap dashboard dibuka) &
 *                                        OrderController::index whereDate
 *  - orders(company_id, status)       -> OrderController::getKdsOrders
 *  - shifts(company_id, start_time)   -> ShiftController::index (orderBy desc)
 *  - ingredient_histories(company_id, created_at) -> StockManagementController::history
 *  - messages(company_id, created_at) -> MessageController::index
 *
 * Tidak ada perubahan skema kolom, jadi bentuk respons API tetap sama persis
 * dan aplikasi yang sudah beredar di Play Store tidak terpengaruh.
 */
return new class extends Migration
{
    /**
     * Daftar index yang dibuat: [tabel, [kolom...], nama index].
     */
    private array $indexes = [
        ['orders', ['company_id', 'created_at'], 'orders_company_created_idx'],
        ['orders', ['company_id', 'status'], 'orders_company_status_idx'],
        ['shifts', ['company_id', 'start_time'], 'shifts_company_start_idx'],
        ['ingredient_histories', ['company_id', 'created_at'], 'ing_hist_company_created_idx'],
        ['messages', ['company_id', 'created_at'], 'messages_company_created_idx'],
    ];

    public function up(): void
    {
        foreach ($this->indexes as [$table, $columns, $name]) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            // Lewati kalau ada kolom yang tidak ada di skema saat ini.
            foreach ($columns as $column) {
                if (!Schema::hasColumn($table, $column)) {
                    continue 2;
                }
            }

            if ($this->indexExists($table, $name)) {
                continue;
            }

            Schema::table($table, function ($blueprint) use ($columns, $name) {
                $blueprint->index($columns, $name);
            });
        }
    }

    public function down(): void
    {
        foreach ($this->indexes as [$table, $columns, $name]) {
            if (!Schema::hasTable($table) || !$this->indexExists($table, $name)) {
                continue;
            }

            Schema::table($table, function ($blueprint) use ($name) {
                $blueprint->dropIndex($name);
            });
        }
    }

    /**
     * Dicek lewat information_schema karena Laravel 10 belum punya
     * Schema::hasIndex(). Membuat migration ini aman dijalankan berulang.
     */
    private function indexExists(string $table, string $name): bool
    {
        $found = DB::selectOne(
            'SELECT 1 AS found FROM information_schema.statistics
             WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?
             LIMIT 1',
            [$table, $name]
        );

        return $found !== null;
    }
};
