<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Menambah nilai `transfer_out` dan `transfer_in` pada enum
 * `ingredient_histories.type`.
 *
 * Kolomnya dibuat sebagai enum('restock','opname','wastage'), sehingga menulis
 * jenis baru ditolak MySQL dengan "Data truncated for column 'type'" - error yang
 * muncul saat runtime, bukan saat kode ditulis.
 *
 * Dijalankan lewat SQL mentah karena Doctrine DBAL tidak menangani perubahan enum
 * dengan andal, dan menambah paket itu hanya untuk satu ALTER tidak sepadan.
 * Idempoten: kalau nilainya sudah ada, migration dilewati.
 */
return new class extends Migration
{
    private const TYPES_BARU = "'restock','opname','wastage','transfer_out','transfer_in'";
    private const TYPES_LAMA = "'restock','opname','wastage'";

    public function up(): void
    {
        if (!Schema::hasTable('ingredient_histories')) {
            return;
        }

        $column = DB::selectOne("SHOW COLUMNS FROM ingredient_histories WHERE Field = 'type'");
        if ($column && str_contains($column->Type, 'transfer_out')) {
            return;
        }

        DB::statement(
            'ALTER TABLE ingredient_histories MODIFY COLUMN type ENUM(' . self::TYPES_BARU . ') NOT NULL'
        );
    }

    public function down(): void
    {
        if (!Schema::hasTable('ingredient_histories')) {
            return;
        }

        // Baris transfer harus dibuang lebih dulu, kalau tidak MySQL menolak
        // menyempitkan enum yang masih menyimpan nilai tersebut.
        DB::table('ingredient_histories')
            ->whereIn('type', ['transfer_out', 'transfer_in'])
            ->delete();

        DB::statement(
            'ALTER TABLE ingredient_histories MODIFY COLUMN type ENUM(' . self::TYPES_LAMA . ') NOT NULL'
        );
    }
};
