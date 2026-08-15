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
        Schema::create('employee_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['leave', 'late'])->default('leave'); // leave = izin libur/cuti/sakit, late = izin telat masuk
            $table->date('permission_date');
            $table->time('estimated_arrival_time')->nullable(); // jam perkiraan tiba jika izin telat
            $table->text('reason');
            $table->string('attachment_path')->nullable(); // path file bukti foto
            $table->timestamp('attachment_deleted_at')->nullable(); // waktu ketika file bukti otomatis dihapus (setelah 3 hari)
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('reviewed_at')->nullable();
            $table->string('rejection_note')->nullable();
            $table->timestamps();

            $table->index(['company_id', 'permission_date']);
            $table->index(['user_id', 'permission_date']);
            $table->index(['status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('employee_permissions');
    }
};
