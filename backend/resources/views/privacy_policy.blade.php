<!DOCTYPE html>
<html lang="{{ request('lang') == 'en' ? 'en' : 'id' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Kebijakan Privasi | Zenvi POS - Point of Sale & Kasir Multi-Outlet</title>
    <meta name="description" content="Kebijakan Privasi resmi aplikasi Zenvi POS oleh Cellanoma Digital. Ketahui bagaimana kami mengumpulkan, melindungi, dan mengelola data pengguna serta kepatuhan izin perangkat.">
    <meta name="robots" content="index, follow">

    <!-- Open Graph / Meta -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://zenvi.cellanoma.my.id/privacy-policy">
    <meta property="og:title" content="Kebijakan Privasi — Zenvi POS">
    <meta property="og:description" content="Kebijakan Privasi resmi aplikasi Zenvi POS untuk kepatuhan Google Play Store dan perlindungan data pengguna.">
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
            --primary-glow: rgba(13, 124, 131, 0.15);
            --accent: #10b981;
            --text-dark: #0f172a;
            --text-body: #334155;
            --text-muted: #64748b;
            --bg-page: #f8fafc;
            --card-bg: #ffffff;
            --border-color: #e2e8f0;
            --border-highlight: #cbd5e1;
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

        /* Top Notification Bar */
        .top-banner {
            background: linear-gradient(90deg, #095459, #0D7C83, #059669);
            color: #ffffff;
            font-size: 0.875rem;
            padding: 0.5rem 1rem;
            text-align: center;
            font-weight: 500;
        }

        .top-banner a {
            color: #bbf7d0;
            text-decoration: underline;
            margin-left: 0.5rem;
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
            transition: all 0.3s ease;
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

        .brand-logo-img {
            width: 32px;
            height: 32px;
            object-fit: contain;
            border-radius: 6px;
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
            display: flex;
            align-items: center;
            gap: 0.35rem;
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
            position: relative;
            border-bottom: 1px solid var(--border-color);
        }

        .badge-verified {
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

        /* Main Layout */
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

        /* Highlight Feature Cards */
        .grid-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.25rem;
            margin: 1.5rem 0;
        }

        .feature-card {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-md);
            padding: 1.25rem;
            transition: all 0.25s ease;
        }

        .feature-card:hover {
            border-color: var(--primary);
            background: #ffffff;
            box-shadow: 0 8px 24px -4px rgba(13, 124, 131, 0.1);
            transform: translateY(-2px);
        }

        .feature-card-header {
            display: flex;
            align-items: center;
            gap: 0.6rem;
            margin-bottom: 0.6rem;
        }

        .feature-card-icon {
            width: 30px;
            height: 30px;
            border-radius: 8px;
            background: #ffffff;
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
        }

        .feature-card-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--text-dark);
        }

        .feature-card-desc {
            font-size: 0.875rem;
            color: var(--text-muted);
            line-height: 1.55;
        }

        /* Callout Box */
        .callout {
            background: #f0fdf4;
            border-left: 4px solid #10b981;
            border-radius: 0 var(--radius-md) var(--radius-md) 0;
            padding: 1.25rem 1.5rem;
            margin: 1.5rem 0;
        }

        .callout.callout-info {
            background: var(--primary-light);
            border-left-color: var(--primary);
        }

        .callout.callout-warning {
            background: #fffbeb;
            border-left-color: #f59e0b;
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

        /* Account Deletion Box (Special for Google Play) */
        .deletion-box {
            background: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: var(--radius-lg);
            padding: 1.75rem;
            margin-top: 1.5rem;
        }

        .deletion-box h4 {
            color: #991b1b;
            font-size: 1.1rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .deletion-steps {
            list-style: decimal;
            margin-left: 1.5rem;
            margin-top: 0.75rem;
            color: #7f1d1d;
            font-size: 0.925rem;
        }

        .deletion-steps li {
            margin-bottom: 0.4rem;
        }

        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: var(--primary);
            color: #ffffff;
            padding: 0.65rem 1.25rem;
            border-radius: var(--radius-sm);
            text-decoration: none;
            font-weight: 600;
            font-size: 0.9rem;
            margin-top: 1rem;
            transition: all 0.2s ease;
        }

        .btn-action:hover {
            background: var(--primary-dark);
            box-shadow: 0 4px 12px rgba(13, 124, 131, 0.25);
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

        .footer-copy {
            color: #64748b;
            font-size: 0.8rem;
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

        /* Responsive Breakpoints */
        @media (max-width: 900px) {
            .layout-container {
                grid-template-columns: 1fr;
                gap: 1.5rem;
            }

            .sidebar {
                display: none; /* Hide sidebar on small screens for cleaner flow */
            }

            .hero-title {
                font-size: 2rem;
            }

            .content-area {
                padding: 1.5rem;
                border-radius: var(--radius-lg);
            }
        }
    </style>
</head>
<body>

    <!-- Top Notice Banner -->
    <div class="top-banner">
        <span id="banner-text">🛡️ Dokumen Resmi Kebijakan Privasi Zenvi POS — Sesuai Standar Google Play Developer Policy 2026</span>
    </div>

    <!-- Header / Navbar -->
    <header class="header">
        <div class="nav-container">
            <a href="https://zenvi.cellanoma.my.id" class="brand-logo">
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
                <!-- Bilingual Toggle -->
                <div class="lang-switch">
                    <button type="button" class="lang-btn active" id="btn-lang-id" onclick="setLanguage('id')">
                        <span>🇮🇩</span> ID
                    </button>
                    <button type="button" class="lang-btn" id="btn-lang-en" onclick="setLanguage('en')">
                        <span>🇬🇧</span> EN
                    </button>
                </div>
            </div>
        </div>
    </header>

    <!-- Hero Header -->
    <section class="hero">
        <div class="badge-verified">
            <i data-lucide="shield-check" style="width: 16px; height: 16px;"></i>
            <span id="badge-text">Kepatuhan Resmi Google Play Store & Perlindungan Data</span>
        </div>
        <h1 class="hero-title" id="hero-title-text">Kebijakan Privasi Zenvi POS</h1>
        <p class="hero-subtitle" id="hero-subtitle-text">
            Transparansi penuh mengenai pengumpulan, perlindungan, pengelolaan data bisnis, dan izin perangkat dalam ekosistem kasir pintar Zenvi.
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
            <div class="hero-meta-item">
                <i data-lucide="globe" style="width: 16px; height: 16px; color: var(--primary);"></i>
                <span>Domain: <strong>zenvi.cellanoma.my.id</strong></span>
            </div>
        </div>
    </section>

    <!-- Main Content Layout -->
    <main class="layout-container">
        
        <!-- Sidebar Navigation (Desktop) -->
        <aside class="sidebar">
            <div class="sidebar-title" id="toc-title">Daftar Isi Kebijakan</div>
            <ul class="toc-list">
                <li><a href="#intro" class="toc-link"><i data-lucide="info"></i> <span class="toc-t1">Pendahuluan</span></a></li>
                <li><a href="#data-collection" class="toc-link"><i data-lucide="database"></i> <span class="toc-t2">Data yang Dikumpulkan</span></a></li>
                <li><a href="#hardware-permissions" class="toc-link"><i data-lucide="cpu"></i> <span class="toc-t3">Izin Perangkat & Biometrik</span></a></li>
                <li><a href="#data-usage" class="toc-link"><i data-lucide="check-circle-2"></i> <span class="toc-t4">Tujuan Penggunaan Data</span></a></li>
                <li><a href="#third-parties" class="toc-link"><i data-lucide="share-2"></i> <span class="toc-t5">Layanan Pihak Ketiga</span></a></li>
                <li><a href="#security" class="toc-link"><i data-lucide="lock"></i> <span class="toc-t6">Keamanan Data & Enkripsi</span></a></li>
                <li><a href="#account-deletion" class="toc-link"><i data-lucide="trash-2"></i> <span class="toc-t7">Penghapusan Akun & Data</span></a></li>
                <li><a href="#children-privacy" class="toc-link"><i data-lucide="smile"></i> <span class="toc-t8">Privasi Anak-Anak</span></a></li>
                <li><a href="#contact" class="toc-link"><i data-lucide="mail"></i> <span class="toc-t9">Hubungi Kami</span></a></li>
            </ul>
        </aside>

        <!-- Content Area -->
        <div class="content-area">

            <!-- ======================================================= -->
            <!-- BAHASA INDONESIA CONTENT (DEFAULT) -->
            <!-- ======================================================= -->
            <div id="content-id" class="lang-content active">

                <!-- 1. Pendahuluan -->
                <section id="intro" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="info"></i></div>
                        <h2 class="section-title">1. Pendahuluan</h2>
                    </div>
                    <p class="policy-p">
                        Selamat datang di <strong>Zenvi POS</strong> (Point of Sale, Kasir Pintar & Manajemen Bisnis Multi-Outlet) yang dikembangkan dan dikelola oleh <strong>Cellanoma Digital</strong> ("kami", "pengembang"). Kami menghargai dan berkomitmen penuh untuk melindungi privasi serta keamanan data pribadi pengguna, pemilik bisnis (merchant), karyawan kasir, dan pelanggan Anda.
                    </p>
                    <p class="policy-p">
                        Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, memproses, dan melindungi informasi saat Anda mengunduh, mengakses, atau menggunakan aplikasi mobile Zenvi POS di Google Play Store maupun layanan web backend terintegrasi di <code>https://zenvi.cellanoma.my.id</code>.
                    </p>
                    <div class="callout callout-info">
                        <div class="callout-title"><i data-lucide="check-check"></i> Prinsip Dasar Privasi Zenvi</div>
                        <p class="callout-p">
                            Kami <strong>TIDAK AKAN PERNAH MENJUAL, MENYEWAKAN, ATAU MEMPERDAGANGKAN</strong> data transaksi bisnis, informasi keuangan, maupun data pribadi Anda kepada pihak ketiga untuk kepentingan iklan pihak ketiga atau monetisasi data.
                        </p>
                    </div>
                </section>

                <!-- 2. Data yang Dikumpulkan -->
                <section id="data-collection" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="database"></i></div>
                        <h2 class="section-title">2. Informasi & Data yang Kami Kumpulkan</h2>
                    </div>
                    <p class="policy-p">
                        Untuk menjalankan fungsi kasir point of sale yang andal, sinkronisasi inventaris, dan pencatatan keuangan yang akurat, aplikasi mengumpulkan beberapa kategori data:
                    </p>

                    <div class="grid-cards">
                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="user-check"></i></div>
                                <div class="feature-card-title">Data Akun & Profil Bisnis</div>
                            </div>
                            <div class="feature-card-desc">
                                Nama lengkap pemilik/kasir, alamat email, nomor telepon, nama outlet/cabang usaha, logo toko, dan kredensial login (terenkripsi) untuk autentikasi sistem multi-pengguna.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="receipt"></i></div>
                                <div class="feature-card-title">Data Transaksi & Keuangan</div>
                            </div>
                            <div class="feature-card-desc">
                                Daftar katalog produk/jasa, harga, varian, persediaan bahan baku (stok), nomor meja, rincian pesanan, metode pembayaran (Tunai, QRIS, Kartu, Transfer), pajak, diskon, dan catatan pengeluaran operasional outlet.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="users"></i></div>
                                <div class="feature-card-title">Data Pelanggan & Loyalitas</div>
                            </div>
                            <div class="feature-card-desc">
                                Nama pelanggan, nomor WhatsApp/telepon, poin keanggotaan (membership), dan riwayat reservasi meja yang dimasukkan secara sukarela oleh kasir atau pelanggan saat memesan.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="clock"></i></div>
                                <div class="feature-card-title">Data Shift & Presensi Staf</div>
                            </div>
                            <div class="feature-card-desc">
                                Waktu pembukaan/penutupan shift kasir, saldo kas awal/akhir, selisih kas fisik, dan riwayat presensi masuk/pulang karyawan beserta titik lokasi outlet.
                            </div>
                        </div>
                    </div>
                </section>

                <!-- 3. Izin Perangkat & Biometrik -->
                <section id="hardware-permissions" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="cpu"></i></div>
                        <h2 class="section-title">3. Penggunaan Izin Perangkat & Data Biometrik</h2>
                    </div>
                    <p class="policy-p">
                        Aplikasi Zenvi POS memerlukan beberapa izin perangkat Android khusus agar dapat mengoperasikan fitur perangkat keras kasir dan verifikasi kehadiran staf. Berikut adalah penjelasan transparan mengenai fungsi setiap izin:
                    </p>

                    <div class="grid-cards">
                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="camera"></i></div>
                                <div class="feature-card-title">Kamera & Deteksi Wajah (Google ML Kit)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Tujuan:</strong> Mengambil foto selfie presensi absensi karyawan kasir (clock-in / clock-out) serta mengambil foto produk atau bukti nota pengeluaran.<br>
                                <strong>Kepatuhan Biometrik:</strong> Deteksi wajah menggunakan Google ML Kit diproses langsung di perangkat (on-device) semata-mata untuk memverifikasi keaslian wajah kehadiran staf. Kami <strong>TIDAK PERNAH</strong> menyimpan data biometrik untuk profiling atau menjualnya ke pihak ketiga.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="map-pin"></i></div>
                                <div class="feature-card-title">Lokasi GPS (Fine & Coarse Location)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Tujuan:</strong> Memverifikasi radius geofencing lokasi saat staf melakukan presensi masuk di cabang outlet yang sah, serta untuk pengaturan koordinat outlet di peta.<br>
                                <strong>Privasi:</strong> Pelacakan lokasi <strong>HANYA</strong> terjadi pada saat tombol presensi ditekan. Kami <strong>TIDAK</strong> melacak lokasi Anda di latar belakang (background tracking) saat aplikasi ditutup.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="printer"></i></div>
                                <div class="feature-card-title">Bluetooth & Nearby Devices</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Tujuan:</strong> Memindai (Bluetooth Scan) dan menghubungkan perangkat (Bluetooth Connect) dengan printer thermal struk mini (58mm / 80mm ESC/POS) serta Cash Drawer.<br>
                                <strong>Privasi:</strong> Izin ini murni digunakan untuk pengiriman byte stream cetak struk kasir dan tidak mengakses riwayat file atau audio pengguna.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="bell"></i></div>
                                <div class="feature-card-title">Notifikasi Push (Notifications)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Tujuan:</strong> Mengirimkan sinyal pesanan baru, notifikasi Kitchen Display System (KDS), pengingat pergantian shift, dan peringatan stok bahan baku menipis via Firebase Cloud Messaging.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="hard-drive"></i></div>
                                <div class="feature-card-title">Penyimpanan Lokal (SQLite Database)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Tujuan:</strong> Menyimpan cache katalog dan riwayat transaksi offline-first pada database internal perangkat Anda, sehingga kasir dapat terus mencetak struk dan melayani pelanggan meski jaringan internet terputus.
                            </div>
                        </div>
                    </div>
                </section>

                <!-- 4. Tujuan Penggunaan Data -->
                <section id="data-usage" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="check-circle-2"></i></div>
                        <h2 class="section-title">4. Tujuan Penggunaan Data</h2>
                    </div>
                    <p class="policy-p">Data yang dikumpulkan digunakan semata-mata untuk:</p>
                    <ul class="policy-list">
                        <li>Memproses transaksi penjualan, split bill, perhitungan diskon, dan pencetakan bukti bayar (struk kasir).</li>
                        <li>Sinkronisasi data multi-outlet, multi-kasir, dan tampilan pesanan dapur (Kitchen Display) secara real-time.</li>
                        <li>Menghasilkan laporan keuangan harian, laba kotor, grafik performa produk terlaris, dan rekapitulasi shift.</li>
                        <li>Mengelola sistem loyalitas poin anggota dan reservasi meja konsumen.</li>
                        <li>Memastikan keamanan autentikasi akun dan mencegah akses tanpa hak ke sistem kasir Anda.</li>
                    </ul>
                </section>

                <!-- 5. Layanan Pihak Ketiga -->
                <section id="third-parties" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="share-2"></i></div>
                        <h2 class="section-title">5. Penggunaan Layanan Pihak Ketiga</h2>
                    </div>
                    <p class="policy-p">
                        Untuk memberikan stabilitas dan performa kelas enterprise, aplikasi terintegrasi dengan penyedia infrastruktur pihak ketiga yang terpercaya:
                    </p>
                    <ul class="policy-list">
                        <li><strong>Google Play Services:</strong> Untuk distribusi aplikasi, update otomatis, dan kepatuhan sistem operasi Android.</li>
                        <li><strong>Firebase Cloud Messaging (Google):</strong> Untuk pengiriman notifikasi push real-time.</li>
                        <li><strong>Google ML Kit:</strong> Untuk analisis deteksi wajah presensi secara lokal di perangkat.</li>
                        <li><strong>Google Sign-In:</strong> Untuk kemudahan autentikasi login OAuth 2.0 (opsional).</li>
                        <li><strong>Infrastruktur Server Hostinger Cloud:</strong> Server penyimpanan database backend terenkripsi dengan firewall aktif dan sertifikasi SSL.</li>
                    </ul>
                </section>

                <!-- 6. Keamanan Data & Enkripsi -->
                <section id="security" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="lock"></i></div>
                        <h2 class="section-title">6. Keamanan Data & Enkripsi</h2>
                    </div>
                    <p class="policy-p">
                        Kami menerapkan standar industri terbaik untuk melindungi integritas dan kerahasiaan data Anda:
                    </p>
                    <ul class="policy-list">
                        <li><strong>Enkripsi Transport (HTTPS/TLS 1.2+):</strong> Semua komunikasi antara aplikasi Zenvi di ponsel/tablet Anda dan server cloud diamankan dengan enkripsi SSL/TLS berlapis.</li>
                        <li><strong>Hashing Kata Sandi:</strong> Kata sandi akun dienkripsi menggunakan algoritma <code>bcrypt</code> satu arah dan tidak dapat dilihat bahkan oleh tim teknis kami.</li>
                        <li><strong>Akses Berbasis Token:</strong> Setiap sesi login menggunakan token otorisasi aman (Laravel Sanctum) dengan masa berlaku dan pembatasan hak akses role (Owner / Kasir).</li>
                    </ul>
                </section>

                <!-- 7. Penghapusan Akun & Data (Google Play Compliance) -->
                <section id="account-deletion" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="trash-2"></i></div>
                        <h2 class="section-title">7. Hak Pengguna & Prosedur Penghapusan Akun / Data</h2>
                    </div>
                    <p class="policy-p">
                        Sesuai dengan <strong>Google Play Data Safety Policy</strong> dan prinsip perlindungan privasi internasional, setiap pengguna memiliki hak penuh untuk mengakses, memperbarui, atau menghapus akun beserta seluruh data usaha yang tersimpan di server kami kapan saja.
                    </p>

                    <div class="deletion-box">
                        <h4><i data-lucide="alert-triangle"></i> Prosedur Permintaan Penghapusan Akun & Data Bisnis</h4>
                        <p style="color: #7f1d1d; font-size: 0.95rem;">
                            Jika Anda memutuskan untuk berhenti menggunakan Zenvi dan ingin menghapus seluruh profil bisnis, riwayat penjualan, inventaris, dan akun staf secara permanen:
                        </p>
                        <ol class="deletion-steps">
                            <li><strong>Melalui Aplikasi Zenvi:</strong> Masuk ke menu <code>Pengaturan Toko &gt; Profil Akun &gt; Hapus Akun &amp; Data Toko</code>.</li>
                            <li><strong>Melalui Permohonan Email:</strong> Kirimkan email resmi dari alamat email yang terdaftar sebagai pemilik usaha ke: <a href="mailto:cellanomadigital@gmail.com?subject=Permohonan%20Penghapusan%20Akun%20Zenvi%20POS" style="color: #991b1b; font-weight: bold;">cellanomadigital@gmail.com</a> dengan subjek <em>"Permohonan Penghapusan Akun Zenvi POS"</em>.</li>
                            <li>Sertakan nama toko/outlet dan email terdaftar untuk proses verifikasi kepemilikan.</li>
                            <li><strong>Waktu Pemrosesan:</strong> Seluruh data akun, riwayat transaksi, dan file terkait akan dihapus secara permanen dari server aktif kami dalam waktu maksimal <strong>7 (tujuh) hari kerja</strong> setelah verifikasi selesai.</li>
                        </ol>
                        <a href="mailto:cellanomadigital@gmail.com?subject=Permohonan%20Penghapusan%20Akun%20Zenvi%20POS" class="btn-action" style="background: #dc2626;">
                            <i data-lucide="mail"></i> Kirim Permohonan Hapus Akun via Email
                        </a>
                    </div>
                </section>

                <!-- 8. Privasi Anak-Anak -->
                <section id="children-privacy" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="smile"></i></div>
                        <h2 class="section-title">8. Privasi Anak-Anak</h2>
                    </div>
                    <p class="policy-p">
                        Layanan Zenvi POS dirancang khusus untuk pelaku usaha, pengelola toko, kasir, dan operasional bisnis komersial. Kami tidak secara sengaja mengumpulkan atau meminta data pribadi dari anak-anak di bawah usia 13 tahun. Jika Anda mengetahui ada data anak di bawah umur yang masuk tanpa izin orang tua/wali, harap segera hubungi kami agar kami dapat menghapus data tersebut secepatnya.
                    </p>
                </section>

                <!-- 9. Perubahan Kebijakan -->
                <section id="policy-changes" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="refresh-cw"></i></div>
                        <h2 class="section-title">9. Pembaruan Kebijakan Privasi</h2>
                    </div>
                    <p class="policy-p">
                        Kami dapat meninjau dan memperbarui Kebijakan Privasi ini dari waktu ke waktu guna menyesuaikan dengan pembaruan fitur aplikasi, rilis perangkat keras baru, atau regulasi hukum yang berlaku. Setiap perubahan penting akan dicantumkan di halaman ini dengan tanggal pembaruan terbaru.
                    </p>
                </section>

                <!-- 10. Kontak -->
                <section id="contact" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="mail"></i></div>
                        <h2 class="section-title">10. Kontak & Pengembang</h2>
                    </div>
                    <p class="policy-p">
                        Jika Anda memiliki pertanyaan, keluhan, saran, atau permohonan terkait data privasi Anda di Zenvi POS, silakan hubungi tim pengembang kami melalui saluran resmi berikut:
                    </p>

                    <div class="contact-grid">
                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="mail"></i></div>
                            <div>
                                <div class="contact-label">Email Dukungan & Privasi</div>
                                <a href="mailto:cellanomadigital@gmail.com" class="contact-val">cellanomadigital@gmail.com</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="globe"></i></div>
                            <div>
                                <div class="contact-label">Website Resmi</div>
                                <a href="https://zenvi.cellanoma.my.id" target="_blank" class="contact-val">zenvi.cellanoma.my.id</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="building-2"></i></div>
                            <div>
                                <div class="contact-label">Badan Pengembang</div>
                                <div class="contact-val">Cellanoma Digital Indonesia</div>
                            </div>
                        </div>
                    </div>
                </section>

            </div>

            <!-- ======================================================= -->
            <!-- ENGLISH CONTENT (FOR GOOGLE PLAY STORE AUDIT & GLOBAL) -->
            <!-- ======================================================= -->
            <div id="content-en" class="lang-content">

                <!-- 1. Introduction -->
                <section id="intro-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="info"></i></div>
                        <h2 class="section-title">1. Introduction</h2>
                    </div>
                    <p class="policy-p">
                        Welcome to <strong>Zenvi POS</strong> (Point of Sale, Smart Cashier & Multi-Outlet Business Management System) developed and operated by <strong>Cellanoma Digital</strong> ("we", "us", or "our"). We are deeply committed to respecting and protecting the privacy, security, and integrity of personal and business data belonging to our merchant users, cashiers, and store customers.
                    </p>
                    <p class="policy-p">
                        This Privacy Policy outlines how we collect, use, store, process, and safeguard your data when you download, install, or use the Zenvi POS mobile application available on Google Play Store, or access its integrated backend portal at <code>https://zenvi.cellanoma.my.id</code>.
                    </p>
                    <div class="callout callout-info">
                        <div class="callout-title"><i data-lucide="check-check"></i> Core Privacy Commitment</div>
                        <p class="callout-p">
                            We <strong>NEVER SELL, RENT, OR TRADE</strong> your transaction records, customer details, or personal information to any third parties for third-party advertising or commercial data brokering.
                        </p>
                    </div>
                </section>

                <!-- 2. Data Collection -->
                <section id="data-collection-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="database"></i></div>
                        <h2 class="section-title">2. Information We Collect</h2>
                    </div>
                    <p class="policy-p">
                        To operate an offline-capable, high-reliability Point of Sale system, real-time inventory management, and financial reporting, we collect the following types of information:
                    </p>

                    <div class="grid-cards">
                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="user-check"></i></div>
                                <div class="feature-card-title">Account & Business Profile Data</div>
                            </div>
                            <div class="feature-card-desc">
                                Full name of store owner/cashier, email address, phone number, store/outlet name, store logo, and securely hashed login credentials for role-based multi-user authorization.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="receipt"></i></div>
                                <div class="feature-card-title">Sales & Financial Transactions</div>
                            </div>
                            <div class="feature-card-desc">
                                Catalog items, prices, inventory raw materials, table allocations, order items, payment methods (Cash, QRIS, Card, Bank Transfer), tax, discounts, and store operational expense entries.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="users"></i></div>
                                <div class="feature-card-title">Customer & Loyalty Data</div>
                            </div>
                            <div class="feature-card-desc">
                                Customer name, WhatsApp/phone number, membership loyalty reward points, and table reservation records entered voluntarily during order checkout.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="clock"></i></div>
                                <div class="feature-card-title">Shift & Attendance Records</div>
                            </div>
                            <div class="feature-card-desc">
                                Cash register shift opening/closing timestamps, initial/final cash balance, physical cash variances, and employee attendance clock-in/out logs.
                            </div>
                        </div>
                    </div>
                </section>

                <!-- 3. Hardware & Biometrics -->
                <section id="hardware-permissions-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="cpu"></i></div>
                        <h2 class="section-title">3. Device Permissions & Biometric Compliance</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi POS utilizes specific Android hardware permissions to integrate POS peripherals and prevent fraudulent staff attendance. Here is a transparent breakdown:
                    </p>

                    <div class="grid-cards">
                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="camera"></i></div>
                                <div class="feature-card-title">Camera & Face Detection (Google ML Kit)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Purpose:</strong> Taking selfie photos for employee attendance verification (clock-in / clock-out) and capturing product photos or receipt proof.<br>
                                <strong>Biometric Safety:</strong> Facial landmark analysis via Google ML Kit is executed on-device solely to confirm human liveness and identity during work shifts. We <strong>DO NOT</strong> store raw biometric templates or share facial data with third parties for surveillance or marketing.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="map-pin"></i></div>
                                <div class="feature-card-title">GPS Location (Fine & Coarse)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Purpose:</strong> Validating geofence radius when staff clocks in at registered store outlets, and setting store map coordinates.<br>
                                <strong>Privacy:</strong> Location coordinates are queried <strong>ONLY</strong> when the attendance button is pressed. We do <strong>NOT</strong> track user location in the background when the app is inactive.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="printer"></i></div>
                                <div class="feature-card-title">Bluetooth & Nearby Devices</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Purpose:</strong> Scanning (Bluetooth Scan) and establishing connections (Bluetooth Connect) with wireless 58mm/80mm ESC/POS thermal receipt printers and Cash Drawers.<br>
                                <strong>Privacy:</strong> This permission is strictly utilized for sending thermal print payloads; it does not collect user media, audio, or browsing history.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="bell"></i></div>
                                <div class="feature-card-title">Push Notifications</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Purpose:</strong> Delivering real-time kitchen order updates (KDS), shift handover alerts, and low inventory notifications via Firebase Cloud Messaging.
                            </div>
                        </div>

                        <div class="feature-card">
                            <div class="feature-card-header">
                                <div class="feature-card-icon"><i data-lucide="hard-drive"></i></div>
                                <div class="feature-card-title">Local Storage (SQLite Database)</div>
                            </div>
                            <div class="feature-card-desc">
                                <strong>Purpose:</strong> Storing offline-first transaction queues locally on your device, ensuring uninterrupted cashier sales even during unstable network connectivity.
                            </div>
                        </div>
                    </div>
                </section>

                <!-- 4. How We Use Data -->
                <section id="data-usage-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="check-circle-2"></i></div>
                        <h2 class="section-title">4. How We Use Your Information</h2>
                    </div>
                    <p class="policy-p">We utilize collected information exclusively to:</p>
                    <ul class="policy-list">
                        <li>Process sales transactions, bill splitting, automated discounts, and print customer sales receipts.</li>
                        <li>Synchronize live order tickets between multiple cashiers, mobile servers, and the kitchen display (KDS).</li>
                        <li>Generate daily profit & loss summaries, shift reconciliations, and sales analytics.</li>
                        <li>Administer loyalty points, promotional discounts, and table bookings.</li>
                        <li>Enforce strict user authentication to prevent unauthorized store access.</li>
                    </ul>
                </section>

                <!-- 5. Third-Party Services -->
                <section id="third-parties-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="share-2"></i></div>
                        <h2 class="section-title">5. Third-Party Service Providers</h2>
                    </div>
                    <p class="policy-p">
                        To maintain high reliability, scalability, and security, we integrate trusted third-party technology providers:
                    </p>
                    <ul class="policy-list">
                        <li><strong>Google Play Services:</strong> For secure app distribution, automated updates, and platform integrity.</li>
                        <li><strong>Firebase Cloud Messaging (Google):</strong> For instant push notifications.</li>
                        <li><strong>Google ML Kit:</strong> For on-device face verification.</li>
                        <li><strong>Google Sign-In:</strong> For optional OAuth 2.0 single sign-on authentication.</li>
                        <li><strong>Hostinger Cloud Infrastructure:</strong> For encrypted database hosting and SSL API termination.</li>
                    </ul>
                </section>

                <!-- 6. Data Security -->
                <section id="security-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="lock"></i></div>
                        <h2 class="section-title">6. Data Security & Encryption</h2>
                    </div>
                    <p class="policy-p">
                        We deploy industry-grade defense measures to secure your store operations:
                    </p>
                    <ul class="policy-list">
                        <li><strong>In-Transit Encryption (HTTPS / TLS 1.2+):</strong> All network traffic between your mobile devices and our servers is encrypted using modern cryptographic protocols.</li>
                        <li><strong>Password Protection:</strong> Account passwords are automatically hashed with the one-way <code>bcrypt</code> algorithm.</li>
                        <li><strong>Token-Based Access:</strong> Every active session is governed by cryptographically signed bearer tokens (Laravel Sanctum) with role-level barriers.</li>
                    </ul>
                </section>

                <!-- 7. Account & Data Deletion (Google Play Compliance) -->
                <section id="account-deletion-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="trash-2"></i></div>
                        <h2 class="section-title">7. User Rights & Account/Data Deletion</h2>
                    </div>
                    <p class="policy-p">
                        In full compliance with <strong>Google Play Store Data Safety & Deletion Requirements</strong>, all users maintain the right to inspect, update, or permanently delete their account and associated store data at any time.
                    </p>

                    <div class="deletion-box">
                        <h4><i data-lucide="alert-triangle"></i> How to Request Complete Account & Data Deletion</h4>
                        <p style="color: #7f1d1d; font-size: 0.95rem;">
                            If you wish to terminate your Zenvi account and request the permanent erasure of all associated business profiles, order history, inventory, and staff accounts:
                        </p>
                        <ol class="deletion-steps">
                            <li><strong>In-App Self Service:</strong> Open Zenvi POS &gt; Navigate to <code>Store Settings &gt; Account Profile &gt; Delete Account &amp; Data</code>.</li>
                            <li><strong>Email Request:</strong> Send an official deletion request from your registered owner email to: <a href="mailto:cellanomadigital@gmail.com?subject=Zenvi%20POS%20Account%20Deletion%20Request" style="color: #991b1b; font-weight: bold;">cellanomadigital@gmail.com</a> with subject <em>"Zenvi POS Account Deletion Request"</em>.</li>
                            <li>Include your registered store name and email address for ownership validation.</li>
                            <li><strong>Fulfillment Timeline:</strong> All corresponding user credentials, sales logs, and server records will be permanently purged from our active databases within <strong>7 (seven) business days</strong> following identity verification.</li>
                        </ol>
                        <a href="mailto:cellanomadigital@gmail.com?subject=Zenvi%20POS%20Account%20Deletion%20Request" class="btn-action" style="background: #dc2626;">
                            <i data-lucide="mail"></i> Submit Account Deletion Request via Email
                        </a>
                    </div>
                </section>

                <!-- 8. Children's Privacy -->
                <section id="children-privacy-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="smile"></i></div>
                        <h2 class="section-title">8. Children's Privacy</h2>
                    </div>
                    <p class="policy-p">
                        Zenvi POS is strictly intended for commercial store owners, business operators, and cashier staff. We do not knowingly solicit or collect data from children under 13 years of age. If you believe a minor has submitted personal data without parental consent, please contact us immediately for prompt deletion.
                    </p>
                </section>

                <!-- 9. Policy Changes -->
                <section id="policy-changes-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="refresh-cw"></i></div>
                        <h2 class="section-title">9. Changes to This Privacy Policy</h2>
                    </div>
                    <p class="policy-p">
                        We may periodically revise this Privacy Policy to reflect application updates, new hardware capabilities, or regulatory changes. The most current version will always remain accessible on this page with the latest revision date.
                    </p>
                </section>

                <!-- 10. Contact Us -->
                <section id="contact-en" class="policy-section">
                    <div class="section-header">
                        <div class="section-icon"><i data-lucide="mail"></i></div>
                        <h2 class="section-title">10. Contact & Developer Information</h2>
                    </div>
                    <p class="policy-p">
                        For any inquiries, privacy concerns, or data protection requests regarding Zenvi POS, please contact our official team:
                    </p>

                    <div class="contact-grid">
                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="mail"></i></div>
                            <div>
                                <div class="contact-label">Support & Privacy Email</div>
                                <a href="mailto:cellanomadigital@gmail.com" class="contact-val">cellanomadigital@gmail.com</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="globe"></i></div>
                            <div>
                                <div class="contact-label">Official Portal</div>
                                <a href="https://zenvi.cellanoma.my.id" target="_blank" class="contact-val">zenvi.cellanoma.my.id</a>
                            </div>
                        </div>

                        <div class="contact-item">
                            <div class="contact-icon"><i data-lucide="building-2"></i></div>
                            <div>
                                <div class="contact-label">Developer Entity</div>
                                <div class="contact-val">Cellanoma Digital Indonesia</div>
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
            <div class="brand-logo" style="justify-content: center; filter: brightness(1.2);">
                <div class="brand-logo-icon" style="width: 32px; height: 32px;">
                    <svg width="20" height="20" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect width="100" height="100" rx="20" fill="#0D7C83"/>
                        <path d="M37.2 25H25L50 75L75 25H43.8" stroke="white" stroke-width="8" stroke-linejoin="miter" stroke-linecap="square"/>
                    </svg>
                </div>
                <div style="text-align: left;">
                    <div style="font-size: 1.1rem; font-weight: 800; color: #ffffff;">Zenvi POS</div>
                    <div style="font-size: 0.7rem; color: #14b8a6;">By Cellanoma Digital</div>
                </div>
            </div>

            <div class="footer-links">
                <a href="#intro" class="footer-link" onclick="setLanguage('id')">Kebijakan Privasi (ID)</a>
                <a href="#intro-en" class="footer-link" onclick="setLanguage('en')">Privacy Policy (EN)</a>
                <a href="#account-deletion" class="footer-link">Hapus Akun / Account Deletion</a>
                <a href="https://zenvi.cellanoma.my.id" class="footer-link">Portal Zenvi</a>
            </div>

            <div class="footer-copy">
                &copy; {{ date('Y') }} Zenvi POS by Cellanoma Digital. All Rights Reserved.<br>
                Published for Google Play Developer Compliance & User Data Protection.
            </div>
        </div>
    </footer>

    <!-- Scripts -->
    <script>
        // Initialize Lucide Icons
        lucide.createIcons();

        // Language Switcher Function
        function setLanguage(lang) {
            const contentId = document.getElementById('content-id');
            const contentEn = document.getElementById('content-en');
            const btnId = document.getElementById('btn-lang-id');
            const btnEn = document.getElementById('btn-lang-en');

            const heroTitle = document.getElementById('hero-title-text');
            const heroSub = document.getElementById('hero-subtitle-text');
            const badgeText = document.getElementById('badge-text');
            const bannerText = document.getElementById('banner-text');
            const tocTitle = document.getElementById('toc-title');

            if (lang === 'en') {
                contentId.classList.remove('active');
                contentEn.classList.add('active');
                btnId.classList.remove('active');
                btnEn.classList.add('active');

                heroTitle.innerText = 'Zenvi POS Privacy Policy';
                heroSub.innerText = 'Full transparency regarding data collection, business security, user rights, and device hardware permissions in Zenvi.';
                badgeText.innerText = 'Official Google Play Store & User Data Compliance';
                bannerText.innerText = '🛡️ Official Zenvi POS Privacy Policy Document — Google Play Developer Policy 2026 Compliant';
                tocTitle.innerText = 'Table of Contents';

                // Update TOC labels
                updateTocLabels('en');

                // Update URL parameter without page reload
                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'en');
                window.history.replaceState({}, '', newUrl);
            } else {
                contentEn.classList.remove('active');
                contentId.classList.add('active');
                btnEn.classList.remove('active');
                btnId.classList.add('active');

                heroTitle.innerText = 'Kebijakan Privasi Zenvi POS';
                heroSub.innerText = 'Transparansi penuh mengenai pengumpulan, perlindungan, pengelolaan data bisnis, dan izin perangkat dalam ekosistem kasir pintar Zenvi.';
                badgeText.innerText = 'Kepatuhan Resmi Google Play Store & Perlindungan Data';
                bannerText.innerText = '🛡️ Dokumen Resmi Kebijakan Privasi Zenvi POS — Sesuai Standar Google Play Developer Policy 2026';
                tocTitle.innerText = 'Daftar Isi Kebijakan';

                // Update TOC labels
                updateTocLabels('id');

                // Update URL parameter without page reload
                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'id');
                window.history.replaceState({}, '', newUrl);
            }

            // Re-create lucide icons for freshly displayed elements
            setTimeout(() => {
                lucide.createIcons();
            }, 50);
        }

        function updateTocLabels(lang) {
            const map = {
                id: ['Pendahuluan', 'Data yang Dikumpulkan', 'Izin Perangkat & Biometrik', 'Tujuan Penggunaan Data', 'Layanan Pihak Ketiga', 'Keamanan Data & Enkripsi', 'Penghapusan Akun & Data', 'Privasi Anak-Anak', 'Hubungi Kami'],
                en: ['Introduction', 'Information We Collect', 'Device & Biometric Permissions', 'How We Use Data', 'Third-Party Services', 'Data Security & Encryption', 'Account & Data Deletion', 'Children’s Privacy', 'Contact & Developer']
            };
            const labels = map[lang] || map.id;
            for (let i = 1; i <= 9; i++) {
                const el = document.querySelector('.toc-t' + i);
                if (el) el.innerText = labels[i-1];
            }
        }

        // On Page Load: Check URL parameter or browser language
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
