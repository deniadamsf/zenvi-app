<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->onDelete('cascade');
            $table->string('member_code', 50);
            $table->string('name');
            $table->string('phone', 50)->index();
            $table->string('email')->nullable();
            $table->text('address')->nullable();
            $table->date('birth_date')->nullable();
            $table->integer('points')->default(0);
            $table->decimal('total_spend', 15, 2)->default(0);
            $table->integer('total_transactions')->default(0);
            $table->decimal('custom_discount_percent', 5, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['company_id', 'member_code']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('members');
    }
};
