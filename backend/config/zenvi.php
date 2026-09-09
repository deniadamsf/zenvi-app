<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Zona Waktu Operasional Toko
    |--------------------------------------------------------------------------
    |
    | Timestamp disimpan dalam UTC (config/app.php timezone = UTC) dan itu
    | sengaja tidak diubah: mengubahnya membuat baris lama terbaca beda dari
    | baris baru.
    |
    | Yang butuh zona waktu ini adalah perbandingan JAM DINDING - jadwal shift
    | yang diketik owner ("08:00") adalah waktu lokal, sedangkan `start_time`
    | shift tersimpan UTC. Membandingkan keduanya mentah-mentah membuat absen
    | 08:30 WIB terbaca 01:30 UTC, jadi tidak pernah dianggap telat sampai ada
    | yang absen lewat jam 3 sore.
    |
    | Catatan: ini satu nilai untuk seluruh instalasi. Toko di zona WITA/WIT
    | akan meleset 1-2 jam; kalau nanti ada toko di luar WIB, nilai ini perlu
    | naik jadi kolom per-perusahaan.
    |
    */

    'business_timezone' => env('ZENVI_BUSINESS_TIMEZONE', 'Asia/Jakarta'),

];
