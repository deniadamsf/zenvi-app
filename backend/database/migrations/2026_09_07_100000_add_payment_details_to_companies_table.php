<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Detail pembayaran non-tunai yang harus dilihat kasir.
 *
 * Sebelumnya QRIS & transfer hanya berupa sakelar nyala/mati, jadi kasir tidak
 * punya apa pun untuk ditunjukkan ke pelanggan: tidak ada kode QR yang bisa
 * dipindai, tidak ada nomor rekening yang bisa dibacakan. Kolom di bawah ini
 * yang mengisinya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->string('qris_image_path')->nullable()->after('is_transfer_enabled');
            $table->string('qris_merchant_name')->nullable()->after('qris_image_path');
            // Daftar rekening, bukan satu kolom nomor: banyak toko memegang
            // lebih dari satu bank dan memilih sesuai bank pelanggan.
            $table->json('bank_accounts')->nullable()->after('qris_merchant_name');
        });
    }

    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['qris_image_path', 'qris_merchant_name', 'bank_accounts']);
        });
    }
};
