<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductRequest;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $products = Product::with(['ingredients', 'variants'])
            ->where('company_id', $request->user()->company_id)
            ->get();
            
        return response()->json(['data' => $products]);
    }

    public function store(StoreProductRequest $request)
    {
        DB::beginTransaction();
        try {
            $imagePath = null;
            if ($request->hasFile('image')) {
                $image = $request->file('image');
                $filename = time() . '.' . $image->getClientOriginalExtension();
                $path = 'uploads/products/' . $filename;
                
                // create new manager instance with desired driver
                $manager = new ImageManager(new Driver());
                $img = $manager->read($image);
                $img->cover(300, 300);
                
                // Save directly to public path to avoid symlink issues on shared hosting
                $destinationPath = public_path('uploads/products');
                if (!file_exists($destinationPath)) {
                    mkdir($destinationPath, 0755, true);
                }
                $img->save(public_path($path));
                
                $imagePath = $path;
            }

            $product = Product::create([
                'company_id' => $request->user()->company_id,
                'name' => $request->name,
                'category' => $request->category,
                'price' => $request->price,
                'cost_price' => $request->cost_price ?? 0,
                'discount_nominal' => $request->discount_nominal ?? 0,
                'discount_percent' => $request->discount_percent ?? 0,
                'is_active' => $request->is_active ?? true,
                'image_path' => $imagePath,
            ]);

            if ($request->has('ingredients')) {
                $syncData = [];
                foreach ($request->ingredients as $item) {
                    $syncData[$item['ingredient_id']] = ['amount_needed' => $item['amount_needed']];
                }
                $product->ingredients()->sync($syncData);
            }

            if ($request->has('variants')) {
                foreach ($request->variants as $var) {
                    $product->variants()->create([
                        'name' => $var['name'],
                        'price' => $var['price'],
                        'is_active' => $var['is_active'] ?? true,
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Produk berhasil ditambahkan.',
                'data' => $product->load(['ingredients', 'variants'])
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal menambahkan produk.', 'error' => $e->getMessage()], 500);
        }
    }

    public function update(StoreProductRequest $request, $id)
    {
        $product = Product::where('company_id', $request->user()->company_id)->findOrFail($id);
        
        DB::beginTransaction();
        try {
            $imagePath = $product->image_path;
            if ($request->hasFile('image')) {
                $image = $request->file('image');
                $filename = time() . '.' . $image->getClientOriginalExtension();
                $path = 'uploads/products/' . $filename;
                
                $manager = new ImageManager(new Driver());
                $img = $manager->read($image);
                $img->cover(300, 300);
                
                $destinationPath = public_path('uploads/products');
                if (!file_exists($destinationPath)) {
                    mkdir($destinationPath, 0755, true);
                }
                $img->save(public_path($path));
                
                // Delete old image if exists
                if ($product->image_path && file_exists(public_path($product->image_path))) {
                    unlink(public_path($product->image_path));
                }        
                
                $imagePath = $path;
            }

            $product->update([
                'name' => $request->name,
                'category' => $request->has('category') ? $request->category : $product->category,
                'price' => $request->price,
                'cost_price' => $request->has('cost_price') ? $request->cost_price : $product->cost_price,
                'discount_nominal' => $request->has('discount_nominal') ? $request->discount_nominal : $product->discount_nominal,
                'discount_percent' => $request->has('discount_percent') ? $request->discount_percent : $product->discount_percent,
                'is_active' => $request->is_active ?? $product->is_active,
                'image_path' => $imagePath,
            ]);

            if ($request->has('ingredients')) {
                $syncData = [];
                foreach ($request->ingredients as $item) {
                    $syncData[$item['ingredient_id']] = ['amount_needed' => $item['amount_needed']];
                }
                $product->ingredients()->sync($syncData);
            }

            if ($request->has('variants')) {
                // To keep it simple, we delete existing variants and re-create them, or we can update existing
                // Since this is a simple POS, we will delete and re-create variants if they are passed.
                // Or better, we sync them manually.
                $product->variants()->delete();
                foreach ($request->variants as $var) {
                    $product->variants()->create([
                        'name' => $var['name'],
                        'price' => $var['price'],
                        'is_active' => $var['is_active'] ?? true,
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Produk berhasil diperbarui.',
                'data' => $product->load(['ingredients', 'variants'])
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal memperbarui produk.', 'error' => $e->getMessage()], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $product = Product::where('company_id', $request->user()->company_id)->findOrFail($id);
        // Soft delete equivalent: set is_active = false
        $product->update(['is_active' => false]);

        return response()->json([
            'message' => 'Produk berhasil dinonaktifkan.'
        ]);
    }
}
