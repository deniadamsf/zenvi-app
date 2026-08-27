<!DOCTYPE html>
<html lang="{{ request('lang') == 'en' ? 'en' : 'id' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Disclaimer (Penafian Hukum) | Zenvi POS - Point of Sale Multi-Outlet</title>
    <meta name="description" content="Penafian hukum resmi (Disclaimer) untuk aplikasi Zenvi POS dan portal layanan zenvi.cellanoma.my.id oleh Cellanoma Digital.">
    <meta name="robots" content="index, follow">

    <!-- Open Graph / Meta -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://zenvi.cellanoma.my.id/disclaimer">
    <meta property="og:title" content="Disclaimer (Penafian) — Zenvi POS">
    <meta property="og:description" content="Penafian hukum resmi Zenvi POS mengenai batasan tanggung jawab, akurasi finansial/pajak, dan kompatibilitas perangkat keras.">
    <meta property="og:image" content="{{ asset('images/logo.png') }}">

    <!-- Google Fonts: Outfit -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <style>
        :root {
            --primary: #0D7C83;
            --primary-dark: #095459;
            --primary-light: #e6f6f7;
            --accent: #10b981;
            --text-dark: #0f172a;
            --text-body: #334155;
            --text-muted: #64748b;
            --bg-page: #f8fafc;
            --card-bg: #ffffff;
            --border-color: #e2e8f0;
            --radius-sm: 8px;
            --radius-md: 14px;
            --radius-lg: 20px;
            --radius-xl: 28px;
            --shadow-subtle: 0 4px 20px -2px rgba(15, 23, 42, 0.05);
            --shadow-elevated: 0 12px 32px -4px rgba(13, 124, 131, 0.08), 0 4px 12px -2px rgba(15, 23, 42, 0.04);
        }

        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        html {
            scroll-behavior: smooth;
            font-size: 16px;
        }

        body {
            font-family: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--bg-page);
            color: var(--text-body);
            line-height: 1.7;
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
        }

        /* Header / Navbar */
        .header {
            position: sticky;
            top: 0;
            z-index: 100;
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--border-color);
        }

        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0.85rem 1.5rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            text-decoration: none;
            color: var(--text-dark);
        }

        .brand-logo-icon {
            width: 40px;
            height: 40px;
            background: var(--primary);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 10px rgba(13, 124, 131, 0.3);
        }

        .brand-title {
            font-size: 1.35rem;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: var(--text-dark);
            line-height: 1.1;
        }

        .brand-subtitle {
            font-size: 0.75rem;
            color: var(--primary);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .nav-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        /* Language Switcher Pill */
        .lang-switch {
            display: flex;
            background: #f1f5f9;
            padding: 3px;
            border-radius: 999px;
            border: 1px solid var(--border-color);
        }

        .lang-btn {
            border: none;
            background: transparent;
            padding: 0.35rem 0.85rem;
            border-radius: 999px;
            font-size: 0.825rem;
            font-weight: 600;
            color: var(--text-muted);
            cursor: pointer;
            transition: all 0.2s ease;
            font-family: inherit;
        }

        .lang-btn.active {
            background: #ffffff;
            color: var(--primary);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
        }

        /* Hero Header */
        .hero {
            background: linear-gradient(180deg, #e6f6f7 0%, #f8fafc 100%);
            padding: 3.5rem 1.5rem 2.5rem;
            text-align: center;
            border-bottom: 1px solid var(--border-color);
        }

        .badge-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            background: #ffffff;
            border: 1px solid rgba(13, 124, 131, 0.25);
            padding: 0.35rem 0.9rem;
            border-radius: 999px;
            font-size: 0.825rem;
            font-weight: 600;
            color: var(--primary);
            margin-bottom: 1.25rem;
            box-shadow: 0 2px 8px rgba(13, 124, 131, 0.06);
        }

        .hero-title {
            font-size: 2.5rem;
            font-weight: 800;
            color: var(--text-dark);
            letter-spacing: -0.03em;
            margin-bottom: 0.75rem;
            line-height: 1.2;
        }

        .hero-subtitle {
            font-size: 1.1rem;
            color: var(--text-muted);
            max-width: 680px;
            margin: 0 auto 1.5rem;
        }

        .hero-meta {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 1.5rem;
            flex-wrap: wrap;
            font-size: 0.875rem;
            color: var(--text-muted);
        }

        .hero-meta-item {
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }

        /* Layout */
        .layout-container {
            max-width: 1200px;
            margin: 2.5rem auto 4rem;
            padding: 0 1.5rem;
            display: grid;
            grid-template-columns: 280px 1fr;
            gap: 2.5rem;
            align-items: start;
        }

        /* Sidebar Navigation */
        .sidebar {
            position: sticky;
            top: 5.5rem;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-lg);
            padding: 1.25rem;
            box-shadow: var(--shadow-subtle);
        }

        .sidebar-title {
            font-size: 0.875rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-muted);
            margin-bottom: 0.85rem;
            padding-left: 0.5rem;
        }

        .toc-list {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .toc-link {
            display: flex;
            align-items: center;
            gap: 0.6rem;
            padding: 0.55rem 0.75rem;
            border-radius: var(--radius-sm);
            color: var(--text-body);
            text-decoration: none;
            font-size: 0.875rem;
            font-weight: 500;
            transition: all 0.2s ease;
        }

        .toc-link:hover, .toc-link.active {
            background: var(--primary-light);
            color: var(--primary);
            font-weight: 600;
        }

        .toc-link i, .toc-link svg {
            width: 16px;
            height: 16px;
            color: var(--primary);
        }

        /* Content Area */
        .content-area {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-xl);
            padding: 2.5rem;
            box-shadow: var(--shadow-elevated);
        }

        .policy-section {
            margin-bottom: 3rem;
            scroll-margin-top: 6rem;
        }

        .policy-section:last-child {
            margin-bottom: 0;
        }

        .section-header {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 1.25rem;
            padding-bottom: 0.75rem;
            border-bottom: 2px solid var(--primary-light);
        }

        .section-icon {
            width: 36px;
            height: 36px;
            background: var(--primary-light);
            color: var(--primary);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .section-title {
            font-size: 1.45rem;
            font-weight: 700;
            color: var(--text-dark);
            letter-spacing: -0.02em;
        }

        .policy-p {
            margin-bottom: 1rem;
            color: var(--text-body);
            font-size: 0.975rem;
        }

        .policy-list {
            margin: 0.75rem 0 1.25rem 1.5rem;
            color: var(--text-body);
            font-size: 0.95rem;
        }

        .policy-list li {
            margin-bottom: 0.5rem;
        }

        /* Callout Box */
        .callout {
            background: #fffbeb;
            border-left: 4px solid #f59e0b;
            border-radius: 0 var(--radius-md) var(--radius-md) 0;
            padding: 1.25rem 1.5rem;
            margin: 1.5rem 0;
        }

        .callout.callout-info {
            background: var(--primary-light);
            border-left-color: var(--primary);
        }

        .callout-title {
            font-weight: 700;
            font-size: 0.95rem;
            color: var(--text-dark);
            margin-bottom: 0.35rem;
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }

        .callout-p {
            font-size: 0.9rem;
            color: var(--text-body);
            margin: 0;
        }

        /* Contact Grid */
        .contact-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1rem;
            margin-top: 1rem;
        }

        .contact-item {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-md);
            padding: 1rem 1.25rem;
            display: flex;
            align-items: center;
            gap: 0.85rem;
        }

        .contact-icon {
            width: 36px;
            height: 36px;
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
            flex-shrink: 0;
        }

        .contact-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            font-weight: 600;
            color: var(--text-muted);
        }

        .contact-val {
            font-size: 0.925rem;
            font-weight: 600;
            color: var(--text-dark);
            text-decoration: none;
            word-break: break-all;
        }

        .contact-val:hover {
            color: var(--primary);
            text-decoration: underline;
        }

        /* Footer */
        .footer {
            background: #0f172a;
            color: #94a3b8;
            padding: 3rem 1.5rem 2rem;
            font-size: 0.875rem;
            border-top: 1px solid #1e293b;
        }

        .footer-container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            gap: 1.5rem;
        }

        .footer-links {
            display: flex;
            gap: 1.5rem;
            flex-wrap: wrap;
            justify-content: center;
        }

        .footer-link {
            color: #cbd5e1;
            text-decoration: none;
            transition: color 0.2s;
        }

        .footer-link:hover {
            color: #ffffff;
        }

        /* Language Toggle Visibility */
        .lang-content {
            display: none;
        }

        .lang-content.active {
            display: block;
            animation: fadeIn 0.3s ease-in-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(6px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (max-width: 900px) {
            .layout-container {
                grid-template-columns: 1fr;
            }
            .sidebar { display: none; }
            .content-area { padding: 1.5rem; }
            .hero-title { font-size: 2rem; }
        }
    </style>
</head>
<body>

    <!-- Header / Navbar -->
    <header class="header">
        <div class="nav-container">
            <a href="/" class="brand-logo">
                <div class="brand-logo-icon">
                    <svg width="24" height="24" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect width="100" height="100" rx="20" fill="#0D7C83"/>
                        <path d="M37.2 25H25L50 75L75 25H43.8" stroke="white" stroke-width="8" stroke-linejoin="miter" stroke-linecap="square"/>
                    </svg>
                </div>
                <div>
                    <div class="brand-title">Zenvi</div>
                    <div class="brand-subtitle">Point of Sale & Business</div>
                </div>
            </a>

            <div class="nav-actions">
                <div class="lang-switch">
                    <button type="button" class="lang-btn active" id="btn-lang-id" onclick="setLanguage('id')">🇮🇩 ID</button>
                    <button type="button" class="lang-btn" id="btn-lang-en" onclick="setLanguage('en')">🇬🇧 EN</button>
                </div>
            </div>
        </div>
    </header>

    <!-- Hero -->
    <section class="hero">
        <div class="badge-pill">
            <i data-lucide="scale" style="width: 16px; height: 16px;"></i>
            <span id="badge-text">Dokumen Hukum & Ketentuan Layanan</span>
        </div>
        <h1 class="hero-title" id="hero-title-text">Penafian Hukum (Disclaimer)</h1>
        <p class="hero-subtitle" id="hero-subtitle-text">
            Batasan tanggung jawab hukum, ketentuan teknis, dan kejelasan operasional layanan aplikasi Zenvi POS.
        </p>
        <div class="hero-meta">
            <div class="hero-meta-item">
                <i data-lucide="building" style="width: 16px; height: 16px; color: var(--primary);"></i>
                <span>Pengembang: <strong>Cellanoma Digital</strong></span>
            </div>
            <div class="hero-meta-item">
                <i data-lucide="calendar" style="width: 16px; height: 16px; color: var(--primary);"></i>
                <span>Terakhir Diperbarui: <strong>Agustus 2026</strong></span>
            </div>
        </div>
    </section>

    <!-- Main Content -->
    <main class="layout-container">
        <!-- Sidebar Navigation (Desktop) -->
        <aside class="sidebar">
            <div class="sidebar-title" id="toc-title">Daftar Isi Penafian</div>
            <ul class="toc-list">
                <li><a href="#general" class="toc-link"><i data-lucide="info"></i> <span class="toc-t1">Penafian Umum</span></a></li>
                <li><a href="#financial" class="toc-link"><i data-lucide="calculator"></i> <span class="toc-t2">Nasihat Finansial & Pajak</span></a></li>
                <li><a href="#hardware" class="toc-link"><i data-lucide="printer"></i> <span class="toc-t3">Kompatibilitas Perangkat</span></a></li>
                <li><a href="#offline" class="toc-link"><i data-lucide="wifi-off"></i> <span class="toc-t4">Ketersediaan & Sinkronisasi</span></a></li>
                <li><a href="#liability" class="toc-link"><i data-lucide="alert-octagon"></i> <span class="toc-t5">Batasan Tanggung Jawab</span></a></li>
                <li><a href="#third-parties" class="toc-link"><i data-lucide="external-link"></i> <span class="toc-t6">Layanan Pihak Ketiga</span></a></li>
                <li><a href="#contact" class="toc-link"><i data-lucide="mail"></i> <span class="toc-t7">Kontak Pengembang</span></a></li>
            </ul>
        </aside>

        <!-- Content Area -->
        <div class="content-area">

            <!-- ======================================================= -->
            <!-- BAHASA INDONESIA CONTENT -->
            <!-- ======================================================= -->
            <div id="content-id" class="lang-content active">

                <!-- 1. Penafian Umum -->
                <section id="general" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="info"></i></div>
                        <h2 class="section-title">1. Penafian Umum (General Disclaimer)</h2>
                    </div>
                    <p class="policy-p">
                        Aplikasi mobile <strong>Zenvi POS</strong> dan portal layanan web terintegrasi di <code>https://zenvi.cellanoma.my.id</code> disediakan oleh <strong>Cellanoma Digital</strong> atas dasar <em>"sebagaimana adanya" ("as-is")</em> dan <em>"sebagaimana tersedia" ("as-available")</em> untuk tujuan efisiensi operasional kasir, manajemen stok, dan pencatatan transaksi bisnis komersial.
                    </p>
                    <p class="policy-p">
                        Meskipun kami berupaya keras memastikan keandalan, stabilitas, dan keamanan kode sistem, kami tidak membuat pernyataan atau jaminan tersurat maupun tersirat mengenai kesesuaian sistem untuk tujuan tertentu di luar spesifikasi fungsional yang telah kami terbitkan.
                    </p>
                </section>

                <!-- 2. Nasihat Finansial & Pajak -->
                <section id="financial" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="calculator"></i></div>
                        <h2 class="section-title">2. Bukan Nasihat Keuangan, Akuntansi, atau Pajak Resmi</h2>
                    </div>
                    <p class="policy-p">
                        Fitur-fitur di dalam Zenvi POS seperti kalkulasi diskon, persentase pajak (PPN/PB1), perhitungan Harga Pokok Penjualan (HPP / COGS), grafik laba kotor, dan rekapitulasi shift kasir disediakan semata-mata sebagai <strong>alat bantu manajemen operasional teknis</strong>.
                    </p>
                    <div class="callout">
                        <div class="callout-title"><i data-lucide="alert-triangle"></i> Tanggung Jawab Kepatuhan Pajak & Akuntansi</div>
                        <p class="callout-p">
                            Zenvi POS <strong>TIDAK BERTINDAK</strong> sebagai konsultan akuntansi, auditor publik, atau otoritas perpajakan resmi. Pemilik usaha / merchant bertanggung jawab penuh untuk memastikan bahwa tarif pajak, laporan keuangan akhir, dan pelaporan perpajakan usaha mereka telah sesuai dengan undang-undang dan peraturan perpajakan yang berlaku di yurisdiksi masing-masing.
                        </p>
                    </div>
                </section>

                <!-- 3. Kompatibilitas Perangkat -->
                <section id="hardware" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="printer"></i></div>
                        <h2 class="section-title">3. Kompatibilitas Perangkat Keras (Hardware) & Bluetooth</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi POS dirancang untuk mendukung berbagai perangkat keras kasir berbasis standar industri (seperti printer thermal 58mm/80mm ESC/POS via Bluetooth/USB, barcode scanner, dan cash drawer). Namun, dikarenakan banyaknya variasi chipset, modul Bluetooth, firmware pihak ketiga, dan versi sistem operasi Android di pasaran, kami tidak dapat menjamin kompatibilitas 100% pada semua merk perangkat keras tanpa pengujian terlebih dahulu.
                    </p>
                </section>

                <!-- 4. Ketersediaan & Sinkronisasi -->
                <section id="offline" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="wifi-off"></i></div>
                        <h2 class="section-title">4. Ketersediaan Layanan & Sinkronisasi Offline</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi mengadopsi arsitektur <em>Offline-First</em> di mana transaksi kasir disimpan pada database lokal SQLite ponsel/tablet saat tidak ada koneksi internet. Pengguna disarankan untuk secara teratur menghubungkan perangkat ke jaringan internet yang stabil agar data transaksi terunggah dan tersinkronisasi ke server cloud secara aman.
                    </p>
                    <p class="policy-p">
                        Kami tidak bertanggung jawab atas kehilangan data lokal yang disebabkan oleh kerusakan fisik perangkat keras pengguna, pembersihan data aplikasi secara tidak sengaja (clear cache/storage manual), atau kegagalan perangkat pengguna sebelum proses sinkronisasi berhasil dilakukan.
                    </p>
                </section>

                <!-- 5. Batasan Tanggung Jawab -->
                <section id="liability" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="alert-octagon"></i></div>
                        <h2 class="section-title">5. Batasan Tanggung Jawab (Limitation of Liability)</h2>
                    </div>
                    <p class="policy-p">
                        Sepanjang diizinkan oleh hukum yang berlaku di Republik Indonesia, <strong>Cellanoma Digital</strong> beserta seluruh pengembang, afiliasi, dan mitra tidak bertanggung jawab atas:
                    </p>
                    <ul class="policy-list">
                        <li>Kerugian finansial tidak langsung, kehilangan laba usaha, gangguan bisnis, atau hilangnya peluang komersial pengguna;</li>
                        <li>Kesalahan input data harga, stok bahan baku, atau diskon yang dilakukan oleh staf kasir atau pemilik toko;</li>
                        <li>Gangguan jaringan internet pihak ketiga (ISP) atau pemadaman listrik di lokasi usaha merchant;</li>
                        <li>Kejadian <em>Force Majeure</em> di luar kendali wajar kami (bencana alam, huru-hara, kegagalan infrastruktur telekomunikasi global).</li>
                    </ul>
                </section>

                <!-- 6. Layanan Pihak Ketiga -->
                <section id="third-parties" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="external-link"></i></div>
                        <h2 class="section-title">6. Layanan Pihak Ketiga & Tautan Eksternal</h2>
                    </div>
                    <p class="policy-p">
                        Aplikasi dan website kami dapat memuat tautan atau integrasi ke layanan pihak ketiga (seperti Google Play Services, Firebase Cloud Messaging, penyedia QRIS, Google Sign-In). Kami tidak mengontrol dan tidak bertanggung jawab atas konten, kebijakan privasi, atau praktik dari situs web atau layanan pihak ketiga tersebut.
                    </p>
                </section>

                <!-- 7. Kontak Pengembang -->
                <section id="contact" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="mail"></i></div>
                        <h2 class="section-title">7. Pertanyaan & Kontak Pengembang</h2>
                    </div>
                    <p class="policy-p">
                        Jika Anda memerlukan klarifikasi lebih lanjut mengenai Disclaimer atau ketentuan penggunaan aplikasi Zenvi POS, silakan hubungi tim legal kami:
                    </p>

                    <div class="contact-grid">
                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="mail"></i></div>
                            <div>
                                <div class="contact-label">Email Dukungan & Legal</div>
                                <a href="mailto:cellanomadigital@gmail.com" class="contact-val">cellanomadigital@gmail.com</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="globe"></i></div>
                            <div>
                                <div class="contact-label">Website Resmi</div>
                                <a href="https://zenvi.cellanoma.my.id" class="contact-val">zenvi.cellanoma.my.id</a>
                            </div>
                        </div>
                    </div>
                </section>

            </div>

            <!-- ======================================================= -->
            <!-- ENGLISH CONTENT -->
            <!-- ======================================================= -->
            <div id="content-en" class="lang-content">

                <!-- 1. General Disclaimer -->
                <section id="general-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="info"></i></div>
                        <h2 class="section-title">1. General Disclaimer</h2>
                    </div>
                    <p class="policy-p">
                        The <strong>Zenvi POS</strong> mobile application and integrated backend web portal at <code>https://zenvi.cellanoma.my.id</code> are developed and maintained by <strong>Cellanoma Digital</strong>. All tools and capabilities are provided on an <em>"as-is"</em> and <em>"as-available"</em> basis for cashier operational management, inventory control, and transaction logging.
                    </p>
                    <p class="policy-p">
                        While we strive to ensure maximum software reliability and security, we make no explicit warranties regarding uninterrupted fitness for specific business practices outside our published documentation.
                    </p>
                </section>

                <!-- 2. Financial & Tax Disclaimer -->
                <section id="financial-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="calculator"></i></div>
                        <h2 class="section-title">2. No Financial, Accounting, or Legal Tax Advice</h2>
                    </div>
                    <p class="policy-p">
                        Features in Zenvi POS (including discount calculations, tax percentages, Cost of Goods Sold / COGS estimations, and gross margin analytics) are intended strictly as <strong>operational technical tools</strong>.
                    </p>
                    <div class="callout">
                        <div class="callout-title"><i data-lucide="alert-triangle"></i> Tax & Accounting Compliance Responsibility</div>
                        <p class="callout-p">
                            Zenvi POS does <strong>NOT</strong> act as a certified public accountant, tax advisor, or statutory financial auditor. Store owners and merchants bear sole responsibility for ensuring their sales records, tax rates, and filing submissions comply fully with local governing tax regulations.
                        </p>
                    </div>
                </section>

                <!-- 3. Hardware Compatibility -->
                <section id="hardware-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="printer"></i></div>
                        <h2 class="section-title">3. Hardware & Peripheral Compatibility</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi POS supports standard ESC/POS protocol thermal receipt printers (58mm and 80mm via Bluetooth/USB) and electronic cash drawers. Due to variations across manufacturers, Bluetooth firmwares, and customized Android ROMs, universal hardware interoperability cannot be guaranteed without prior testing on specific peripherals.
                    </p>
                </section>

                <!-- 4. Service Availability & Offline Sync -->
                <section id="offline-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="wifi-off"></i></div>
                        <h2 class="section-title">4. Offline Data Synchronization & Availability</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi utilizes an <em>Offline-First</em> architecture that persists transaction logs to local SQLite storage during network outages. Users must periodically connect their devices to a reliable internet connection to complete cloud synchronization.
                    </p>
                </section>

                <!-- 5. Limitation of Liability -->
                <section id="liability-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="alert-octagon"></i></div>
                        <h2 class="section-title">5. Limitation of Liability</h2>
                    </div>
                    <p class="policy-p">
                        To the maximum extent permitted by applicable law, <strong>Cellanoma Digital</strong> and its developers shall not be held liable for:
                    </p>
                    <ul class="policy-list">
                        <li>Indirect, incidental, or consequential losses, including lost profits or business interruptions;</li>
                        <li>Clerical data input errors, incorrect discount configurations, or mispriced items created by merchant users;</li>
                        <li>Third-party network outages or telecom carrier disruptions;</li>
                        <li>Force majeure events beyond reasonable technical control.</li>
                    </ul>
                </section>

                <!-- 6. Third-Party Services -->
                <section id="third-parties-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="external-link"></i></div>
                        <h2 class="section-title">6. Third-Party Services & Links</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi POS incorporates third-party APIs (Google Play Services, Firebase Cloud Messaging, OpenStreetMap). We do not control and assume no liability for the practices or policies of third-party platforms.
                    </p>
                </section>

                <!-- 7. Contact Us -->
                <section id="contact-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="mail"></i></div>
                        <h2 class="section-title">7. Legal Inquiries & Contact</h2>
                    </div>
                    <p class="policy-p">
                        For any legal inquiries regarding this Disclaimer, please reach out to our team:
                    </p>

                    <div class="contact-grid">
                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="mail"></i></div>
                            <div>
                                <div class="contact-label">Legal & Support Email</div>
                                <a href="mailto:cellanomadigital@gmail.com" class="contact-val">cellanomadigital@gmail.com</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="globe"></i></div>
                            <div>
                                <div class="contact-label">Official Portal</div>
                                <a href="https://zenvi.cellanoma.my.id" class="contact-val">zenvi.cellanoma.my.id</a>
                            </div>
                        </div>
                    </div>
                </section>

            </div>

        </div>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <div class="footer-container">
            <div class="footer-links">
                <a href="/" class="footer-link">Beranda Zenvi</a>
                <a href="/privacy-policy" class="footer-link">Kebijakan Privasi</a>
                <a href="/disclaimer" class="footer-link">Disclaimer / Penafian</a>
                <a href="/delete-account" class="footer-link">Hapus Akun</a>
            </div>
            <div style="color: #64748b; font-size: 0.8rem;">
                &copy; {{ date('Y') }} Zenvi POS by Cellanoma Digital. All Rights Reserved.
            </div>
        </div>
    </footer>

    <!-- Scripts -->
    <script>
        lucide.createIcons();

        function setLanguage(lang) {
            const contentId = document.getElementById('content-id');
            const contentEn = document.getElementById('content-en');
            const btnId = document.getElementById('btn-lang-id');
            const btnEn = document.getElementById('btn-lang-en');
            const heroTitle = document.getElementById('hero-title-text');
            const heroSub = document.getElementById('hero-subtitle-text');
            const badgeText = document.getElementById('badge-text');
            const tocTitle = document.getElementById('toc-title');

            if (lang === 'en') {
                contentId.classList.remove('active');
                contentEn.classList.add('active');
                btnId.classList.remove('active');
                btnEn.classList.add('active');
                heroTitle.innerText = 'Legal Disclaimer';
                heroSub.innerText = 'Limitations of liability, technical terms, and operational clarity for Zenvi POS.';
                badgeText.innerText = 'Official Legal Terms & Service Clarifications';
                tocTitle.innerText = 'Table of Contents';
                updateTocLabels('en');

                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'en');
                window.history.replaceState({}, '', newUrl);
            } else {
                contentEn.classList.remove('active');
                contentId.classList.add('active');
                btnEn.classList.remove('active');
                btnId.classList.add('active');
                heroTitle.innerText = 'Penafian Hukum (Disclaimer)';
                heroSub.innerText = 'Batasan tanggung jawab hukum, ketentuan teknis, dan kejelasan operasional layanan aplikasi Zenvi POS.';
                badgeText.innerText = 'Dokumen Hukum & Ketentuan Layanan';
                tocTitle.innerText = 'Daftar Isi Penafian';
                updateTocLabels('id');

                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'id');
                window.history.replaceState({}, '', newUrl);
            }

            setTimeout(() => {
                lucide.createIcons();
            }, 50);
        }

        function updateTocLabels(lang) {
            const map = {
                id: ['Penafian Umum', 'Nasihat Finansial & Pajak', 'Kompatibilitas Perangkat', 'Ketersediaan & Sinkronisasi', 'Batasan Tanggung Jawab', 'Layanan Pihak Ketiga', 'Kontak Pengembang'],
                en: ['General Disclaimer', 'Financial & Tax Disclaimer', 'Hardware Compatibility', 'Availability & Offline Sync', 'Limitation of Liability', 'Third-Party Services', 'Legal Contact']
            };
            const labels = map[lang] || map.id;
            for (let i = 1; i <= 7; i++) {
                const el = document.querySelector('.toc-t' + i);
                if (el) el.innerText = labels[i-1];
            }
        }

        document.addEventListener('DOMContentLoaded', () => {
            const urlParams = new URLSearchParams(window.location.search);
            const langParam = urlParams.get('lang');
            if (langParam === 'en') {
                setLanguage('en');
            } else {
                setLanguage('id');
            }
        });
    </script>
</body>
</html>
