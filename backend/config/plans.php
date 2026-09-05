<?php

/*
|--------------------------------------------------------------------------
| Paket Langganan Zenvi
|--------------------------------------------------------------------------
|
| Definisi paket sengaja ditaruh di config, bukan tabel database: paket jarang
| berubah tapi dibaca di hampir setiap request, dan di sini ia ikut ter-cache
| oleh `php artisan config:cache` sehingga tidak menambah satu query pun.
|
| HARGA TIDAK ADA DI SINI. Pembayaran memakai Google Play Billing, jadi harga
| ditetapkan di Play Console dan ditampilkan aplikasi dari sana. Menyimpan harga
| di dua tempat hanya melahirkan ketidakcocokan antara yang tampil di aplikasi
| dan yang benar-benar ditagih Google.
|
*/

return [

    'default' => 'free',

    /*
    | Masa tenggang setelah `plan_expires_at` terlewat. Selama masa ini paket
    | masih berlaku penuh - memutus akses tepat di detik kedaluwarsa membuat
    | toko yang pembayarannya sedang diproses Google berhenti berjualan.
    |
    | HARUS >= masa tenggang di Play Console (disetel 7 hari). Kalau lebih
    | pendek, pelanggan yang pembayarannya gagal masih dianggap berlangganan
    | oleh Google tapi sudah diturunkan oleh server - mereka kehilangan akses
    | padahal Google masih mencoba menagih ulang.
    */
    'grace_days' => 7,

    /*
    | Seluruh fitur yang bisa dikunci. Fitur yang tidak terdaftar di sini
    | berarti gratis untuk semua paket (POS, struk, shift, stok, absensi GPS,
    | chat, laporan performa karyawan, dan seterusnya).
    */
    'features' => [
        'product_image'       => 'Foto produk',
        'attendance_selfie'   => 'Selfie absensi',
        'membership'          => 'Member & promo member',
        'points'              => 'Poin pelanggan',
        'qr_menu'             => 'QR menu & halaman toko',
        'reservation'         => 'Reservasi',
        'kds'                 => 'Kitchen Display System',
        'full_report'         => 'Laporan laba rugi penuh',
        'export'              => 'Export Excel & PDF',
        'multi_branch'        => 'Multi-cabang',
        'branch_stock'        => 'Stok per cabang',
        'consolidated_report' => 'Laporan konsolidasi lintas cabang',
        'stock_transfer'      => 'Transfer stok antar cabang',
    ],

    /*
    | Batas per paket. `null` berarti tak terbatas.
    |
    | `rank` menentukan urutan paket, dipakai untuk menghitung paket termurah
    | yang membuka sebuah fitur (dikirim ke aplikasi sebagai `required_plan`).
    */
    'plans' => [

        'free' => [
            'rank'     => 0,
            'name'     => 'Gratis',
            'features' => [],
            'limits'   => [
                'products'     => 50,
                'employees'    => 10,
                'branches'     => 1,
                'history_days' => 30,
            ],
        ],

        'premium' => [
            'rank'     => 1,
            'name'     => 'Premium',
            'features' => [
                'product_image',
                'attendance_selfie',
                'membership',
                'points',
                'qr_menu',
                'reservation',
                'kds',
                'full_report',
                'export',
            ],
            'limits'   => [
                'products'     => null,
                'employees'    => null,
                'branches'     => 1,
                'history_days' => null,
            ],
        ],

        'business' => [
            'rank'     => 2,
            'name'     => 'Bisnis',
            'features' => [
                'product_image',
                'attendance_selfie',
                'membership',
                'points',
                'qr_menu',
                'reservation',
                'kds',
                'full_report',
                'export',
                'multi_branch',
                'branch_stock',
                'consolidated_report',
                'stock_transfer',
            ],
            'limits'   => [
                'products'     => null,
                'employees'    => null,
                'branches'     => 5,
                'history_days' => null,
            ],
        ],

    ],

];
