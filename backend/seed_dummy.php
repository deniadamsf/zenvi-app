<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

DB::table('companies')->insert(['id' => 1, 'name' => 'Dummy Company', 'code' => 'DUMMY']);

DB::table('users')->insert([
    'id' => 1, 
    'name' => 'Owner Dummy', 
    'email' => 'owner@zenvi.com', 
    'password' => Hash::make('password'), 
    'role' => 'Owner', 
    'company_id' => 1
]);

DB::table('personal_access_tokens')->insert([
    'tokenable_type' => 'App\Models\User', 
    'tokenable_id' => 1, 
    'name' => 'Test Token', 
    'token' => hash('sha256', 'dummy_token_123'), 
    'abilities' => '["*"]'
]);

echo "Dummy data inserted!\n";
