<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Catatan setiap pembelian langganan yang sudah diverifikasi ke Google.
 *
 * Idempotensi bertumpu pada `token_hash` yang UNIQUE. Google mengirim
 * purchaseToken yang sama berulang kali - saat restore, pasang ulang, ganti
 * perangkat, dan setiap sinkronisasi harian. Tanpa kolom unik ini, setiap
 * pengiriman ulang tercatat sebagai pembelian baru dan paket bisa diperpanjang
 * berkali-kali dari satu pembayaran.
 *
 * Yang di-index adalah SHA-256 dari token, bukan tokennya sendiri: panjang
 * purchaseToken tidak dijamin Google, sementara kunci unik InnoDB dibatasi 3072
 * byte. Hash 64 karakter selalu muat, apa pun panjang tokennya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->string('product_id', 64);
            $table->char('token_hash', 64)->unique();
            $table->text('purchase_token');
            $table->string('order_id', 128)->nullable();
            $table->string('plan_code', 32);
            // active | grace | expired
            $table->string('status', 16)->default('active');
            $table->timestamp('expiry_time')->nullable();
            $table->timestamp('verified_at')->nullable();
            // Balasan mentah Google, disimpan untuk penelusuran sengketa.
            $table->json('raw_payload')->nullable();
            $table->timestamps();

            $table->index(['company_id', 'status']);
            $table->index('expiry_time');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_purchases');
    }
};
