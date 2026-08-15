<?php
require '/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/vendor/autoload.php';
$app = require_once '/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

// Simulasikan apa yang OrderController@index lakukan
// User #3 (Deni Adams) punya company_id = 2
$companyId = 2;
$date = '2026-08-01';

echo "=== Simulating OrderController@index ===\n";
echo "company_id=$companyId, date=$date\n\n";

$orders = App\Models\Order::with(['items.product', 'user', 'shift.branch'])
    ->where('company_id', $companyId)
    ->whereDate('created_at', $date)
    ->latest()
    ->get();

echo "Found: " . $orders->count() . " orders\n\n";

foreach($orders as $o) {
    echo "Order #{$o->id}: total={$o->total_amount}, status={$o->status}, items=" . $o->items->count() . "\n";
    foreach($o->items as $item) {
        echo "  -> Product: " . ($item->product->name ?? 'N/A') . " x{$item->qty} = {$item->subtotal}\n";
    }
}

// Test the JSON output
echo "\n=== JSON Response ===\n";
echo json_encode(['data' => $orders->toArray()], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
