<?php
require '/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/vendor/autoload.php';
$app = require_once '/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
$orders = \App\Models\Order::all();
foreach($orders as $o) {
    echo 'Order ID: ' . $o->id . ' Company ID: ' . $o->company_id . ' User ID: ' . $o->user_id . "\n";
}
