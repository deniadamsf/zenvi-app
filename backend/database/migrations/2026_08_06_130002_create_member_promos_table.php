<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_promos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->onDelete('cascade');
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('discount_type', ['percent', 'nominal', 'fixed_price'])->default('percent');
            $table->decimal('discount_value', 15, 2)->default(0);
            $table->decimal('min_purchase', 15, 2)->default(0);
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('member_promo_products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_promo_id')->constrained('member_promos')->onDelete('cascade');
            $table->foreignId('product_id')->constrained('products')->onDelete('cascade');
            $table->timestamps();

            $table->unique(['member_promo_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_promo_products');
        Schema::dropIfExists('member_promos');
    }
};
