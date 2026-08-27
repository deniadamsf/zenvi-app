<!DOCTYPE html>
<html lang="{{ request('lang') == 'en' ? 'en' : 'id' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Zenvi POS — Aplikasi Kasir Pintar & Manajemen Bisnis Multi-Outlet Modern</title>
    <meta name="description" content="Zenvi POS adalah aplikasi kasir point of sale modern untuk Kafe, Restoran, Retail, dan Usaha Jasa. Dilengkapi fitur Offline-First, Kitchen Display (KDS), Presensi Wajah AI, dan QR Menu Meja.">
    <meta name="keywords" content="zenvi pos, aplikasi kasir, point of sale indonesia, kasir restoran, kasir kafe, kds, offline pos, kasir multi outlet, presensi wajah">
    <meta name="robots" content="index, follow">

    <!-- Open Graph / Social Meta -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://zenvi.cellanoma.my.id/">
    <meta property="og:title" content="Zenvi POS — Aplikasi Kasir Pintar & Manajemen Bisnis Multi-Outlet">
    <meta property="og:description" content="Tingkatkan omzet dan efisiensi bisnis Anda dengan Zenvi POS. Solusi kasir offline-first, kitchen display, presensi AI, dan QR menu digital.">
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
            --primary-glow: rgba(13, 124, 131, 0.2);
            --accent: #10b981;
            --accent-glow: rgba(16, 185, 129, 0.2);
            --dark: #0f172a;
            --dark-surface: #1e293b;
            --text-dark: #0f172a;
            --text-body: #334155;
            --text-muted: #64748b;
            --bg-page: #f8fafc;
            --card-bg: #ffffff;
            --border-color: #e2e8f0;
            --radius-sm: 8px;
            --radius-md: 14px;
            --radius-lg: 22px;
            --radius-xl: 32px;
            --shadow-subtle: 0 4px 20px -2px rgba(15, 23, 42, 0.05);
            --shadow-elevated: 0 20px 40px -10px rgba(13, 124, 131, 0.12), 0 8px 16px -4px rgba(15, 23, 42, 0.04);
            --shadow-glow: 0 10px 30px rgba(13, 124, 131, 0.25);
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
            line-height: 1.65;
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
        }

        /* Top Announcement Bar */
        .announcement-bar {
            background: linear-gradient(90deg, #095459 0%, #0D7C83 50%, #059669 100%);
            color: #ffffff;
            font-size: 0.85rem;
            font-weight: 500;
            padding: 0.5rem 1rem;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }

        .announcement-bar a {
            color: #bbf7d0;
            text-decoration: underline;
            font-weight: 600;
        }

        /* Header / Navbar */
        .navbar {
            position: sticky;
            top: 0;
            z-index: 100;
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(14px);
            -webkit-backdrop-filter: blur(14px);
            border-bottom: 1px solid var(--border-color);
            transition: all 0.3s ease;
        }

        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0.9rem 1.5rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 0.85rem;
            text-decoration: none;
            color: var(--text-dark);
        }

        .brand-icon {
            width: 42px;
            height: 42px;
            background: var(--primary);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 12px rgba(13, 124, 131, 0.35);
        }

        .brand-name {
            font-size: 1.45rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            color: var(--text-dark);
            line-height: 1;
        }

        .brand-tag {
            font-size: 0.75rem;
            font-weight: 600;
            color: var(--primary);
            text-transform: uppercase;
            letter-spacing: 0.06em;
            margin-top: 2px;
        }

        .nav-menu {
            display: flex;
            align-items: center;
            gap: 2rem;
            list-style: none;
        }

        .nav-link {
            text-decoration: none;
            color: var(--text-body);
            font-size: 0.925rem;
            font-weight: 600;
            transition: color 0.2s ease;
        }

        .nav-link:hover {
            color: var(--primary);
        }

        .nav-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        /* Language Switcher */
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
            padding: 0.35rem 0.8rem;
            border-radius: 999px;
            font-size: 0.8rem;
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

        .btn-nav-cta {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            background: var(--primary);
            color: #ffffff;
            padding: 0.6rem 1.25rem;
            border-radius: 999px;
            font-size: 0.875rem;
            font-weight: 700;
            text-decoration: none;
            box-shadow: 0 4px 12px rgba(13, 124, 131, 0.25);
            transition: all 0.25s ease;
        }

        .btn-nav-cta:hover {
            background: var(--primary-dark);
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(13, 124, 131, 0.35);
        }

        /* Hero Section */
        .hero-section {
            position: relative;
            background: radial-gradient(circle at 50% 20%, #d8f3f5 0%, #f0fdfa 45%, #f8fafc 85%);
            padding: 5rem 1.5rem 4rem;
            text-align: center;
            overflow: hidden;
        }

        .hero-container {
            max-width: 980px;
            margin: 0 auto;
            position: relative;
            z-index: 2;
        }

        .hero-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: #ffffff;
            border: 1px solid rgba(13, 124, 131, 0.25);
            padding: 0.45rem 1.15rem;
            border-radius: 999px;
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 1.5rem;
            box-shadow: 0 4px 12px rgba(13, 124, 131, 0.08);
        }

        .hero-title {
            font-size: 3.5rem;
            font-weight: 900;
            color: var(--text-dark);
            letter-spacing: -0.04em;
            line-height: 1.12;
            margin-bottom: 1.25rem;
        }

        .hero-title .highlight {
            background: linear-gradient(135deg, #0D7C83 0%, #059669 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero-desc {
            font-size: 1.2rem;
            color: var(--text-muted);
            max-width: 720px;
            margin: 0 auto 2.5rem;
            line-height: 1.6;
        }

        .hero-buttons {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 1.25rem;
            flex-wrap: wrap;
            margin-bottom: 3.5rem;
        }

        .btn-primary-hero {
            display: inline-flex;
            align-items: center;
            gap: 0.6rem;
            background: var(--primary);
            color: #ffffff;
            padding: 0.9rem 2rem;
            border-radius: 999px;
            font-size: 1.05rem;
            font-weight: 700;
            text-decoration: none;
            box-shadow: var(--shadow-glow);
            transition: all 0.25s ease;
        }

        .btn-primary-hero:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
            box-shadow: 0 14px 32px rgba(13, 124, 131, 0.35);
        }

        .btn-secondary-hero {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: #ffffff;
            color: var(--text-dark);
            border: 1px solid var(--border-color);
            padding: 0.9rem 1.75rem;
            border-radius: 999px;
            font-size: 1.05rem;
            font-weight: 600;
            text-decoration: none;
            box-shadow: var(--shadow-subtle);
            transition: all 0.25s ease;
        }

        .btn-secondary-hero:hover {
            background: #f8fafc;
            border-color: var(--primary);
            color: var(--primary);
        }

        /* Hero App Mockup / Feature Showcase */
        .hero-mockup-wrap {
            max-width: 1040px;
            margin: 0 auto;
            background: #ffffff;
            border: 1px solid rgba(13, 124, 131, 0.2);
            border-radius: var(--radius-xl);
            padding: 1.5rem;
            box-shadow: var(--shadow-elevated);
            position: relative;
        }

        .mockup-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-bottom: 1.25rem;
            border-bottom: 1px solid var(--border-color);
            margin-bottom: 1.5rem;
        }

        .mockup-dots {
            display: flex;
            gap: 6px;
        }

        .mockup-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }

        .mockup-dot.red { background: #ef4444; }
        .mockup-dot.yellow { background: #f59e0b; }
        .mockup-dot.green { background: #10b981; }

        .mockup-title-bar {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }

        /* Mockup Grid Inside */
        .mockup-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1rem;
            text-align: left;
        }

        .mockup-card {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-md);
            padding: 1.25rem;
            transition: all 0.2s ease;
        }

        .mockup-card:hover {
            background: #ffffff;
            border-color: var(--primary);
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(13, 124, 131, 0.08);
        }

        .mockup-card-icon {
            width: 38px;
            height: 38px;
            background: var(--primary-light);
            color: var(--primary);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 0.85rem;
        }

        .mockup-card-title {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--text-dark);
            margin-bottom: 0.35rem;
        }

        .mockup-card-sub {
            font-size: 0.8rem;
            color: var(--text-muted);
            line-height: 1.45;
        }

        /* Trust Metric Stats */
        .stats-section {
            background: #ffffff;
            border-top: 1px solid var(--border-color);
            border-bottom: 1px solid var(--border-color);
            padding: 3rem 1.5rem;
        }

        .stats-container {
            max-width: 1100px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 2rem;
            text-align: center;
        }

        .stat-num {
            font-size: 2.5rem;
            font-weight: 900;
            color: var(--primary);
            letter-spacing: -0.03em;
            line-height: 1;
            margin-bottom: 0.35rem;
        }

        .stat-label {
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--text-body);
        }

        /* Features Section */
        .section {
            padding: 6rem 1.5rem;
            max-width: 1200px;
            margin: 0 auto;
        }

        .section-header-center {
            text-align: center;
            max-width: 760px;
            margin: 0 auto 4rem;
        }

        .section-tag {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            background: var(--primary-light);
            color: var(--primary);
            padding: 0.35rem 0.95rem;
            border-radius: 999px;
            font-size: 0.825rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 1rem;
        }

        .section-h2 {
            font-size: 2.6rem;
            font-weight: 900;
            color: var(--text-dark);
            letter-spacing: -0.03em;
            line-height: 1.2;
            margin-bottom: 1rem;
        }

        .section-p {
            font-size: 1.05rem;
            color: var(--text-muted);
            line-height: 1.6;
        }

        /* Feature Cards Grid */
        .feature-grid-8 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(270px, 1fr));
            gap: 1.75rem;
        }

        .feature-box {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-lg);
            padding: 2rem 1.75rem;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
            display: flex;
            flex-direction: column;
        }

        .feature-box:hover {
            border-color: var(--primary);
            box-shadow: 0 16px 36px -4px rgba(13, 124, 131, 0.12);
            transform: translateY(-4px);
        }

        .feature-box-icon {
            width: 48px;
            height: 48px;
            background: var(--primary-light);
            color: var(--primary);
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1.25rem;
        }

        .feature-box-title {
            font-size: 1.25rem;
            font-weight: 800;
            color: var(--text-dark);
            margin-bottom: 0.65rem;
            letter-spacing: -0.02em;
        }

        .feature-box-desc {
            font-size: 0.925rem;
            color: var(--text-muted);
            line-height: 1.6;
            flex-grow: 1;
        }

        /* How it works */
        .how-it-works-bg {
            background: linear-gradient(180deg, #f0fdfa 0%, #f8fafc 100%);
            border-top: 1px solid var(--border-color);
            border-bottom: 1px solid var(--border-color);
            padding: 6rem 1.5rem;
        }

        .steps-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 2rem;
            max-width: 1100px;
            margin: 0 auto;
        }

        .step-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-lg);
            padding: 2.25rem 1.75rem;
            text-align: center;
            position: relative;
            box-shadow: var(--shadow-subtle);
        }

        .step-num {
            width: 44px;
            height: 44px;
            background: var(--primary);
            color: #ffffff;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 900;
            font-size: 1.2rem;
            margin: 0 auto 1.25rem;
            box-shadow: 0 4px 12px rgba(13, 124, 131, 0.3);
        }

        .step-title {
            font-size: 1.2rem;
            font-weight: 800;
            color: var(--text-dark);
            margin-bottom: 0.65rem;
        }

        .step-desc {
            font-size: 0.9rem;
            color: var(--text-muted);
            line-height: 1.55;
        }

        /* Industry Badges */
        .industries-wrap {
            display: flex;
            justify-content: center;
            gap: 1rem;
            flex-wrap: wrap;
            margin-top: 2rem;
        }

        .industry-pill {
            background: #ffffff;
            border: 1px solid var(--border-color);
            padding: 0.75rem 1.5rem;
            border-radius: 999px;
            display: flex;
            align-items: center;
            gap: 0.6rem;
            font-weight: 700;
            font-size: 0.95rem;
            color: var(--text-dark);
            box-shadow: var(--shadow-subtle);
        }

        /* FAQ Section */
        .faq-container {
            max-width: 860px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }

        .faq-item {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-md);
            padding: 1.5rem;
            transition: all 0.2s ease;
        }

        .faq-q {
            font-size: 1.1rem;
            font-weight: 800;
            color: var(--text-dark);
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .faq-a {
            font-size: 0.95rem;
            color: var(--text-muted);
            line-height: 1.6;
        }

        /* CTA Banner */
        .cta-banner {
            background: linear-gradient(135deg, #095459 0%, #0D7C83 50%, #059669 100%);
            border-radius: var(--radius-xl);
            padding: 4.5rem 2rem;
            text-align: center;
            color: #ffffff;
            max-width: 1200px;
            margin: 0 auto 5rem;
            box-shadow: 0 24px 48px -8px rgba(13, 124, 131, 0.35);
            position: relative;
            overflow: hidden;
        }

        .cta-h2 {
            font-size: 2.8rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            line-height: 1.2;
            margin-bottom: 1rem;
        }

        .cta-p {
            font-size: 1.15rem;
            color: #ccfbf1;
            max-width: 650px;
            margin: 0 auto 2.5rem;
        }

        .btn-cta-white {
            display: inline-flex;
            align-items: center;
            gap: 0.6rem;
            background: #ffffff;
            color: var(--primary-dark);
            padding: 0.95rem 2.25rem;
            border-radius: 999px;
            font-size: 1.05rem;
            font-weight: 800;
            text-decoration: none;
            box-shadow: 0 10px 24px rgba(0, 0, 0, 0.15);
            transition: all 0.25s ease;
        }

        .btn-cta-white:hover {
            transform: translateY(-2px);
            box-shadow: 0 16px 32px rgba(0, 0, 0, 0.2);
            background: #f8fafc;
        }

        /* Footer */
        .footer {
            background: #0f172a;
            color: #94a3b8;
            padding: 4.5rem 1.5rem 2.5rem;
            border-top: 1px solid #1e293b;
        }

        .footer-grid {
            max-width: 1200px;
            margin: 0 auto 3.5rem;
            display: grid;
            grid-template-columns: 2fr 1fr 1fr 1fr;
            gap: 3rem;
        }

        .footer-col-title {
            color: #ffffff;
            font-size: 0.95rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 1.25rem;
        }

        .footer-links {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
        }

        .footer-link {
            color: #94a3b8;
            text-decoration: none;
            font-size: 0.9rem;
            transition: color 0.2s ease;
        }

        .footer-link:hover {
            color: #ffffff;
        }

        .footer-bottom {
            max-width: 1200px;
            margin: 0 auto;
            padding-top: 2rem;
            border-top: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.85rem;
            color: #64748b;
            flex-wrap: wrap;
            gap: 1rem;
        }

        /* Bilingual Switcher Classes */
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
        @media (max-width: 960px) {
            .hero-title { font-size: 2.6rem; }
            .mockup-grid { grid-template-columns: repeat(2, 1fr); }
            .stats-container { grid-template-columns: repeat(2, 1fr); }
            .steps-grid { grid-template-columns: 1fr; }
            .footer-grid { grid-template-columns: 1fr 1fr; gap: 2rem; }
            .nav-menu { display: none; }
        }

        @media (max-width: 640px) {
            .hero-title { font-size: 2.1rem; }
            .hero-desc { font-size: 1rem; }
            .section-h2 { font-size: 2rem; }
            .cta-h2 { font-size: 2rem; }
            .mockup-grid { grid-template-columns: 1fr; }
            .stats-container { grid-template-columns: 1fr; }
            .footer-grid { grid-template-columns: 1fr; }
            .footer-bottom { flex-direction: column; text-align: center; }
        }
    </style>
</head>
<body>

    <!-- Announcement Bar -->
    <div class="announcement-bar">
        <span id="ann-text">🚀 Zenvi POS v1.0 Resmi Hadir di Google Play Store! Kelola Kasir & Cabang Bisnis Lebih Cepat.</span>
    </div>

    <!-- Navigation Header -->
    <header class="navbar">
        <div class="nav-container">
            <a href="/" class="brand-logo">
                <div class="brand-icon">
                    <svg width="24" height="24" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect width="100" height="100" rx="20" fill="#0D7C83"/>
                        <path d="M37.2 25H25L50 75L75 25H43.8" stroke="white" stroke-width="8" stroke-linejoin="miter" stroke-linecap="square"/>
                    </svg>
                </div>
                <div>
                    <div class="brand-name">Zenvi</div>
                    <div class="brand-tag">Point of Sale</div>
                </div>
            </a>

            <ul class="nav-menu">
                <li><a href="#features" class="nav-link" id="nav-f">Fitur</a></li>
                <li><a href="#how-it-works" class="nav-link" id="nav-h">Cara Kerja</a></li>
                <li><a href="#faq" class="nav-link" id="nav-faq">FAQ</a></li>
                <li><a href="/privacy-policy" class="nav-link" id="nav-p">Kebijakan Privasi</a></li>
                <li><a href="/disclaimer" class="nav-link" id="nav-d">Disclaimer</a></li>
            </ul>

            <div class="nav-actions">
                <!-- Language Switcher -->
                <div class="lang-switch">
                    <button type="button" class="lang-btn active" id="btn-id" onclick="setLanguage('id')">ID</button>
                    <button type="button" class="lang-btn" id="btn-en" onclick="setLanguage('en')">EN</button>
                </div>

                <a href="https://play.google.com/store/apps" class="btn-nav-cta" target="_blank">
                    <i data-lucide="download" style="width: 16px; height: 16px;"></i>
                    <span id="btn-nav-text">Download App</span>
                </a>
            </div>
        </div>
    </header>

    <!-- ========================================================== -->
    <!-- BAHASA INDONESIA CONTENT (DEFAULT) -->
    <!-- ========================================================== -->
    <div id="content-id" class="lang-content active">

        <!-- Hero Section -->
        <section class="hero-section">
            <div class="hero-container">
                <div class="hero-pill">
                    <i data-lucide="sparkles" style="width: 16px; height: 16px;"></i>
                    <span>Solusi POS Multi-Outlet Generasi Terbaru</span>
                </div>
                <h1 class="hero-title">
                    Kelola Kasir, Cabang & Pesanan dengan <span class="highlight">Zenvi POS Pintar</span>
                </h1>
                <p class="hero-desc">
                    Aplikasi kasir all-in-one untuk kafe, resto, retail, dan jasa. Dirancang <strong>Offline-First</strong>, dilengkapi integrasi Kitchen Display (KDS), Presensi AI Wajah, QR Menu Meja, dan Cetak Struk Bluetooth.
                </p>
                <div class="hero-buttons">
                    <a href="https://play.google.com/store/apps" class="btn-primary-hero" target="_blank">
                        <i data-lucide="play" style="width: 20px; height: 20px; fill: white;"></i>
                        <span>Download di Play Store</span>
                    </a>
                    <a href="#features" class="btn-secondary-hero">
                        <i data-lucide="layout-grid" style="width: 18px; height: 18px;"></i>
                        <span>Jelajahi Fitur</span>
                    </a>
                </div>

                <!-- Mockup Highlights -->
                <div class="hero-mockup-wrap">
                    <div class="mockup-header">
                        <div class="mockup-dots">
                            <div class="mockup-dot red"></div>
                            <div class="mockup-dot yellow"></div>
                            <div class="mockup-dot green"></div>
                        </div>
                        <div class="mockup-title-bar">
                            <i data-lucide="shield-check" style="width: 14px; height: 14px; color: var(--primary);"></i>
                            <span>Zenvi POS Cloud Engine & Offline Database Sync</span>
                        </div>
                        <div></div>
                    </div>
                    <div class="mockup-grid">
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="wifi-off"></i></div>
                            <div class="mockup-card-title">100% Offline-First</div>
                            <div class="mockup-card-sub">Kasir tetap bisa transaksi dan cetak struk tanpa internet.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="scan-face"></i></div>
                            <div class="mockup-card-title">Presensi Wajah AI</div>
                            <div class="mockup-card-sub">Absensi staf anti titip absen dengan ML Kit & Geofencing.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="chef-hat"></i></div>
                            <div class="mockup-card-title">Kitchen Display (KDS)</div>
                            <div class="mockup-card-sub">Pesanan langsung tampil di layar dapur tanpa kertas tiket.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="qr-code"></i></div>
                            <div class="mockup-card-title">QR Menu Digital</div>
                            <div class="mockup-card-sub">Pelanggan bisa scan QR meja untuk lihat menu & order langsung.</div>
                        </div>
                    </div>
                </div>

            </div>
        </section>

        <!-- Stats Counter -->
        <section class="stats-section">
            <div class="stats-container">
                <div>
                    <div class="stat-num">0 ms</div>
                    <div class="stat-label">Delay Transaksi Kasir</div>
                </div>
                <div>
                    <div class="stat-num">100%</div>
                    <div class="stat-label">Offline-First Resilience</div>
                </div>
                <div>
                    <div class="stat-num">Multi</div>
                    <div class="stat-label">Outlet & Multi-Kasir</div>
                </div>
                <div>
                    <div class="stat-num">58/80mm</div>
                    <div class="stat-label">Dukungan Printer Thermal</div>
                </div>
            </div>
        </section>

        <!-- Main Features -->
        <section id="features" class="section">
            <div class="section-header-center">
                <div class="section-tag">Fitur Lengkap Enterprise</div>
                <h2 class="section-h2">Segala Kebutuhan Bisnis Anda dalam Satu Aplikasi Kasir</h2>
                <p class="section-p">Tinggalkan pencatatan manual yang lambat. Zenvi dirancang khusus dengan performa tinggi untuk kecepatan kasir dan kenyamanan pelanggan Anda.</p>
            </div>

            <div class="feature-grid-8">
                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="zap"></i></div>
                    <div class="feature-box-title">Kasir Cepat & Split Bill</div>
                    <div class="feature-box-desc">Input pesanan secepat kilat, dukung split bill (pisah tagihan), diskon otomatis, pajak, catatan pesanan khusus, dan mode meja dine-in / take-away.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="printer"></i></div>
                    <div class="feature-box-title">Cetak Struk Bluetooth & USB</div>
                    <div class="feature-box-desc">Mendukung printer thermal ukuran 58mm dan 80mm ESC/POS. Cetak logo toko kustom, rincian pembayaran, barcode QRIS, dan otomatis buka laci uang.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="scan-face"></i></div>
                    <div class="feature-box-title">Presensi Selfie AI (ML Kit)</div>
                    <div class="feature-box-desc">Kehadiran staf terverifikasi akurat menggunakan deteksi wajah Google ML Kit dan validasi radius lokasi GPS cabang. Bebas dari kecurangan absensi.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="chef-hat"></i></div>
                    <div class="feature-box-title">Kitchen Display System (KDS)</div>
                    <div class="feature-box-desc">Pesanan yang diinput kasir otomatis masuk ke tablet dapur secara real-time. Koki dapat mengubah status 'Diproses' hingga 'Siap Disajikan'.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="boxes"></i></div>
                    <div class="feature-box-title">Bahan Baku & Resep (BOM)</div>
                    <div class="feature-box-desc">Stok bahan baku (misal: biji kopi, susu, sirup) otomatis berkurang saat menu terjual. Pantau HPP riil dan margin laba kotor secara presisi.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="store"></i></div>
                    <div class="feature-box-title">Katalog & Portal Toko Web</div>
                    <div class="feature-box-desc">Setiap toko memiliki link website portal digital sendiri (misal: <code>zenvi.cellanoma.my.id/toko-kopi</code>) lengkap dengan QR Meja dan reservasi online.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="users"></i></div>
                    <div class="feature-box-title">Keanggotaan & CRM Loyalitas</div>
                    <div class="feature-box-desc">Daftarkan member pelanggan dengan nomor telepon/WhatsApp, berikan poin reward belanja, dan tingkatkan repeat order pelanggan setia Anda.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="bar-chart-3"></i></div>
                    <div class="feature-box-title">Laporan Keuangan & Shift</div>
                    <div class="feature-box-desc">Rekapitulasi pembukaan/penutupan shift kasir, pencatatan kas kecil (petty cash), grafik laba rugi, dan ranking menu paling laris.</div>
                </div>
            </div>
        </section>

        <!-- Suitable for Industries -->
        <section class="section" style="padding-top: 0;">
            <div class="section-header-center">
                <div class="section-tag">Fleksibilitas Bisnis</div>
                <h2 class="section-h2">Cocok untuk Berbagai Jenis Usaha</h2>
                <p class="section-p">Zenvi dirancang adaptif untuk mendukung alur operasional ritel, makanan & minuman, maupun industri jasa.</p>
                <div class="industries-wrap">
                    <div class="industry-pill"><i data-lucide="coffee" style="color: var(--primary);"></i> Coffee Shop & Kafe</div>
                    <div class="industry-pill"><i data-lucide="utensils" style="color: var(--primary);"></i> Restoran & Rumah Makan</div>
                    <div class="industry-pill"><i data-lucide="shopping-bag" style="color: var(--primary);"></i> Toko Retail & Minimarket</div>
                    <div class="industry-pill"><i data-lucide="scissors" style="color: var(--primary);"></i> Barbershop & Salon</div>
                    <div class="industry-pill"><i data-lucide="croissant" style="color: var(--primary);"></i> Bakery & Cake Shop</div>
                    <div class="industry-pill"><i data-lucide="sparkles" style="color: var(--primary);"></i> Cuci Mobil & Jasa Laundry</div>
                </div>
            </div>
        </section>

        <!-- How It Works -->
        <section id="how-it-works" class="how-it-works-bg">
            <div class="section-header-center">
                <div class="section-tag">Mudah & Cepat</div>
                <h2 class="section-h2">Mulai Jualan dalam 3 Langkah Sederhana</h2>
                <p class="section-p">Tanpa instalasi server yang rumit. Siap digunakan dalam hitungan menit.</p>
            </div>

            <div class="steps-grid">
                <div class="step-card">
                    <div class="step-num">1</div>
                    <div class="step-title">Unduh Aplikasi Zenvi</div>
                    <div class="step-desc">Download aplikasi Zenvi POS dari Google Play Store pada smartphone atau tablet Android Anda.</div>
                </div>

                <div class="step-card">
                    <div class="step-num">2</div>
                    <div class="step-title">Daftar & Input Menu</div>
                    <div class="step-desc">Buat akun pemilik toko, tambahkan nama cabang/outlet, dan masukkan daftar menu produk beserta harga.</div>
                </div>

                <div class="step-card">
                    <div class="step-num">3</div>
                    <div class="step-title">Mulai Transaksi!</div>
                    <div class="step-desc">Hubungkan printer thermal Bluetooth Anda dan mulai terima pesanan kasir dengan cepat dan akurat.</div>
                </div>
            </div>
        </section>

        <!-- FAQ Section -->
        <section id="faq" class="section">
            <div class="section-header-center">
                <div class="section-tag">Tanya Jawab</div>
                <h2 class="section-h2">Pertanyaan yang Sering Diajukan</h2>
                <p class="section-p">Pelajari lebih lanjut mengenai cara kerja dan keunggulan Zenvi POS.</p>
            </div>

            <div class="faq-container">
                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Apakah Zenvi bisa digunakan saat internet mati?</div>
                    <div class="faq-a">Ya! Zenvi menggunakan arsitektur <em>Offline-First</em> dengan database SQLite lokal. Anda tetap dapat memasukkan pesanan dan mencetak struk kasir saat offline. Ketika internet kembali menyala, data otomatis tersinkronisasi ke server cloud.</div>
                </div>

                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Printer apa saja yang kompatibel dengan Zenvi?</div>
                    <div class="faq-a">Zenvi mendukung hampir semua printer thermal Bluetooth dan USB yang mendukung protokol standar ESC/POS dengan ukuran kertas 58mm maupun 80mm.</div>
                </div>

                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Apakah saya bisa mengelola banyak cabang toko sekaligus?</div>
                    <div class="faq-a">Tentu! Zenvi dirancang khusus dengan dukungan Multi-Outlet. Pemilik usaha (Owner) dapat memantau penjualan seluruh cabang dari dasbor utama secara real-time.</div>
                </div>

                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Bagaimana privasi dan keamanan data bisnis saya?</div>
                    <div class="faq-a">Kami menggunakan enkripsi SSL/TLS berlapis dan hashing kata sandi tingkat tinggi. Kami tidak pernah menjual data bisnis Anda kepada pihak ketiga. Baca selengkapnya di <a href="/privacy-policy" style="color: var(--primary); font-weight: bold;">Kebijakan Privasi</a> kami.</div>
                </div>
            </div>
        </section>

        <!-- Call to Action Banner -->
        <div class="cta-banner">
            <h2 class="cta-h2">Siap Bawa Bisnis Anda ke Level Berikutnya?</h2>
            <p class="cta-p">Download Zenvi POS sekarang di Google Play Store dan rasakan kemudahan kasir pintar tanpa ribet.</p>
            <a href="https://play.google.com/store/apps" class="btn-cta-white" target="_blank">
                <i data-lucide="download" style="width: 20px; height: 20px;"></i>
                <span>Download Zenvi POS Gratis</span>
            </a>
        </div>

    </div>

    <!-- ========================================================== -->
    <!-- ENGLISH CONTENT -->
    <!-- ========================================================== -->
    <div id="content-en" class="lang-content">

        <!-- Hero Section -->
        <section class="hero-section">
            <div class="hero-container">
                <div class="hero-pill">
                    <i data-lucide="sparkles" style="width: 16px; height: 16px;"></i>
                    <span>Next-Gen Multi-Outlet Smart POS System</span>
                </div>
                <h1 class="hero-title">
                    Empower Your Store, Staff & Sales with <span class="highlight">Zenvi Smart POS</span>
                </h1>
                <p class="hero-desc">
                    The all-in-one point of sale app for cafes, restaurants, retail shops, and services. Built <strong>Offline-First</strong> with real-time Kitchen Display (KDS), AI Face Attendance, QR Table Menus, and Bluetooth Thermal Printing.
                </p>
                <div class="hero-buttons">
                    <a href="https://play.google.com/store/apps" class="btn-primary-hero" target="_blank">
                        <i data-lucide="play" style="width: 20px; height: 20px; fill: white;"></i>
                        <span>Get on Google Play</span>
                    </a>
                    <a href="#features" class="btn-secondary-hero">
                        <i data-lucide="layout-grid" style="width: 18px; height: 18px;"></i>
                        <span>Explore Features</span>
                    </a>
                </div>

                <!-- Mockup Highlights -->
                <div class="hero-mockup-wrap">
                    <div class="mockup-header">
                        <div class="mockup-dots">
                            <div class="mockup-dot red"></div>
                            <div class="mockup-dot yellow"></div>
                            <div class="mockup-dot green"></div>
                        </div>
                        <div class="mockup-title-bar">
                            <i data-lucide="shield-check" style="width: 14px; height: 14px; color: var(--primary);"></i>
                            <span>Zenvi POS Cloud Engine & Offline Database Sync</span>
                        </div>
                        <div></div>
                    </div>
                    <div class="mockup-grid">
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="wifi-off"></i></div>
                            <div class="mockup-card-title">100% Offline-First</div>
                            <div class="mockup-card-sub">Process orders & print receipts even without internet.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="scan-face"></i></div>
                            <div class="mockup-card-title">AI Face Attendance</div>
                            <div class="mockup-card-sub">Staff selfie clock-in powered by ML Kit & GPS Geofencing.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="chef-hat"></i></div>
                            <div class="mockup-card-title">Kitchen Display (KDS)</div>
                            <div class="mockup-card-sub">Orders appear instantly in the kitchen without paper tickets.</div>
                        </div>
                        <div class="mockup-card">
                            <div class="mockup-card-icon"><i data-lucide="qr-code"></i></div>
                            <div class="mockup-card-title">Digital QR Menus</div>
                            <div class="mockup-card-sub">Customers can scan table QR codes to browse & order.</div>
                        </div>
                    </div>
                </div>

            </div>
        </section>

        <!-- Stats Counter -->
        <section class="stats-section">
            <div class="stats-container">
                <div>
                    <div class="stat-num">0 ms</div>
                    <div class="stat-label">Checkout Latency</div>
                </div>
                <div>
                    <div class="stat-num">100%</div>
                    <div class="stat-label">Offline Resilience</div>
                </div>
                <div>
                    <div class="stat-num">Multi</div>
                    <div class="stat-label">Branch & Cashier Support</div>
                </div>
                <div>
                    <div class="stat-num">58/80mm</div>
                    <div class="stat-label">Thermal Printer Compatibility</div>
                </div>
            </div>
        </section>

        <!-- Main Features -->
        <section id="features" class="section">
            <div class="section-header-center">
                <div class="section-tag">Enterprise Capabilities</div>
                <h2 class="section-h2">Everything Your Store Needs in One Platform</h2>
                <p class="section-p">Say goodbye to slow legacy registers. Zenvi is engineered with blazing speed for cashier productivity and customer delight.</p>
            </div>

            <div class="feature-grid-8">
                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="zap"></i></div>
                    <div class="feature-box-title">Lightning Checkout & Split Bill</div>
                    <div class="feature-box-desc">Speedy order entry, split bill payments, automated promos, tax calculations, and flexible dine-in / take-away order handling.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="printer"></i></div>
                    <div class="feature-box-title">Bluetooth & USB Thermal Printing</div>
                    <div class="feature-box-desc">Compatible with 58mm & 80mm ESC/POS thermal printers. Print custom logos, itemized bills, QRIS codes, and trigger cash drawers.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="scan-face"></i></div>
                    <div class="feature-box-title">AI Selfie Attendance (ML Kit)</div>
                    <div class="feature-box-desc">Accurate employee presence verification using Google ML Kit face liveness check and GPS store geofence validation.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="chef-hat"></i></div>
                    <div class="feature-box-title">Kitchen Display System (KDS)</div>
                    <div class="feature-box-desc">Orders placed at the counter appear on kitchen tablets in real-time. Chefs can seamlessly mark items preparing and ready.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="boxes"></i></div>
                    <div class="feature-box-title">Ingredients & Recipe BOM</div>
                    <div class="feature-box-desc">Raw ingredient inventory deducts automatically per portion sold. Track accurate COGS and real-time gross profit margins.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="store"></i></div>
                    <div class="feature-box-title">Digital Web Menu & Store Portal</div>
                    <div class="feature-box-desc">Each store outlet gets its dedicated live catalog URL (e.g. <code>zenvi.cellanoma.my.id/store-slug</code>) with table QR codes and reservations.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="users"></i></div>
                    <div class="feature-box-title">Customer Loyalty & CRM</div>
                    <div class="feature-box-desc">Register store members with WhatsApp/phone number, reward loyalty points, and boost recurring customer sales.</div>
                </div>

                <div class="feature-box">
                    <div class="feature-box-icon"><i data-lucide="bar-chart-3"></i></div>
                    <div class="feature-box-title">Financial Reports & Shifts</div>
                    <div class="feature-box-desc">Shift opening/closing reconciliation, petty cash expense logging, gross profit graphs, and best-seller analytics.</div>
                </div>
            </div>
        </section>

        <!-- How It Works -->
        <section id="how-it-works" class="how-it-works-bg">
            <div class="section-header-center">
                <div class="section-tag">Quick Start</div>
                <h2 class="section-h2">Start Selling in 3 Easy Steps</h2>
                <p class="section-p">No complicated server setup required. Get up and running in minutes.</p>
            </div>

            <div class="steps-grid">
                <div class="step-card">
                    <div class="step-num">1</div>
                    <div class="step-title">Download Zenvi POS</div>
                    <div class="step-desc">Get the Zenvi POS app from Google Play Store on your Android phone, tablet, or POS terminal.</div>
                </div>

                <div class="step-card">
                    <div class="step-num">2</div>
                    <div class="step-title">Setup Store & Menu</div>
                    <div class="step-desc">Register your business, create outlets, and input your catalog products, prices, and categories.</div>
                </div>

                <div class="step-card">
                    <div class="step-num">3</div>
                    <div class="step-title">Start Ringing Sales!</div>
                    <div class="step-desc">Pair your Bluetooth thermal printer and start serving customers with speed and precision.</div>
                </div>
            </div>
        </section>

        <!-- FAQ Section -->
        <section id="faq" class="section">
            <div class="section-header-center">
                <div class="section-tag">Common Questions</div>
                <h2 class="section-h2">Frequently Asked Questions</h2>
                <p class="section-p">Learn more about Zenvi POS capabilities and architecture.</p>
            </div>

            <div class="faq-container">
                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Can Zenvi operate without an internet connection?</div>
                    <div class="faq-a">Yes! Zenvi uses an <em>Offline-First</em> architecture powered by a local SQLite engine. You can ring up sales and print receipts offline; once connected, data syncs to the cloud automatically.</div>
                </div>

                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> Which receipt printers are supported?</div>
                    <div class="faq-a">Zenvi supports almost all standard ESC/POS Bluetooth and USB thermal printers in both 58mm and 80mm paper widths.</div>
                </div>

                <div class="faq-item">
                    <div class="faq-q"><i data-lucide="help-circle" style="color: var(--primary); width: 20px;"></i> How is my store data protected?</div>
                    <div class="faq-a">We employ end-to-end SSL/TLS encryption, secure database partitioning, and industry-standard password hashing. Read our full <a href="/privacy-policy" style="color: var(--primary); font-weight: bold;">Privacy Policy</a>.</div>
                </div>
            </div>
        </section>

        <!-- Call to Action Banner -->
        <div class="cta-banner">
            <h2 class="cta-h2">Ready to Upgrade Your Business Operations?</h2>
            <p class="cta-p">Download Zenvi POS now on Google Play Store and enjoy modern, stress-free cashier management.</p>
            <a href="https://play.google.com/store/apps" class="btn-cta-white" target="_blank">
                <i data-lucide="download" style="width: 20px; height: 20px;"></i>
                <span>Get Zenvi POS for Free</span>
            </a>
        </div>

    </div>

    <!-- Footer -->
    <footer class="footer">
        <div class="footer-grid">
            <div>
                <div class="brand-logo" style="margin-bottom: 1rem;">
                    <div class="brand-icon" style="width: 36px; height: 36px;">
                        <svg width="20" height="20" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <rect width="100" height="100" rx="20" fill="#0D7C83"/>
                            <path d="M37.2 25H25L50 75L75 25H43.8" stroke="white" stroke-width="8" stroke-linejoin="miter" stroke-linecap="square"/>
                        </svg>
                    </div>
                    <div>
                        <div class="brand-name" style="color: #ffffff; font-size: 1.25rem;">Zenvi POS</div>
                        <div class="brand-tag" style="color: #14b8a6;">By Cellanoma Digital</div>
                    </div>
                </div>
                <p style="font-size: 0.875rem; color: #94a3b8; max-width: 320px; line-height: 1.6;">
                    Solusi kasir point of sale (POS) cerdas, offline-first, dan terintegrasi untuk bisnis modern di Indonesia.
                </p>
            </div>

            <div>
                <div class="footer-col-title">Produk & Layanan</div>
                <ul class="footer-links">
                    <li><a href="#features" class="footer-link">Fitur Utama</a></li>
                    <li><a href="#how-it-works" class="footer-link">Cara Kerja</a></li>
                    <li><a href="https://play.google.com/store/apps" class="footer-link" target="_blank">Download Play Store</a></li>
                </ul>
            </div>

            <div>
                <div class="footer-col-title">Legal & Kepatuhan</div>
                <ul class="footer-links">
                    <li><a href="/privacy-policy" class="footer-link">Kebijakan Privasi</a></li>
                    <li><a href="/disclaimer" class="footer-link">Disclaimer / Penafian</a></li>
                    <li><a href="/delete-account" class="footer-link">Hapus Akun & Data</a></li>
                </ul>
            </div>

            <div>
                <div class="footer-col-title">Bantuan & Kontak</div>
                <ul class="footer-links">
                    <li><a href="mailto:cellanomadigital@gmail.com" class="footer-link">cellanomadigital@gmail.com</a></li>
                    <li><a href="https://zenvi.cellanoma.my.id" class="footer-link">zenvi.cellanoma.my.id</a></li>
                    <li><span class="footer-link">Indonesia</span></li>
                </ul>
            </div>
        </div>

        <div class="footer-bottom">
            <div>
                &copy; {{ date('Y') }} Zenvi POS by Cellanoma Digital. All Rights Reserved.
            </div>
            <div style="display: flex; gap: 1.5rem;">
                <a href="/privacy-policy" class="footer-link" style="color: #64748b;">Privacy Policy</a>
                <a href="/disclaimer" class="footer-link" style="color: #64748b;">Disclaimer</a>
                <a href="/delete-account" class="footer-link" style="color: #64748b;">Delete Account</a>
            </div>
        </div>
    </footer>

    <!-- Script Lucide & Language Toggle -->
    <script>
        lucide.createIcons();

        function setLanguage(lang) {
            const contentId = document.getElementById('content-id');
            const contentEn = document.getElementById('content-en');
            const btnId = document.getElementById('btn-id');
            const btnEn = document.getElementById('btn-en');
            const annText = document.getElementById('ann-text');
            const btnNavText = document.getElementById('btn-nav-text');
            const navF = document.getElementById('nav-f');
            const navH = document.getElementById('nav-h');
            const navP = document.getElementById('nav-p');
            const navD = document.getElementById('nav-d');

            if (lang === 'en') {
                contentId.classList.remove('active');
                contentEn.classList.add('active');
                btnId.classList.remove('active');
                btnEn.classList.add('active');
                annText.innerText = '🚀 Zenvi POS v1.0 is now live on Google Play Store! Accelerate your checkout & multi-branch operations.';
                btnNavText.innerText = 'Download App';
                navF.innerText = 'Features';
                navH.innerText = 'How it Works';
                navP.innerText = 'Privacy Policy';
                navD.innerText = 'Disclaimer';

                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'en');
                window.history.replaceState({}, '', newUrl);
            } else {
                contentEn.classList.remove('active');
                contentId.classList.add('active');
                btnEn.classList.remove('active');
                btnId.classList.add('active');
                annText.innerText = '🚀 Zenvi POS v1.0 Resmi Hadir di Google Play Store! Kelola Kasir & Cabang Bisnis Lebih Cepat.';
                btnNavText.innerText = 'Download App';
                navF.innerText = 'Fitur';
                navH.innerText = 'Cara Kerja';
                navP.innerText = 'Kebijakan Privasi';
                navD.innerText = 'Disclaimer';

                const newUrl = new URL(window.location);
                newUrl.searchParams.set('lang', 'id');
                window.history.replaceState({}, '', newUrl);
            }

            setTimeout(() => {
                lucide.createIcons();
            }, 50);
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
