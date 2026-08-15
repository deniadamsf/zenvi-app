<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Create branch_ingredients table
        if (!Schema::hasTable('branch_ingredients')) {
            Schema::create('branch_ingredients', function (Blueprint $table) {
                $table->id();
                $table->foreignId('branch_id')->constrained('branches')->onDelete('cascade');
                $table->foreignId('ingredient_id')->constrained('ingredients')->onDelete('cascade');
                $table->decimal('stock_qty', 10, 2)->default(0);
                $table->decimal('min_stock', 10, 2)->default(5);
                $table->timestamps();

                $table->unique(['branch_id', 'ingredient_id']);
            });
        }

        // 2. Add branch_id to ingredient_histories table if not present
        if (Schema::hasTable('ingredient_histories') && !Schema::hasColumn('ingredient_histories', 'branch_id')) {
            Schema::table('ingredient_histories', function (Blueprint $table) {
                $table->foreignId('branch_id')->nullable()->after('ingredient_id')->constrained('branches')->nullOnDelete();
            });
        }

        // 3. Populate initial branch_ingredients for existing data
        try {
            $branches = DB::table('branches')->get();
            $now = now();
            foreach ($branches as $branch) {
                $ingredients = DB::table('ingredients')->where('company_id', $branch->company_id)->get();
                foreach ($ingredients as $ing) {
                    $exists = DB::table('branch_ingredients')
                        ->where('branch_id', $branch->id)
                        ->where('ingredient_id', $ing->id)
                        ->exists();

                    if (!$exists) {
                        DB::table('branch_ingredients')->insert([
                            'branch_id' => $branch->id,
                            'ingredient_id' => $ing->id,
                            'stock_qty' => $ing->stock_qty ?? 0,
                            'min_stock' => $ing->min_stock ?? 5,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ]);
                    }
                }
            }
        } catch (\Exception $e) {
            \Log::warning('Data migration for branch_ingredients: ' . $e->getMessage());
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('ingredient_histories') && Schema::hasColumn('ingredient_histories', 'branch_id')) {
            Schema::table('ingredient_histories', function (Blueprint $table) {
                $table->dropForeign(['branch_id']);
                $table->dropColumn('branch_id');
            });
        }

        Schema::dropIfExists('branch_ingredients');
    }
};
