<!DOCTYPE html>
<html lang="{{ $lang ?? 'id' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $company ? $company->name . ' — Portal Katalog, Jasa & Reservasi' : 'Zenvi Digital Portal' }}</title>
    
    <!-- Google Fonts: Outfit -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    
    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        :root {
            --primary: #0f172a;
            --primary-hover: #1e293b;
            --primary-light: #f1f5f9;
            --teal: #0d9488;
            --teal-hover: #0f766e;
            --teal-light: #f0fdfa;
            --teal-subtle: rgba(13, 148, 136, 0.12);
            --bg-page: #f8fafc;
            --surface: #ffffff;
            --surface-hover: #fcfdfe;
            --text-primary: #0f172a;
            --text-secondary: #475569;
            --text-muted: #94a3b8;
            --border-color: #e2e8f0;
            --border-subtle: #f1f5f9;
            --danger: #ef4444;
            --success: #10b981;
            --amber: #f59e0b;
            --indigo: #6366f1;
            
            --radius-xs: 6px;
            --radius-sm: 10px;
            --radius-md: 14px;
            --radius-lg: 18px;
            --radius-xl: 24px;
            --radius-pill: 9999px;
            
            --shadow-xs: 0 1px 2px rgba(0, 0, 0, 0.04);
            --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.04), 0 1px 2px rgba(0, 0, 0, 0.02);
            --shadow-md: 0 8px 20px -4px rgba(0, 0, 0, 0.06), 0 4px 8px -2px rgba(0, 0, 0, 0.03);
            --shadow-lg: 0 20px 40px -8px rgba(0, 0, 0, 0.08);
            --shadow-card: 0 4px 16px rgba(0, 0, 0, 0.04);
        }

        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            background-color: var(--bg-page);
            color: var(--text-primary);
            font-family: 'Outfit', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
            min-height: 100vh;
            margin: 0;
            padding: 0;
            overflow-x: clip;
        }

        /* Utilities */
        .hidden { display: none !important; }
        .flex { display: flex; }
        .items-center { align-items: center; }
        .justify-between { justify-content: space-between; }
        .justify-center { justify-content: center; }
        .gap-1 { gap: 4px; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 12px; }
        .gap-4 { gap: 16px; }
        .w-full { width: 100%; }
        .font-bold { font-weight: 700; }
        .font-extrabold { font-weight: 800; }
        .font-black { font-weight: 900; }
        .font-medium { font-weight: 500; }
        .text-muted { color: var(--text-muted); }
        .text-secondary { color: var(--text-secondary); }
        .text-teal { color: var(--teal); }

        /* =========================================================
           APP LAYOUT & UNIFIED SINGLE MINIMALIST HEADER
           ========================================================= */
        .app-layout {
            width: 100%;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            position: relative;
            overflow: visible;
        }

        /* 1. SINGLE UNIFIED STICKY TOP NAVBAR */
        .top-navbar {
            position: -webkit-sticky;
            position: sticky;
            top: 0;
            left: 0;
            right: 0;
            z-index: 500;
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-bottom: 1px solid var(--border-color);
            box-shadow: 0 2px 12px rgba(0, 0, 0, 0.03);
            width: 100%;
            transition: all 0.2s ease;
        }

        .navbar-inner {
            max-width: 1200px;
            margin: 0 auto;
            padding: 10px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            width: 100%;
        }

        /* Brand & Logo */
        .nav-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
            color: inherit;
            min-width: 0;
            flex-shrink: 0;
        }
        .brand-logo-img {
            width: 40px;
            height: 40px;
            border-radius: var(--radius-md);
            object-fit: cover;
            border: 1.5px solid var(--border-color);
            background: var(--primary-light);
            flex-shrink: 0;
            box-shadow: var(--shadow-xs);
        }
        .brand-logo-fallback {
            width: 40px;
            height: 40px;
            border-radius: var(--radius-md);
            background: var(--teal);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 18px;
            flex-shrink: 0;
            box-shadow: var(--shadow-xs);
        }
        .brand-text {
            display: flex;
            flex-direction: column;
            min-width: 0;
        }
        .brand-title {
            font-size: 1.05rem;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: var(--text-primary);
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .brand-subinfo {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 0.6875rem;
            font-weight: 600;
            color: var(--text-secondary);
            margin-top: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .status-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background-color: var(--teal);
            box-shadow: 0 0 0 3px rgba(13, 148, 136, 0.25);
            animation: pulseDot 2s infinite;
            flex-shrink: 0;
        }
        @keyframes pulseDot {
            0% { box-shadow: 0 0 0 0 rgba(13, 148, 136, 0.4); }
            70% { box-shadow: 0 0 0 6px rgba(13, 148, 136, 0); }
            100% { box-shadow: 0 0 0 0 rgba(13, 148, 136, 0); }
        }

        /* Desktop Nav Tabs */
        .desktop-nav-tabs {
            display: flex;
            align-items: center;
            background: var(--primary-light);
            padding: 4px;
            border-radius: var(--radius-pill);
            gap: 4px;
            border: 1px solid var(--border-color);
            flex-shrink: 0;
        }
        .desktop-tab-btn {
            padding: 7px 16px;
            border-radius: var(--radius-pill);
            border: none;
            background: transparent;
            font-size: 0.845rem;
            font-weight: 700;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 7px;
            font-family: inherit;
        }
        .desktop-tab-btn:hover {
            color: var(--text-primary);
        }
        .desktop-tab-btn.active {
            background: var(--surface);
            color: var(--text-primary);
            box-shadow: var(--shadow-sm);
        }

        /* Right Actions */
        .navbar-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }
        .lang-pill-wrap {
            display: inline-flex;
            align-items: center;
            background: var(--primary-light);
            padding: 3px;
            border-radius: var(--radius-pill);
            border: 1px solid var(--border-color);
            gap: 2px;
        }
        .lang-pill {
            border: none;
            background: transparent;
            padding: 4px 8px;
            border-radius: var(--radius-pill);
            font-size: 0.75rem;
            font-weight: 700;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 3px;
            font-family: inherit;
        }
        .lang-pill.active {
            background: #ffffff;
            color: var(--text-primary);
            box-shadow: var(--shadow-xs);
        }
        .action-icon-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: var(--radius-pill);
            border: 1px solid var(--border-color);
            background: var(--surface);
            color: var(--text-primary);
            font-size: 0.8125rem;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s ease;
            font-family: inherit;
        }
        .action-icon-btn:hover {
            background: var(--primary-light);
            transform: translateY(-1px);
        }

        /* =========================================================
           COMPACT STORE SUB-BAR
           ========================================================= */
        .store-sub-bar {
            background: var(--surface);
            border-bottom: 1px solid var(--border-color);
            padding: 10px 20px;
            width: 100%;
        }
        .store-sub-inner {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            width: 100%;
        }
        .sub-bar-left {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
            min-width: 0;
        }
        .tag-pill {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 8px;
            border-radius: var(--radius-xs);
            font-size: 0.725rem;
            font-weight: 700;
        }
        .tag-pill-neutral { background: var(--primary-light); color: var(--text-secondary); }
        .tag-pill-teal { background: var(--teal-light); color: var(--teal); }
        .tag-pill-amber { background: #fef3c7; color: #b45309; }

        .sub-bar-right {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 0.75rem;
            font-weight: 700;
            color: var(--text-muted);
        }
        .sub-stat-item {
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .sub-stat-num {
            color: var(--text-primary);
            font-weight: 800;
        }

        /* =========================================================
           MAIN BODY & STICKY CONTAINERS
           ========================================================= */
        .main-content-wrapper {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px 20px 80px;
            width: 100%;
            flex: 1;
            overflow: visible;
        }

        /* Sticky Mobile Category Filter Bar */
        .mobile-sticky-filter-wrap {
            display: none;
            position: -webkit-sticky;
            position: sticky;
            top: 61px;
            z-index: 400;
            background: rgba(248, 250, 252, 0.96);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            padding: 8px 12px;
            margin: -8px -12px 12px;
            border-bottom: 1px solid var(--border-color);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.02);
            width: calc(100% + 24px);
        }
        .mobile-category-bar {
            display: flex;
            gap: 8px;
            overflow-x: auto;
            scrollbar-width: none;
            width: 100%;
        }
        .mobile-category-bar::-webkit-scrollbar { display: none; }
        .mobile-cat-pill {
            padding: 6px 14px;
            border-radius: var(--radius-pill);
            border: 1px solid var(--border-color);
            background: var(--surface);
            font-size: 0.8125rem;
            font-weight: 700;
            color: var(--text-secondary);
            white-space: nowrap;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            font-family: inherit;
            flex-shrink: 0;
            box-shadow: var(--shadow-xs);
        }
        .mobile-cat-pill.active {
            background: var(--teal);
            color: #ffffff;
            border-color: var(--teal);
            box-shadow: 0 3px 10px rgba(13, 148, 136, 0.3);
        }

        /* --- 1. CATALOG / SERVICES SECTION --- */
        .menu-layout-grid {
            display: grid;
            grid-template-columns: 260px minmax(0, 1fr);
            gap: 24px;
            align-items: start;
            width: 100%;
            overflow: visible;
        }

        /* Sticky Desktop Category Sidebar */
        .category-sidebar {
            position: -webkit-sticky;
            position: sticky;
            top: 76px;
            z-index: 100;
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-xl);
            padding: 16px 12px;
            box-shadow: var(--shadow-card);
        }
        .sidebar-header-title {
            font-size: 0.8125rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--text-muted);
            margin-bottom: 10px;
            padding: 0 8px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .category-nav-list {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }
        .category-nav-btn {
            width: 100%;
            text-align: left;
            padding: 9px 12px;
            border-radius: var(--radius-sm);
            border: 1px solid transparent;
            background: transparent;
            color: var(--text-secondary);
            font-size: 0.875rem;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: all 0.2s ease;
            font-family: inherit;
        }
        .category-nav-btn:hover {
            background: var(--primary-light);
            color: var(--text-primary);
            transform: translateX(2px);
        }
        .category-nav-btn.active {
            background: var(--primary);
            color: #ffffff;
            box-shadow: var(--shadow-xs);
        }
        .category-count-badge {
            font-size: 0.75rem;
            padding: 2px 7px;
            border-radius: var(--radius-pill);
            background: rgba(0, 0, 0, 0.06);
            color: inherit;
        }
        .category-nav-btn.active .category-count-badge {
            background: rgba(255, 255, 255, 0.2);
            color: #ffffff;
        }

        /* Right Product Area */
        .product-area {
            display: flex;
            flex-direction: column;
            gap: 16px;
            width: 100%;
            min-width: 0;
        }

        /* Search Bar */
        .search-action-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            background: var(--surface);
            padding: 8px 14px 8px 16px;
            border-radius: var(--radius-pill);
            border: 1.5px solid var(--border-color);
            box-shadow: var(--shadow-sm);
            width: 100%;
            transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }
        .search-action-bar:focus-within {
            border-color: var(--teal);
            box-shadow: 0 0 0 4px rgba(13, 148, 136, 0.1);
        }
        .search-input-wrap {
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 1;
            min-width: 0;
        }
        .search-main-input {
            width: 100%;
            border: none;
            outline: none;
            background: transparent;
            font-size: 0.9375rem;
            font-family: inherit;
            color: var(--text-primary);
        }
        .search-main-input::placeholder {
            color: var(--text-muted);
        }
        .search-clear-btn {
            background: transparent;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            padding: 4px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            flex-shrink: 0;
        }
        .search-clear-btn:hover { color: var(--text-primary); }

        /* Dynamic Product & Service Cards Grid */
        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
            gap: 16px;
            width: 100%;
        }
        .product-item-card {
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-lg);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            cursor: pointer;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
            box-shadow: var(--shadow-sm);
            width: 100%;
            min-width: 0;
        }
        .product-item-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-md);
            border-color: var(--teal);
        }
        .product-thumb-wrap {
            position: relative;
            width: 100%;
            padding-top: 72%;
            background: var(--primary-light);
            overflow: hidden;
        }
        .product-thumb-img {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.4s ease;
        }
        .product-item-card:hover .product-thumb-img {
            transform: scale(1.06);
        }
        .product-discount-tag {
            position: absolute;
            top: 10px;
            left: 10px;
            background: var(--danger);
            color: #ffffff;
            font-size: 0.725rem;
            font-weight: 800;
            padding: 2px 8px;
            border-radius: var(--radius-xs);
            box-shadow: 0 2px 6px rgba(239, 68, 68, 0.35);
            z-index: 2;
        }
        .product-card-body {
            padding: 13px;
            display: flex;
            flex-direction: column;
            flex: 1;
            justify-content: space-between;
            min-width: 0;
        }
        .p-category-name {
            font-size: 0.725rem;
            font-weight: 700;
            color: var(--teal);
            text-transform: uppercase;
            letter-spacing: 0.04em;
            margin-bottom: 4px;
        }
        .p-item-name {
            font-size: 0.9375rem;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 6px;
            line-height: 1.35;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
            word-break: break-word;
        }
        .p-price-container {
            display: flex;
            align-items: baseline;
            gap: 6px;
            margin-top: 4px;
            flex-wrap: wrap;
        }
        .p-final-price {
            font-size: 1.05rem;
            font-weight: 900;
            color: var(--text-primary);
        }
        .p-slash-price {
            font-size: 0.75rem;
            color: var(--text-muted);
            text-decoration: line-through;
        }
        .p-variant-indicator {
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px dashed var(--border-color);
            font-size: 0.725rem;
            color: var(--text-secondary);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .p-view-btn {
            font-size: 0.725rem;
            font-weight: 700;
            color: var(--teal);
            display: inline-flex;
            align-items: center;
            gap: 2px;
            transition: transform 0.15s ease;
        }
        .product-item-card:hover .p-view-btn {
            transform: translateX(3px);
        }

        /* --- 2. MEMBERSHIP & RESERVATION (Two-Column Layout) --- */
        .two-col-layout {
            display: grid;
            grid-template-columns: 360px minmax(0, 1fr);
            gap: 28px;
            align-items: start;
            width: 100%;
            overflow: visible;
        }

        /* Sticky Left Boxes (Desktop) */
        .sticky-left-box {
            position: -webkit-sticky;
            position: sticky;
            top: 76px;
            z-index: 100;
            display: flex;
            flex-direction: column;
            gap: 16px;
            width: 100%;
        }

        /* Luxury Digital Member Card */
        .luxury-member-card {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            border-radius: var(--radius-xl);
            padding: 22px;
            color: #ffffff;
            position: relative;
            overflow: hidden;
            box-shadow: 0 20px 40px -10px rgba(15, 23, 42, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.12);
            width: 100%;
        }
        .luxury-card-sheen {
            position: absolute;
            top: -60%;
            right: -40%;
            width: 320px;
            height: 320px;
            background: radial-gradient(circle, rgba(13, 148, 136, 0.35) 0%, rgba(255, 255, 255, 0) 70%);
            border-radius: 50%;
            pointer-events: none;
        }
        .card-top-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
        }
        .card-store-title {
            font-size: 0.8125rem;
            font-weight: 800;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: #94a3b8;
        }
        .card-vip-pill {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            padding: 3px 10px;
            border-radius: var(--radius-pill);
            font-size: 0.725rem;
            font-weight: 800;
            color: #38bdf8;
            letter-spacing: 0.04em;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .card-holder-name {
            font-size: 1.35rem;
            font-weight: 900;
            letter-spacing: -0.01em;
            margin-bottom: 4px;
            word-break: break-word;
        }
        .card-number-code {
            font-family: monospace;
            font-size: 0.95rem;
            color: #cbd5e1;
            letter-spacing: 0.08em;
            margin-bottom: 18px;
        }
        .card-stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            padding-top: 14px;
            border-top: 1px solid rgba(255, 255, 255, 0.15);
        }
        .card-stat-box {
            display: flex;
            flex-direction: column;
        }
        .card-stat-lbl {
            font-size: 0.675rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: #94a3b8;
        }
        .card-stat-val {
            font-size: 0.95rem;
            font-weight: 900;
            color: #ffffff;
            margin-top: 2px;
        }

        /* Perks & Info Cards */
        .perks-card-box {
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-xl);
            padding: 22px;
            box-shadow: var(--shadow-sm);
            width: 100%;
        }
        .perks-title {
            font-size: 1rem;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .perk-item {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            margin-bottom: 14px;
        }
        .perk-item:last-child { margin-bottom: 0; }
        .perk-icon-circle {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: var(--teal-light);
            color: var(--teal);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .perk-desc-wrap h4 {
            font-size: 0.875rem;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 2px;
        }
        .perk-desc-wrap p {
            font-size: 0.8125rem;
            color: var(--text-secondary);
            line-height: 1.4;
        }

        /* Form Container Cards */
        .form-surface-card {
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: var(--radius-xl);
            padding: 28px;
            box-shadow: var(--shadow-card);
            width: 100%;
        }
        .form-header-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--border-color);
            flex-wrap: wrap;
            gap: 8px;
        }
        .form-header-title {
            font-size: 1.25rem;
            font-weight: 900;
            color: var(--text-primary);
            letter-spacing: -0.02em;
        }
        .form-header-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background: var(--teal-light);
            color: var(--teal);
            padding: 4px 10px;
            border-radius: var(--radius-pill);
            font-size: 0.75rem;
            font-weight: 800;
        }

        /* Modern Form Fieldset Groups */
        .form-section-block {
            background: #fafbfc;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-lg);
            padding: 18px;
            margin-bottom: 18px;
        }
        .form-section-head {
            font-size: 0.8125rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-secondary);
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        /* Sub Toggle Segment */
        .form-sub-tabs {
            display: flex;
            background: var(--primary-light);
            padding: 4px;
            border-radius: var(--radius-pill);
            margin-bottom: 18px;
            gap: 4px;
            border: 1px solid var(--border-color);
            width: 100%;
        }
        .form-sub-tab-btn {
            flex: 1;
            padding: 8px 14px;
            border-radius: var(--radius-pill);
            border: none;
            background: transparent;
            font-size: 0.8125rem;
            font-weight: 700;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.15s ease;
            text-align: center;
            font-family: inherit;
            white-space: nowrap;
        }
        .form-sub-tab-btn.active {
            background: #ffffff;
            color: var(--text-primary);
            box-shadow: var(--shadow-xs);
        }

        /* Form Controls */
        .form-group-block {
            margin-bottom: 14px;
            width: 100%;
        }
        .form-group-block:last-child { margin-bottom: 0; }
        
        .form-field-label {
            display: block;
            font-size: 0.8125rem;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 6px;
        }
        .form-field-label .req { color: var(--danger); }
        .form-input-control, .form-select-control, .form-textarea-control {
            width: 100%;
            padding: 10px 14px;
            border: 1.5px solid var(--border-color);
            border-radius: var(--radius-md);
            font-size: 0.875rem;
            background: #ffffff;
            color: var(--text-primary);
            outline: none;
            transition: all 0.2s ease;
            font-family: inherit;
        }
        .form-input-control:focus, .form-select-control:focus, .form-textarea-control:focus {
            border-color: var(--teal);
            box-shadow: 0 0 0 4px rgba(13, 148, 136, 0.12);
        }
        .form-textarea-control {
            resize: vertical;
            min-height: 75px;
        }
        .form-grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
            width: 100%;
        }

        /* Guest Counter & Stepper (Compact & Proportional) */
        .guest-counter-wrapper {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .guest-counter-box {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #ffffff;
            padding: 3px 6px;
            border-radius: var(--radius-pill);
            border: 1.5px solid var(--border-color);
            height: 36px;
        }
        .stepper-btn {
            width: 26px;
            height: 26px;
            border-radius: 50%;
            border: 1px solid var(--border-color);
            background: var(--primary-light);
            color: var(--text-primary);
            font-size: 0.875rem;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.15s ease;
            flex-shrink: 0;
        }
        .stepper-btn:hover {
            background: var(--teal);
            color: #ffffff;
            border-color: var(--teal);
        }
        .stepper-num {
            font-size: 0.875rem;
            font-weight: 800;
            min-width: 24px;
            text-align: center;
            color: var(--text-primary);
        }
        .preset-guest-pills {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
            align-items: center;
        }
        .preset-pill-btn {
            height: 36px;
            padding: 0 12px;
            border-radius: var(--radius-pill);
            border: 1px solid var(--border-color);
            background: #ffffff;
            font-size: 0.775rem;
            font-weight: 700;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .preset-pill-btn:hover {
            border-color: var(--teal);
            color: var(--teal);
        }
        .preset-pill-btn.active {
            background: var(--teal-light);
            border-color: var(--teal);
            color: var(--teal);
        }

        /* Time Slot Quick Pills */
        .time-slots-box {
            background: #ffffff;
            padding: 10px 12px;
            border-radius: var(--radius-md);
            border: 1.5px solid var(--border-color);
            margin-top: 8px;
        }
        .time-slots-label {
            font-size: 0.725rem;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            margin-bottom: 6px;
            display: block;
        }
        .time-slots-wrap {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            width: 100%;
        }
        .time-slot-btn {
            padding: 6px 13px;
            border-radius: var(--radius-pill);
            border: 1px solid var(--border-color);
            background: var(--bg-page);
            color: var(--text-secondary);
            font-size: 0.8125rem;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.15s ease;
            font-family: inherit;
        }
        .time-slot-btn:hover { border-color: var(--teal); color: var(--teal); }
        .time-slot-btn.active {
            background: var(--teal);
            border-color: var(--teal);
            color: #ffffff;
            box-shadow: 0 2px 6px rgba(13, 148, 136, 0.3);
        }

        /* Action Buttons */
        .btn-submit-action {
            width: 100%;
            padding: 14px 20px;
            background: var(--teal);
            color: #ffffff;
            border: none;
            border-radius: var(--radius-pill);
            font-size: 0.95rem;
            font-weight: 800;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-family: inherit;
            box-shadow: 0 4px 14px rgba(13, 148, 136, 0.25);
        }
        .btn-submit-action:hover {
            background: var(--teal-hover);
            transform: translateY(-1px);
        }
        .btn-submit-action:active { transform: translateY(0); }
        .btn-submit-action:disabled { opacity: 0.6; cursor: not-allowed; }

        .submit-helper-note {
            text-align: center;
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-top: 10px;
            font-weight: 500;
        }

        /* =========================================================
           5. MOBILE FLOATING STICKY BOTTOM NAVIGATION BAR
           ========================================================= */
        .mobile-bottom-nav {
            display: none;
            position: fixed;
            bottom: 14px;
            left: 12px;
            right: 12px;
            width: calc(100% - 24px);
            max-width: 480px;
            margin: 0 auto;
            z-index: 600;
            background: rgba(15, 23, 42, 0.94);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-radius: var(--radius-pill);
            padding: 5px 8px;
            box-shadow: 0 12px 32px rgba(0, 0, 0, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.15);
        }
        .mobile-nav-inner {
            display: flex;
            align-items: center;
            justify-content: space-around;
            width: 100%;
        }
        .mobile-nav-item {
            flex: 1;
            border: none;
            background: transparent;
            color: #94a3b8;
            padding: 7px 10px;
            border-radius: var(--radius-pill);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 2px;
            font-size: 0.675rem;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            font-family: inherit;
        }
        .mobile-nav-item.active {
            background: var(--teal);
            color: #ffffff;
            box-shadow: 0 2px 8px rgba(13, 148, 136, 0.4);
        }

        /* Empty State */
        .empty-state-card {
            text-align: center;
            padding: 48px 16px;
            background: var(--surface);
            border-radius: var(--radius-xl);
            border: 1px solid var(--border-color);
            width: 100%;
        }
        .empty-icon {
            width: 48px;
            height: 48px;
            margin-bottom: 12px;
            color: var(--text-muted);
            opacity: 0.5;
        }

        /* Modal Dialog & Bottom Sheet */
        .modal-overlay-custom {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.65);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            z-index: 700;
            display: flex;
            justify-content: center;
            align-items: center;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.25s ease;
            padding: 16px;
        }
        .modal-overlay-custom.active {
            opacity: 1;
            pointer-events: auto;
        }
        .modal-dialog-box {
            background: var(--surface);
            width: 100%;
            max-width: 520px;
            border-radius: var(--radius-xl);
            padding: 22px;
            max-height: 90vh;
            overflow-y: auto;
            position: relative;
            transform: scale(0.96) translateY(10px);
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            box-shadow: var(--shadow-lg);
        }
        .modal-overlay-custom.active .modal-dialog-box {
            transform: scale(1) translateY(0);
        }
        .modal-close-trigger {
            position: absolute;
            top: 16px;
            right: 16px;
            background: var(--primary-light);
            border: none;
            border-radius: 50%;
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            color: var(--text-secondary);
            transition: background 0.15s ease;
            z-index: 10;
        }
        .modal-close-trigger:hover { background: var(--border-color); color: var(--text-primary); }

        /* Variant Radio */
        .variant-radio-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-top: 12px;
            width: 100%;
        }
        .variant-radio-item {
            padding: 10px 13px;
            border: 1.5px solid var(--border-color);
            border-radius: var(--radius-md);
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .variant-radio-item:hover {
            border-color: var(--teal);
            background: var(--teal-light);
        }
        .variant-radio-item.selected {
            border-color: var(--teal);
            background: var(--teal-light);
        }

        .fade-in { animation: fadeIn 0.25s ease forwards; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
        .spin { animation: spin 1s linear infinite; }
        @keyframes spin { 100% { transform: rotate(360deg); } }

        /* =========================================================
           RESPONSIVE BREAKPOINTS (< 1024px)
           ========================================================= */
        @media (max-width: 1023px) {
            .desktop-nav-tabs { display: none; }
            .mobile-bottom-nav { display: block; }
            .sub-bar-right { display: none; }
            
            .navbar-inner {
                padding: 10px 14px;
                gap: 8px;
            }
            .brand-logo-img, .brand-logo-fallback {
                width: 36px;
                height: 36px;
                font-size: 16px;
            }
            .brand-title {
                font-size: 0.95rem;
            }
            .brand-subinfo {
                font-size: 0.65rem;
            }
            
            .store-sub-bar {
                padding: 8px 14px;
            }
            
            .menu-layout-grid { grid-template-columns: minmax(0, 1fr); gap: 0; }
            .category-sidebar { display: none; }
            .mobile-sticky-filter-wrap { display: block; }
            .two-col-layout { grid-template-columns: minmax(0, 1fr); gap: 16px; }
            .sticky-left-box { position: static; }
            
            .main-content-wrapper { 
                padding: 12px 12px 100px;
                max-width: 100%;
                overflow: visible;
            }
            
            .form-surface-card { padding: 18px 14px; }
            .perks-card-box { padding: 16px 14px; }
            .form-grid-2 { grid-template-columns: 1fr; gap: 0; }
            
            /* Clean 2-column mobile grid */
            .products-grid { 
                grid-template-columns: repeat(2, minmax(0, 1fr)); 
                gap: 10px;
                width: 100%;
            }
            .product-card-body { padding: 10px; }
            .p-item-name { font-size: 0.8125rem; margin-bottom: 4px; }
            .p-final-price { font-size: 0.875rem; }
            .p-slash-price { font-size: 0.7rem; }
            
            /* Mobile Bottom Sheet */
            .modal-overlay-custom {
                align-items: flex-end;
                padding: 0;
            }
            .modal-dialog-box {
                max-width: 100%;
                border-bottom-left-radius: 0;
                border-bottom-right-radius: 0;
                padding: 20px 16px 32px;
                transform: translateY(100%);
            }
            .modal-overlay-custom.active .modal-dialog-box {
                transform: translateY(0);
            }
        }
    </style>
</head>
<body>

    @php
        $lang = $lang ?? ($company->default_language ?? 'id');
        $t = [
            'catalog' => $lang == 'en' ? 'Catalog & Services' : 'Katalog & Layanan',
            'member' => $lang == 'en' ? 'Membership' : 'Member',
            'reservation' => $lang == 'en' ? 'Booking / Reservation' : 'Reservasi & Booking',
            'search' => $lang == 'en' ? 'Search items, products or services...' : 'Cari menu, produk, atau layanan...',
            'all' => $lang == 'en' ? 'All' : 'Semua',
            'currency' => 'Rp ',
            'empty_menu' => $lang == 'en' ? 'No products or services match your search.' : 'Tidak ada produk atau layanan yang sesuai pencarian.',
            'not_found' => $lang == 'en' ? 'Store Not Found' : 'Toko Tidak Ditemukan',
            'not_found_desc' => $lang == 'en' ? 'The store link you are trying to visit does not exist or is inactive.' : 'Tautan toko yang Anda tuju tidak tersedia atau sudah tidak aktif.',
            'submit' => $lang == 'en' ? 'Submit' : 'Kirim',
            'share' => $lang == 'en' ? 'Share' : 'Bagikan',
            'copied' => $lang == 'en' ? 'Store link copied to clipboard!' : 'Tautan toko berhasil disalin!',
            // Member
            'register_member' => $lang == 'en' ? 'Register Member' : 'Daftar Member',
            'check_member' => $lang == 'en' ? 'Check Member Status' : 'Cek Status Member',
            'member_promos' => $lang == 'en' ? 'Member Promos' : 'Promo Member',
            'name' => $lang == 'en' ? 'Full Name' : 'Nama Lengkap',
            'phone' => $lang == 'en' ? 'WhatsApp Number' : 'Nomor WhatsApp',
            'email' => $lang == 'en' ? 'Email (Optional)' : 'Email (Opsional)',
            'birth_date' => $lang == 'en' ? 'Birth Date (Optional)' : 'Tanggal Lahir (Opsional)',
            'address' => $lang == 'en' ? 'Address (Optional)' : 'Alamat (Opsional)',
            'notes' => $lang == 'en' ? 'Notes (Optional)' : 'Catatan (Opsional)',
            'member_benefits' => $lang == 'en' ? 'Earn reward points, member discounts, and exclusive seasonal promotions.' : 'Dapatkan poin belanja/layanan, diskon khusus member, dan penawaran spesial.',
            'check_phone_hint' => $lang == 'en' ? 'Enter your registered WhatsApp number to display your digital member card.' : 'Masukkan nomor WhatsApp Anda untuk melihat kartu member digital & poin.',
            'btn_check' => $lang == 'en' ? 'Check Member' : 'Cari Member',
            'points' => $lang == 'en' ? 'Points' : 'Poin',
            'discount' => $lang == 'en' ? 'Discount' : 'Diskon',
            'transactions' => $lang == 'en' ? 'Transactions' : 'Transaksi',
            'active' => $lang == 'en' ? 'Active VIP' : 'Aktif VIP',
            'no_promos' => $lang == 'en' ? 'No member promos available.' : 'Belum ada promo member aktif.',
            // Booking & Reservation
            'book_table' => $lang == 'en' ? 'Online Booking & Reservation' : 'Reservasi & Booking Online',
            'book_table_desc' => $lang == 'en' ? 'Book a table, schedule barbershop/salon services, car wash, or service appointments with ease.' : 'Pesan meja, booking jadwal salon/barbershop, servis kendaraan, atau perawatan tanpa harus antre.',
            'date' => $lang == 'en' ? 'Booking / Arrival Date' : 'Tanggal Kedatangan / Reservasi',
            'time' => $lang == 'en' ? 'Time / Slot' : 'Waktu / Jam Kedatangan',
            'people' => $lang == 'en' ? 'Guests / Service Slots (People)' : 'Jumlah Tamu / Slot Layanan (Orang)',
            'service_names' => $lang == 'en' ? 'Desired Service, Package, or Menu' : 'Pilihan Layanan, Paket Jasa, atau Menu',
            'special_requests' => $lang == 'en' ? 'Special Notes (Barber preference, VIP Table, etc)' : 'Catatan Khusus (Preferensi staf/barber, meja VIP, tipe kendaraan, dll)',
            'branch' => $lang == 'en' ? 'Select Branch' : 'Pilih Cabang',
            // Alerts
            'success' => $lang == 'en' ? 'Success!' : 'Berhasil!',
            'error' => $lang == 'en' ? 'Error!' : 'Gagal!',
            'conn_error' => $lang == 'en' ? 'Connection error. Please try again.' : 'Terjadi gangguan koneksi. Silakan coba lagi.',
            'variants' => $lang == 'en' ? 'Package / Variant Options' : 'Pilihan Paket / Varian',
            'open_now' => $lang == 'en' ? 'Buka Sekarang' : 'Open Now',
            'categories' => $lang == 'en' ? 'Categories' : 'Kategori',
            'items_count' => $lang == 'en' ? 'items' : 'item & jasa',
            'branches_count' => $lang == 'en' ? 'Branches' : 'Cabang',
            'view_details' => $lang == 'en' ? 'Details' : 'Lihat Detail',
            'book_now_btn' => $lang == 'en' ? 'Book This Service' : 'Booking Layanan Ini',
        ];
    @endphp

    @if ($notFound)
    <div class="app-layout" style="justify-content: center; align-items: center; padding: 40px 20px;">
        <div class="empty-state-card" style="max-width: 480px; width: 100%;">
            <i data-lucide="store" class="empty-icon"></i>
            <h1 class="font-extrabold" style="font-size: 1.5rem; margin-bottom: 8px;">{{ $t['not_found'] }}</h1>
            <p class="text-secondary" style="font-size: 0.9375rem;">{{ $t['not_found_desc'] }}</p>
        </div>
    </div>
    @else

    <div class="app-layout">
        
        <!-- 1. SINGLE UNIFIED STICKY TOP NAVBAR -->
        <header class="top-navbar">
            <div class="navbar-inner">
                <!-- Brand Info -->
                <div class="nav-brand">
                    @if ($company->logo_url)
                        <img src="{{ $company->logo_url }}" alt="{{ $company->name }}" class="brand-logo-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                        <div class="brand-logo-fallback" style="display:none;">{{ strtoupper(substr($company->name, 0, 1)) }}</div>
                    @else
                        <div class="brand-logo-fallback">{{ strtoupper(substr($company->name, 0, 1)) }}</div>
                    @endif
                    <div class="brand-text">
                        <span class="brand-title">{{ $company->name }}</span>
                        <div class="brand-subinfo">
                            <span class="status-dot"></span>
                            <span data-i18n="open_now" style="color:var(--teal); font-weight:700;">{{ $t['open_now'] }}</span>
                            @if ($company->qr_menu_description)
                                <span>• {{ $company->qr_menu_description }}</span>
                            @endif
                        </div>
                    </div>
                </div>

                <!-- Desktop Center Navigation Pills -->
                <nav class="desktop-nav-tabs">
                    <button class="desktop-tab-btn active" id="deskTabCatalog" onclick="switchMainTab('catalog')">
                        <i data-lucide="layout-grid" style="width:16px; height:16px;"></i> <span data-i18n="catalog">{{ $t['catalog'] }}</span>
                    </button>
                    @if ($company->is_membership_enabled)
                        <button class="desktop-tab-btn" id="deskTabMember" onclick="switchMainTab('member')">
                            <i data-lucide="credit-card" style="width:16px; height:16px;"></i> <span data-i18n="member">{{ $t['member'] }}</span>
                        </button>
                    @endif
                    @if ($company->is_reservation_enabled)
                        <button class="desktop-tab-btn" id="deskTabReservation" onclick="switchMainTab('reservation')">
                            <i data-lucide="calendar-check" style="width:16px; height:16px;"></i> <span data-i18n="reservation">{{ $t['reservation'] }}</span>
                        </button>
                    @endif
                </nav>

                <!-- Right Actions -->
                <div class="navbar-actions">
                    <!-- Language Switcher Pill -->
                    <div class="lang-pill-wrap">
                        <button type="button" class="lang-pill {{ $lang == 'id' ? 'active' : '' }}" id="langBtnId" onclick="switchLanguage('id')">
                            <span>🇮🇩</span> ID
                        </button>
                        <button type="button" class="lang-pill {{ $lang == 'en' ? 'active' : '' }}" id="langBtnEn" onclick="switchLanguage('en')">
                            <span>🇬🇧</span> EN
                        </button>
                    </div>

                    <!-- Share Button -->
                    <button type="button" onclick="sharePortal()" class="action-icon-btn">
                        <i data-lucide="share-2" style="width:14px; height:14px;"></i>
                        <span data-i18n="share">{{ $t['share'] }}</span>
                    </button>
                </div>
            </div>
        </header>

        <!-- COMPACT SUB-HEADER STRIP -->
        <div class="store-sub-bar">
            <div class="store-sub-inner">
                <div class="sub-bar-left">
                    @if ($company->code)
                        <span class="tag-pill tag-pill-neutral">Code: {{ $company->code }}</span>
                    @endif
                    @if ($company->is_membership_enabled && $company->default_member_discount_percent > 0)
                        <span class="tag-pill tag-pill-teal">
                            <i data-lucide="sparkles" style="width:12px; height:12px;"></i>
                            {{ intval($company->default_member_discount_percent) }}% Promo Member
                        </span>
                    @endif
                    @if ($company->is_reservation_enabled)
                        <span class="tag-pill tag-pill-amber">
                            <i data-lucide="calendar" style="width:12px; height:12px;"></i>
                            Online Booking & Reservasi
                        </span>
                    @endif
                </div>

                <div class="sub-bar-right">
                    <div class="sub-stat-item">
                        <span class="sub-stat-num">{{ $products->count() }}</span>
                        <span data-i18n="items_count">{{ $t['items_count'] }}</span>
                    </div>
                    @if ($company->branches && $company->branches->count() > 0)
                    <span>•</span>
                    <div class="sub-stat-item">
                        <span class="sub-stat-num">{{ $company->branches->count() }}</span>
                        <span data-i18n="branches_count">{{ $t['branches_count'] }}</span>
                    </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- MAIN BODY WRAPPER -->
        <main class="main-content-wrapper">

            <!-- ==========================================
                 TAB 1: CATALOG, SERVICES & PRODUCTS
                 ========================================== -->
            <div id="view-catalog" class="fade-in">
                <!-- Sticky Mobile Category Filter Bar -->
                <div class="mobile-sticky-filter-wrap">
                    <div class="mobile-category-bar">
                        <button class="mobile-cat-pill active" data-cat="all" onclick="selectCategory('all', this)" data-i18n="all">{{ $t['all'] }}</button>
                        @foreach ($categories as $cat)
                            <button class="mobile-cat-pill" data-cat="{{ $cat }}" onclick="selectCategory('{{ $cat }}', this)">{{ $cat }}</button>
                        @endforeach
                    </div>
                </div>

                <div class="menu-layout-grid">
                    <!-- Sticky Desktop Category Sidebar -->
                    <aside class="category-sidebar">
                        <div class="sidebar-header-title">
                            <i data-lucide="layers" style="width:14px; height:14px;"></i>
                            <span data-i18n="categories">{{ $t['categories'] }}</span>
                        </div>
                        <ul class="category-nav-list">
                            <li>
                                <button class="category-nav-btn active" data-cat="all" onclick="selectCategory('all', this)">
                                    <span data-i18n="all">{{ $t['all'] }}</span>
                                    <span class="category-count-badge">{{ $products->count() }}</span>
                                </button>
                            </li>
                            @foreach ($categories as $cat)
                                @php $catCount = $products->where('category', $cat)->count(); @endphp
                                <li>
                                    <button class="category-nav-btn" data-cat="{{ $cat }}" onclick="selectCategory('{{ $cat }}', this)">
                                        <span>{{ $cat }}</span>
                                        <span class="category-count-badge">{{ $catCount }}</span>
                                    </button>
                                </li>
                            @endforeach
                        </ul>
                    </aside>

                    <!-- Right Product & Service Area -->
                    <section class="product-area">
                        <!-- Search Bar -->
                        <div class="search-action-bar">
                            <div class="search-input-wrap">
                                <i data-lucide="search" style="width:18px; height:18px; color:var(--text-muted); flex-shrink:0;"></i>
                                <input type="text" id="mainSearchInput" class="search-main-input" placeholder="{{ $t['search'] }}" autocomplete="off">
                            </div>
                            <button type="button" id="clearSearchBtn" class="search-clear-btn hidden" onclick="clearSearch()">
                                <i data-lucide="x" style="width:16px; height:16px;"></i>
                            </button>
                        </div>

                        <!-- Product & Service Grid -->
                        <div class="products-grid" id="productGridContainer">
                            @foreach ($products as $prod)
                                <div class="product-item-card" data-name="{{ strtolower($prod->name) }}" data-category="{{ $prod->category ?? '' }}" onclick="openProductModal({{ $prod->id }})">
                                    @if ($prod->discount_percent > 0)
                                        <div class="product-discount-tag">-{{ intval($prod->discount_percent) }}%</div>
                                    @endif
                                    
                                    <div class="product-thumb-wrap">
                                        @if ($prod->image_url)
                                            <img src="{{ $prod->image_url }}" alt="{{ $prod->name }}" class="product-thumb-img" loading="lazy" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                            <div style="display:none; width:100%; height:100%; align-items:center; justify-content:center; color:var(--text-muted); position:absolute; top:0; left:0;">
                                                <i data-lucide="package" style="width:32px; height:32px; opacity:0.3;"></i>
                                            </div>
                                        @else
                                            <div style="width:100%; height:100%; display:flex; align-items:center; justify-content:center; color:var(--text-muted); position:absolute; top:0; left:0;">
                                                <i data-lucide="package" style="width:32px; height:32px; opacity:0.3;"></i>
                                            </div>
                                        @endif
                                    </div>

                                    <div class="product-card-body">
                                        <div>
                                            @if ($prod->category)
                                                <div class="p-category-name">{{ $prod->category }}</div>
                                            @endif
                                            <h3 class="p-item-name">{{ $prod->name }}</h3>
                                        </div>

                                        <div>
                                            <div class="p-price-container">
                                                <span class="p-final-price">Rp {{ number_format($prod->price, 0, ',', '.') }}</span>
                                                @if ($prod->discount_percent > 0)
                                                    @php $orig = $prod->price / (1 - ($prod->discount_percent / 100)); @endphp
                                                    <span class="p-slash-price">Rp {{ number_format($orig, 0, ',', '.') }}</span>
                                                @endif
                                            </div>

                                            <div class="p-variant-indicator">
                                                <span>{{ $prod->variants->count() > 0 ? $prod->variants->count() . ' Pilihan Paket' : 'Standar' }}</span>
                                                <span class="p-view-btn"><span data-i18n="view_details">{{ $t['view_details'] }}</span> <i data-lucide="arrow-right" style="width:12px; height:12px;"></i></span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>

                        <!-- Empty State -->
                        <div id="noProductsFound" class="empty-state-card hidden">
                            <i data-lucide="search-x" class="empty-icon"></i>
                            <h3 class="font-bold" style="font-size:1.125rem; margin-bottom:4px;" data-i18n="empty_menu">{{ $t['empty_menu'] }}</h3>
                            <p class="text-secondary" style="font-size:0.875rem;">Coba gunakan kata kunci pencarian yang lain.</p>
                        </div>
                    </section>
                </div>
            </div>

            <!-- ==========================================
                 TAB 2: MEMBERSHIP & LOYALTY (Dual Split View)
                 ========================================== -->
            @if ($company->is_membership_enabled)
            <div id="view-member" class="fade-in hidden">
                <div class="two-col-layout">
                    <!-- Left: Sticky 3D Luxury Member Card Preview -->
                    <div class="sticky-left-box" id="luxuryCardPreviewBox">
                        <div class="luxury-member-card">
                            <div class="luxury-card-sheen"></div>
                            <div class="card-top-row">
                                <div>
                                    <div class="card-store-title">{{ $company->name }}</div>
                                    <div style="font-size:0.75rem; color:#94a3b8; margin-top:2px;">Digital VIP Membership</div>
                                </div>
                                <div class="card-vip-pill" id="cardTierBadge">MEMBER VIP</div>
                            </div>

                            <div class="card-holder-name" id="cardDisplayName">Member Name</div>
                            <div class="card-number-code" id="cardNumberDisplay">MB-0000-ZENVI</div>

                            <div class="card-stats-grid">
                                @if ($company->is_points_enabled)
                                <div class="card-stat-box" id="cardStatPointsBox">
                                    <span class="card-stat-lbl" data-i18n="points">{{ $t['points'] }}</span>
                                    <span class="card-stat-val text-teal" id="cardPointsDisplay">0</span>
                                </div>
                                @endif
                                <div class="card-stat-box">
                                    <span class="card-stat-lbl" data-i18n="discount">{{ $t['discount'] }}</span>
                                    <span class="card-stat-val" id="cardDiscountDisplay">{{ intval($company->default_member_discount_percent) }}%</span>
                                </div>
                                <div class="card-stat-box">
                                    <span class="card-stat-lbl" data-i18n="transactions">{{ $t['transactions'] }}</span>
                                    <span class="card-stat-val" id="cardTxDisplay">0x</span>
                                </div>
                            </div>
                        </div>

                        <!-- Perks Box -->
                        <div class="perks-card-box">
                            <h3 class="perks-title">
                                <i data-lucide="crown" style="width:18px; height:18px; color:var(--teal);"></i>
                                Member Privileges
                            </h3>
                            <div class="perk-item">
                                <div class="perk-icon-circle"><i data-lucide="percent" style="width:16px; height:16px;"></i></div>
                                <div class="perk-desc-wrap">
                                    <h4>Diskon Eksklusif</h4>
                                    <p>Nikmati diskon khusus member di setiap pembelian produk atau order layanan.</p>
                                </div>
                            </div>
                            @if ($company->is_points_enabled)
                            <div class="perk-item">
                                <div class="perk-icon-circle"><i data-lucide="award" style="width:16px; height:16px;"></i></div>
                                <div class="perk-desc-wrap">
                                    <h4>Poin Loyalitas & Reward</h4>
                                    <p>Kumpulkan poin di setiap transaksi (setiap kelipatan Rp {{ number_format($company->point_earning_amount ?? 1000, 0, ',', '.') }} dapat 1 Poin).</p>
                                </div>
                            </div>
                            @endif
                        </div>
                    </div>

                    <!-- Right: Tabbed Forms (Register & Check) -->
                    <div class="form-surface-card">
                        <div class="form-sub-tabs">
                            <button type="button" class="form-sub-tab-btn active" id="subBtnReg" onclick="switchMemberForm('reg')" data-i18n="register_member">{{ $t['register_member'] }}</button>
                            <button type="button" class="form-sub-tab-btn" id="subBtnChk" onclick="switchMemberForm('chk')" data-i18n="check_member">{{ $t['check_member'] }}</button>
                        </div>

                        <!-- Form Register -->
                        <div id="memberRegSection">
                            <h2 class="form-header-title" style="margin-bottom:4px;" data-i18n="register_member">{{ $t['register_member'] }}</h2>
                            <p class="text-secondary" style="font-size:0.845rem; margin-bottom:18px;" data-i18n="member_benefits">{{ $t['member_benefits'] }}</p>

                            <form id="memberRegisterForm" onsubmit="handleMemberRegister(event)">
                                <div class="form-group-block">
                                    <label class="form-field-label"><span data-i18n="name">{{ $t['name'] }}</span> <span class="req">*</span></label>
                                    <input type="text" id="m_name" class="form-input-control" placeholder="e.g. Budi Santoso" required>
                                </div>

                                <div class="form-group-block">
                                    <label class="form-field-label"><span data-i18n="phone">{{ $t['phone'] }}</span> <span class="req">*</span></label>
                                    <input type="tel" id="m_phone" class="form-input-control" placeholder="08123456789 atau 628123456789" required>
                                </div>

                                <div class="form-grid-2">
                                    <div class="form-group-block">
                                        <label class="form-field-label" data-i18n="email">{{ $t['email'] }}</label>
                                        <input type="email" id="m_email" class="form-input-control" placeholder="name@email.com">
                                    </div>
                                    <div class="form-group-block">
                                        <label class="form-field-label" data-i18n="birth_date">{{ $t['birth_date'] }}</label>
                                        <input type="date" id="m_birth_date" class="form-input-control">
                                    </div>
                                </div>

                                <div class="form-group-block">
                                    <label class="form-field-label" data-i18n="address">{{ $t['address'] }}</label>
                                    <textarea id="m_address" class="form-textarea-control" rows="2" placeholder="Alamat domisili..."></textarea>
                                </div>

                                <div class="form-group-block">
                                    <label class="form-field-label" data-i18n="notes">{{ $t['notes'] }}</label>
                                    <input type="text" id="m_notes" class="form-input-control" placeholder="Catatan tambahan">
                                </div>

                                <button type="submit" id="btnMemberRegister" class="btn-submit-action">
                                    <i data-lucide="user-plus" style="width:18px; height:18px;"></i>
                                    <span data-i18n="submit">{{ $t['submit'] }}</span>
                                </button>
                            </form>
                        </div>

                        <!-- Form Check Status -->
                        <div id="memberChkSection" class="hidden">
                            <h2 class="form-header-title" style="margin-bottom:4px;" data-i18n="check_member">{{ $t['check_member'] }}</h2>
                            <p class="text-secondary" style="font-size:0.845rem; margin-bottom:18px;" data-i18n="check_phone_hint">{{ $t['check_phone_hint'] }}</p>

                            <form id="memberCheckForm" onsubmit="handleMemberCheck(event)" style="margin-bottom: 24px;">
                                <div class="form-group-block">
                                    <label class="form-field-label"><span data-i18n="phone">{{ $t['phone'] }}</span> <span class="req">*</span></label>
                                    <div class="flex gap-2">
                                        <input type="tel" id="check_phone" class="form-input-control" placeholder="0812... / 62812..." required>
                                        <button type="submit" id="btnMemberCheck" class="btn-submit-action" style="width:auto; padding:0 20px; white-space:nowrap;">
                                            <span data-i18n="btn_check">{{ $t['btn_check'] }}</span>
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            @endif

            <!-- ==========================================
                 TAB 3: RESERVASI & BOOKING JASA / LAYANAN / MEJA
                 ========================================== -->
            @if ($company->is_reservation_enabled)
            <div id="view-reservation" class="fade-in hidden">
                <div class="two-col-layout">
                    <!-- Left: Sticky Unified Booking Summary Sidebar -->
                    <div class="sticky-left-box">
                        <div class="perks-card-box">
                            <h3 class="perks-title">
                                <i data-lucide="shield-check" style="width:20px; height:20px; color:var(--teal);"></i>
                                Keuntungan Booking Online
                            </h3>

                            <div class="perk-item">
                                <div class="perk-icon-circle"><i data-lucide="check-circle-2" style="width:16px; height:16px;"></i></div>
                                <div class="perk-desc-wrap">
                                    <h4>Konfirmasi Cepat WhatsApp</h4>
                                    <p>Detail jadwal & reservasi Anda akan langsung diverifikasi dan dikirim ke WhatsApp.</p>
                                </div>
                            </div>

                            <div class="perk-item">
                                <div class="perk-icon-circle"><i data-lucide="clock" style="width:16px; height:16px;"></i></div>
                                <div class="perk-desc-wrap">
                                    <h4>Slot Terjadwal & Bebas Antre</h4>
                                    <p>Meja atau slot kapster/teknisi/layanan siap sedia saat Anda tiba di lokasi.</p>
                                </div>
                            </div>

                            <div class="perk-item">
                                <div class="perk-icon-circle"><i data-lucide="sparkles" style="width:16px; height:16px;"></i></div>
                                <div class="perk-desc-wrap">
                                    <h4>{{ $company->is_points_enabled ? 'Poin & Promo Otomatis' : 'Promo & Diskon Member' }}</h4>
                                    <p>{{ $company->is_points_enabled ? 'Gunakan nomor yang sama untuk klaim poin reward dan promo member aktif.' : 'Gunakan nomor WhatsApp terdaftar untuk klaim diskon dan promo member aktif.' }}</p>
                                </div>
                            </div>

                            @if ($company->branches && $company->branches->count() > 0)
                            <div style="margin-top: 18px; padding-top: 16px; border-top: 1px solid var(--border-color);">
                                <div style="font-size:0.75rem; font-weight:800; text-transform:uppercase; color:var(--text-muted); margin-bottom:8px; display:flex; align-items:center; gap:4px;">
                                    <i data-lucide="map-pin" style="width:12px; height:12px;"></i>
                                    <span>Pilihan Lokasi Cabang:</span>
                                </div>
                                <div style="display:flex; flex-direction:column; gap:6px;">
                                    @foreach ($company->branches as $b)
                                        <div style="padding:8px 12px; border:1px solid var(--border-color); border-radius:var(--radius-sm); font-size:0.8125rem; font-weight:700; display:flex; align-items:center; gap:8px; background:var(--bg-page); color:var(--text-primary);">
                                            <i data-lucide="store" style="width:14px; height:14px; color:var(--teal);"></i>
                                            <span>{{ $b->name }}</span>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                            @endif
                        </div>
                    </div>

                    <!-- Right Column: Refined Grouped Booking Form -->
                    <div class="form-surface-card">
                        <div class="form-header-bar">
                            <div>
                                <h2 class="form-header-title">Formulir Booking & Reservasi</h2>
                                <p class="text-secondary" style="font-size:0.8125rem; margin-top:2px;">
                                    {{ $company->reservation_description ?: 'Lengkapi data di bawah untuk memesan jadwal kedatangan / layanan.' }}
                                </p>
                            </div>
                            <span class="form-header-badge">
                                <i data-lucide="zap" style="width:12px; height:12px;"></i>
                                Booking Instan
                            </span>
                        </div>

                        <form id="reservationSubmitForm" onsubmit="handleReservationSubmit(event)">
                            
                            <!-- Block 1: Jadwal & Lokasi -->
                            <div class="form-section-block">
                                <div class="form-section-head">
                                    <i data-lucide="calendar" style="width:14px; height:14px; color:var(--teal);"></i>
                                    <span>1. Jadwal & Lokasi Kunjungan</span>
                                </div>

                                @if ($company->branches && $company->branches->count() > 0)
                                <div class="form-group-block">
                                    <label class="form-field-label"><span data-i18n="branch">{{ $t['branch'] }}</span> <span class="req">*</span></label>
                                    <select id="r_branch_id" class="form-select-control">
                                        @foreach ($company->branches as $b)
                                            <option value="{{ $b->id }}">{{ $b->name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                @endif

                                <div class="form-grid-2">
                                    <div class="form-group-block">
                                        <label class="form-field-label"><span data-i18n="date">{{ $t['date'] }}</span> <span class="req">*</span></label>
                                        <input type="date" id="r_date" class="form-input-control" min="{{ date('Y-m-d') }}" value="{{ date('Y-m-d') }}" required>
                                    </div>
                                    <div class="form-group-block">
                                        <label class="form-field-label"><span data-i18n="time">{{ $t['time'] }}</span> <span class="req">*</span></label>
                                        <input type="time" id="r_time" class="form-input-control" value="13:00" required>
                                    </div>
                                </div>

                                <!-- Quick Time Slot Selector -->
                                <div class="time-slots-box">
                                    <span class="time-slots-label">Pilihan Jam Populer:</span>
                                    <div class="time-slots-wrap">
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('10:00', this)">10:00</button>
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('11:30', this)">11:30</button>
                                        <button type="button" class="time-slot-btn active" onclick="setTimeSlot('13:00', this)">13:00</button>
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('15:00', this)">15:00</button>
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('17:00', this)">17:00</button>
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('19:00', this)">19:00</button>
                                        <button type="button" class="time-slot-btn" onclick="setTimeSlot('20:00', this)">20:00</button>
                                    </div>
                                </div>
                            </div>

                            <!-- Block 2: Detail Tamu & Layanan -->
                            <div class="form-section-block">
                                <div class="form-section-head">
                                    <i data-lucide="clipboard-list" style="width:14px; height:14px; color:var(--teal);"></i>
                                    <span>2. Detail Layanan & Jumlah Slot</span>
                                </div>

                                <!-- Slot / Guest Stepper -->
                                <div class="form-group-block">
                                    <label class="form-field-label"><span data-i18n="people">{{ $t['people'] }}</span> <span class="req">*</span></label>
                                    <div class="guest-counter-wrapper">
                                        <div class="guest-counter-box">
                                            <button type="button" class="stepper-btn" onclick="stepGuests(-1)">-</button>
                                            <span class="stepper-num" id="guestCountNum">1</span>
                                            <button type="button" class="stepper-btn" onclick="stepGuests(1)">+</button>
                                            <input type="hidden" id="r_people" value="1">
                                        </div>
                                        <div class="preset-guest-pills">
                                            <button type="button" class="preset-pill-btn active" data-preset="1" onclick="setGuestPreset(1)">1 Orang</button>
                                            <button type="button" class="preset-pill-btn" data-preset="2" onclick="setGuestPreset(2)">2 Orang</button>
                                            <button type="button" class="preset-pill-btn" data-preset="4" onclick="setGuestPreset(4)">4 Orang</button>
                                            <button type="button" class="preset-pill-btn" data-preset="6" onclick="setGuestPreset(6)">6+ Rombongan</button>
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group-block">
                                    <label class="form-field-label" data-i18n="service_names">{{ $t['service_names'] }}</label>
                                    
                                    @if ($products && $products->count() > 0)
                                    <select class="form-select-control" style="margin-bottom: 8px;" onchange="if(this.value){ document.getElementById('r_service_names').value = this.value; }">
                                        <option value="">-- Pilih dari Daftar Produk / Layanan (Opsional) --</option>
                                        @foreach ($products as $p)
                                            <option value="{{ $p->name }}">{{ $p->name }} (Rp {{ number_format($p->price, 0, ',', '.') }})</option>
                                        @endforeach
                                    </select>
                                    @endif

                                    <input type="text" id="r_service_names" class="form-input-control" placeholder="Tulis nama layanan, paket, atau request khusus (e.g. Potong Rambut + Wash / Cuci Mobil / Meja Depan)">
                                </div>
                            </div>

                            <!-- Block 3: Kontak Pemesan -->
                            <div class="form-section-block">
                                <div class="form-section-head">
                                    <i data-lucide="user-check" style="width:14px; height:14px; color:var(--teal);"></i>
                                    <span>3. Data Pemesan</span>
                                </div>

                                <div class="form-grid-2">
                                    <div class="form-group-block">
                                        <label class="form-field-label"><span data-i18n="name">{{ $t['name'] }}</span> <span class="req">*</span></label>
                                        <input type="text" id="r_name" class="form-input-control" placeholder="e.g. Budi Santoso" required>
                                    </div>

                                    <div class="form-group-block">
                                        <label class="form-field-label"><span data-i18n="phone">{{ $t['phone'] }}</span> <span class="req">*</span></label>
                                        <input type="tel" id="r_phone" class="form-input-control" placeholder="08123456789 atau 628123456789" required>
                                    </div>
                                </div>

                                <div class="form-group-block">
                                    <label class="form-field-label" data-i18n="special_requests">{{ $t['special_requests'] }}</label>
                                    <textarea id="r_notes" class="form-textarea-control" rows="2" placeholder="Catatan tambahan (misal: preferensi kapster/staf, nomor plat kendaraan, smoking area, dll)"></textarea>
                                </div>
                            </div>

                            <button type="submit" id="btnReservationSubmit" class="btn-submit-action">
                                <i data-lucide="calendar-check" style="width:18px; height:18px;"></i>
                                <span data-i18n="submit">Konfirmasi & Kirim Booking</span>
                            </button>
                            <div class="submit-helper-note">
                                🔒 Data Anda aman. Konfirmasi reservasi akan dikirimkan langsung via WhatsApp.
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            @endif

        </main>

        <!-- 5. MOBILE FLOATING STICKY BOTTOM NAVIGATION BAR -->
        <nav class="mobile-bottom-nav">
            <div class="mobile-nav-inner">
                <button type="button" class="mobile-nav-item active" id="mobTabCatalog" onclick="switchMainTab('catalog')">
                    <i data-lucide="layout-grid" style="width:18px; height:18px;"></i>
                    <span data-i18n="catalog">{{ $t['catalog'] }}</span>
                </button>
                @if ($company->is_membership_enabled)
                    <button type="button" class="mobile-nav-item" id="mobTabMember" onclick="switchMainTab('member')">
                        <i data-lucide="credit-card" style="width:18px; height:18px;"></i>
                        <span data-i18n="member">{{ $t['member'] }}</span>
                    </button>
                @endif
                @if ($company->is_reservation_enabled)
                    <button type="button" class="mobile-nav-item" id="mobTabReservation" onclick="switchMainTab('reservation')">
                        <i data-lucide="calendar-check" style="width:18px; height:18px;"></i>
                        <span data-i18n="reservation">{{ $t['reservation'] }}</span>
                    </button>
                @endif
            </div>
        </nav>

    </div>

    <!-- PRODUCT / SERVICE DETAIL MODAL / BOTTOM SHEET -->
    <div class="modal-overlay-custom" id="productModal" onclick="closeProductModal()">
        <div class="modal-dialog-box" onclick="event.stopPropagation()">
            <button class="modal-close-trigger" onclick="closeProductModal()">
                <i data-lucide="x" style="width:18px; height:18px;"></i>
            </button>
            <div id="productModalContent"></div>
        </div>
    </div>

    <script>
        lucide.createIcons();

        // Multilingual Dictionary
        const i18n = {
            id: {
                share: 'Bagikan',
                copied: 'Tautan toko berhasil disalin!',
                catalog: 'Katalog & Layanan',
                member: 'Member',
                reservation: 'Reservasi & Booking',
                search: 'Cari menu, produk, atau layanan...',
                all: 'Semua',
                empty_menu: 'Tidak ada produk atau layanan yang sesuai pencarian.',
                register_member: 'Daftar Member',
                check_member: 'Cek Status Member',
                member_promos: 'Promo Member',
                member_benefits: 'Dapatkan poin belanja/layanan, diskon khusus member, dan penawaran spesial.',
                name: 'Nama Lengkap',
                phone: 'Nomor WhatsApp',
                email: 'Email (Opsional)',
                birth_date: 'Tanggal Lahir (Opsional)',
                address: 'Alamat (Opsional)',
                notes: 'Catatan (Opsional)',
                submit: 'Konfirmasi & Kirim Booking',
                submitting: 'Menyimpan...',
                sending: 'Mengirim Booking...',
                check_phone_hint: 'Masukkan nomor WhatsApp Anda untuk melihat kartu member digital & poin.',
                btn_check: 'Cari Member',
                points: 'Poin',
                discount: 'Diskon',
                transactions: 'Transaksi',
                active: 'Aktif VIP',
                book_table: 'Reservasi & Booking Online',
                book_table_desc: 'Pesan meja, booking jadwal salon/barbershop, servis kendaraan, atau perawatan tanpa harus antre.',
                branch: 'Pilih Cabang',
                date: 'Tanggal Kedatangan / Reservasi',
                time: 'Waktu / Jam Kedatangan',
                people: 'Jumlah Tamu / Slot Layanan (Orang)',
                service_names: 'Pilihan Layanan, Paket Jasa, atau Menu',
                special_requests: 'Catatan Khusus (Preferensi staf/barber, meja VIP, tipe kendaraan, dll)',
                variants: 'Pilihan Paket / Varian',
                open_now: 'Buka Sekarang',
                categories: 'Kategori',
                items_count: 'item & jasa',
                branches_count: 'Cabang',
                view_details: 'Lihat Detail',
                book_now_btn: 'Booking Layanan Ini',
                success: 'Berhasil!',
                error: 'Gagal!',
                conn_error: 'Terjadi gangguan koneksi. Silakan coba lagi.'
            },
            en: {
                share: 'Share',
                copied: 'Store link copied to clipboard!',
                catalog: 'Catalog & Services',
                member: 'Membership',
                reservation: 'Booking / Reservation',
                search: 'Search items, products or services...',
                all: 'All',
                empty_menu: 'No products or services match your search.',
                register_member: 'Register Member',
                check_member: 'Check Member Status',
                member_promos: 'Member Promos',
                member_benefits: 'Earn reward points, member discounts, and exclusive seasonal promotions.',
                name: 'Full Name',
                phone: 'WhatsApp Number',
                email: 'Email (Optional)',
                birth_date: 'Birth Date (Optional)',
                address: 'Address (Optional)',
                notes: 'Notes (Optional)',
                submit: 'Confirm & Send Booking',
                submitting: 'Saving...',
                sending: 'Sending Booking...',
                check_phone_hint: 'Enter your registered WhatsApp number to display your digital member card.',
                btn_check: 'Check Member',
                points: 'Points',
                discount: 'Discount',
                transactions: 'Transactions',
                active: 'Active VIP',
                book_table: 'Online Booking & Reservation',
                book_table_desc: 'Book a table, schedule barbershop/salon services, car wash, or service appointments with ease.',
                branch: 'Select Branch',
                date: 'Booking / Arrival Date',
                time: 'Time / Slot',
                people: 'Guests / Service Slots (People)',
                service_names: 'Desired Service, Package, or Menu',
                special_requests: 'Special Notes (Barber preference, VIP Table, etc)',
                variants: 'Package / Variant Options',
                open_now: 'Open Now',
                categories: 'Categories',
                items_count: 'items',
                branches_count: 'Branches',
                view_details: 'Details',
                book_now_btn: 'Book This Service',
                success: 'Success!',
                error: 'Error!',
                conn_error: 'Connection error. Please try again.'
            }
        };

        let currentLang = localStorage.getItem('zenvi_lang') || "{{ $lang }}";

        function switchLanguage(lang) {
            currentLang = lang;
            localStorage.setItem('zenvi_lang', lang);

            const btnId = document.getElementById('langBtnId');
            const btnEn = document.getElementById('langBtnEn');
            if (btnId && btnEn) {
                btnId.classList.toggle('active', lang === 'id');
                btnEn.classList.toggle('active', lang === 'en');
            }

            const dict = i18n[lang] || i18n.id;

            document.querySelectorAll('[data-i18n]').forEach(el => {
                const key = el.getAttribute('data-i18n');
                if (dict[key]) el.textContent = dict[key];
            });

            const searchInput = document.getElementById('mainSearchInput');
            if (searchInput) searchInput.placeholder = dict.search;

            lucide.createIcons();
        }

        if (currentLang !== "{{ $lang }}") {
            switchLanguage(currentLang);
        }

        // Data from backend
        const products = @json($products);
        const storeSlug = @json($company->slug ?: ($company->code ?: 'store'));
        
        // Exact root relative endpoints
        const routes = {
            memberRegister: '/public/members/' + encodeURIComponent(storeSlug),
            memberCheck: '/public/members/' + encodeURIComponent(storeSlug) + '/check',
            reservationSubmit: '/public/reservations/' + encodeURIComponent(storeSlug)
        };

        // Navigation Tabs (Synchronized Desktop & Mobile)
        function switchMainTab(tabName) {
            ['catalog', 'member', 'reservation'].forEach(name => {
                const view = document.getElementById('view-' + name);
                if (view) view.classList.add('hidden');

                const deskBtn = document.getElementById('deskTab' + capitalize(name));
                if (deskBtn) deskBtn.classList.remove('active');

                const mobBtn = document.getElementById('mobTab' + capitalize(name));
                if (mobBtn) mobBtn.classList.remove('active');
            });

            const targetView = document.getElementById('view-' + tabName);
            if (targetView) targetView.classList.remove('hidden');

            const activeDesk = document.getElementById('deskTab' + capitalize(tabName));
            if (activeDesk) activeDesk.classList.add('active');

            const activeMob = document.getElementById('mobTab' + capitalize(tabName));
            if (activeMob) activeMob.classList.add('active');

            window.scrollTo({ top: 0, behavior: 'smooth' });
            lucide.createIcons();
        }

        function capitalize(s) {
            return s.charAt(0).toUpperCase() + s.slice(1);
        }

        // Category Filtering
        let activeCat = 'all';
        function selectCategory(cat, el) {
            activeCat = cat;

            document.querySelectorAll('.category-nav-btn').forEach(btn => {
                btn.classList.toggle('active', btn.getAttribute('data-cat') === cat);
            });
            document.querySelectorAll('.mobile-cat-pill').forEach(pill => {
                pill.classList.toggle('active', pill.getAttribute('data-cat') === cat);
            });

            filterProducts();
        }

        // Search & Filter
        const mainSearchInput = document.getElementById('mainSearchInput');
        const clearSearchBtn = document.getElementById('clearSearchBtn');
        const productItems = document.querySelectorAll('.product-item-card');
        const noProductsFound = document.getElementById('noProductsFound');

        if (mainSearchInput) {
            mainSearchInput.addEventListener('input', () => {
                if (clearSearchBtn) {
                    clearSearchBtn.classList.toggle('hidden', mainSearchInput.value.length === 0);
                }
                filterProducts();
            });
        }

        function clearSearch() {
            if (mainSearchInput) {
                mainSearchInput.value = '';
                clearSearchBtn.classList.add('hidden');
                filterProducts();
            }
        }

        function filterProducts() {
            const query = mainSearchInput ? mainSearchInput.value.toLowerCase().trim() : '';
            let matchCount = 0;

            productItems.forEach(card => {
                const name = (card.getAttribute('data-name') || '').toLowerCase();
                const category = card.getAttribute('data-category') || '';

                const matchesQuery = name.includes(query);
                const matchesCategory = activeCat === 'all' || category === activeCat;

                if (matchesQuery && matchesCategory) {
                    card.style.display = 'flex';
                    matchCount++;
                } else {
                    card.style.display = 'none';
                }
            });

            if (noProductsFound) {
                noProductsFound.classList.toggle('hidden', matchCount > 0);
            }
        }

        // Product & Service Modal
        let selectedProduct = null;
        let selectedVariantPrice = 0;

        function openProductModal(productId) {
            selectedProduct = products.find(p => p.id === productId);
            if (!selectedProduct) return;
            selectedVariantPrice = 0;

            const dict = i18n[currentLang] || i18n.id;
            const basePrice = parseInt(selectedProduct.price || 0);

            let variantsHtml = '';
            if (selectedProduct.variants && selectedProduct.variants.length > 0) {
                variantsHtml = `
                    <div style="margin-top:16px; padding-top:14px; border-top:1px solid var(--border-color);">
                        <h4 class="font-bold" style="font-size:0.875rem; margin-bottom:8px;">${dict.variants}:</h4>
                        <div class="variant-radio-group">
                            <div class="variant-radio-item selected" onclick="chooseVariant(0, this)">
                                <span class="font-bold" style="font-size:0.8125rem;">Standar / Reguler</span>
                                <span class="font-extrabold text-teal" style="font-size:0.8125rem;">+Rp 0</span>
                            </div>
                            ${selectedProduct.variants.map(v => `
                                <div class="variant-radio-item" onclick="chooseVariant(${parseInt(v.price || 0)}, this)">
                                    <span class="font-bold" style="font-size:0.8125rem;">${v.name}</span>
                                    <span class="font-extrabold text-teal" style="font-size:0.8125rem;">+Rp ${parseInt(v.price || 0).toLocaleString('id-ID')}</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `;
            }

            const html = `
                <div>
                    ${selectedProduct.image_url ? `
                        <div style="position:relative; width:100%; padding-top:60%; border-radius:var(--radius-lg); overflow:hidden; margin-bottom:14px; background:var(--primary-light);">
                            <img src="${selectedProduct.image_url}" alt="${selectedProduct.name}" style="position:absolute; top:0; left:0; width:100%; height:100%; object-fit:cover;" onerror="this.style.display='none';">
                        </div>
                    ` : ''}
                    
                    ${selectedProduct.category ? `<div class="p-category-name" style="margin-bottom:4px;">${selectedProduct.category}</div>` : ''}
                    <h2 class="font-extrabold" style="font-size:1.2rem; line-height:1.3; color:var(--text-primary); margin-bottom:4px; word-break:break-word;">${selectedProduct.name}</h2>
                    
                    <div style="display:flex; align-items:baseline; gap:8px; margin-bottom:12px;">
                        <span class="font-extrabold" id="modalFinalPrice" style="font-size:1.35rem; color:var(--teal);">Rp ${basePrice.toLocaleString('id-ID')}</span>
                    </div>

                    ${selectedProduct.description ? `
                        <p class="text-secondary" style="font-size:0.875rem; line-height:1.55; margin-bottom:14px;">${selectedProduct.description}</p>
                    ` : ''}

                    ${variantsHtml}

                    @if ($company->is_reservation_enabled)
                    <div style="margin-top:20px; padding-top:16px; border-top:1px solid var(--border-color);">
                        <button type="button" class="btn-submit-action" onclick="bookThisItem('${selectedProduct.name.replace(/'/g, "\\'")}')">
                            <i data-lucide="calendar" style="width:18px; height:18px;"></i>
                            <span>${dict.book_now_btn}</span>
                        </button>
                    </div>
                    @endif
                </div>
            `;

            document.getElementById('productModalContent').innerHTML = html;
            document.getElementById('productModal').classList.add('active');
            lucide.createIcons();
        }

        function chooseVariant(extraPrice, element) {
            selectedVariantPrice = extraPrice;
            document.querySelectorAll('.variant-radio-item').forEach(el => el.classList.remove('selected'));
            element.classList.add('selected');

            if (selectedProduct) {
                const total = parseInt(selectedProduct.price || 0) + selectedVariantPrice;
                const priceEl = document.getElementById('modalFinalPrice');
                if (priceEl) priceEl.textContent = 'Rp ' + total.toLocaleString('id-ID');
            }
        }

        function bookThisItem(itemName) {
            closeProductModal();
            switchMainTab('reservation');
            const svcInput = document.getElementById('r_service_names');
            if (svcInput) {
                svcInput.value = itemName;
                svcInput.focus();
            }
        }

        function closeProductModal() {
            document.getElementById('productModal').classList.remove('active');
        }

        // Stepper Guest / Slot Counter
        let guestCount = 1;
        function stepGuests(delta) {
            guestCount = Math.max(1, Math.min(100, guestCount + delta));
            updateGuestUI();
        }

        function setGuestPreset(num) {
            guestCount = num;
            updateGuestUI();
        }

        function updateGuestUI() {
            document.getElementById('guestCountNum').textContent = guestCount;
            document.getElementById('r_people').value = guestCount;

            document.querySelectorAll('.preset-pill-btn').forEach(btn => {
                const val = parseInt(btn.getAttribute('data-preset') || '0');
                if (val === 6) {
                    btn.classList.toggle('active', guestCount >= 6);
                } else {
                    btn.classList.toggle('active', guestCount === val);
                }
            });
        }

        // Quick Time Slot Selector
        function setTimeSlot(timeStr, btn) {
            document.querySelectorAll('.time-slot-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const timeInput = document.getElementById('r_time');
            if (timeInput) timeInput.value = timeStr;
        }

        // Member Sub-Form Switcher
        function switchMemberForm(type) {
            const regBox = document.getElementById('memberRegSection');
            const chkBox = document.getElementById('memberChkSection');
            const btnReg = document.getElementById('subBtnReg');
            const btnChk = document.getElementById('subBtnChk');

            if (type === 'reg') {
                regBox.classList.remove('hidden');
                chkBox.classList.add('hidden');
                btnReg.classList.add('active');
                btnChk.classList.remove('active');
            } else {
                regBox.classList.add('hidden');
                chkBox.classList.remove('hidden');
                btnReg.classList.remove('active');
                btnChk.classList.add('active');
            }
            lucide.createIcons();
        }

        // Share Function
        function sharePortal() {
            const dict = i18n[currentLang] || i18n.id;
            if (navigator.share) {
                navigator.share({
                    title: "{{ $company->name }}",
                    url: window.location.href
                }).catch(() => {});
            } else {
                navigator.clipboard.writeText(window.location.href);
                Swal.fire({
                    toast: true,
                    position: 'top',
                    icon: 'success',
                    title: dict.copied,
                    showConfirmButton: false,
                    timer: 2000
                });
            }
        }

        // Handle Member Registration
        async function handleMemberRegister(e) {
            e.preventDefault();
            const dict = i18n[currentLang] || i18n.id;
            const btn = document.getElementById('btnMemberRegister');
            btn.disabled = true;
            btn.innerHTML = `<i data-lucide="loader-2" class="spin" style="width:18px; height:18px;"></i> ${dict.submitting}`;
            lucide.createIcons();

            const payload = {
                name: document.getElementById('m_name').value.trim(),
                phone: document.getElementById('m_phone').value.trim(),
                email: document.getElementById('m_email').value.trim() || null,
                birth_date: document.getElementById('m_birth_date').value || null,
                address: document.getElementById('m_address').value.trim() || null,
                notes: document.getElementById('m_notes').value.trim() || null,
            };

            try {
                const res = await fetch(routes.memberRegister, {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json', 
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}'
                    },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();

                if (res.ok) {
                    if (data.data) {
                        if (document.getElementById('cardDisplayName')) document.getElementById('cardDisplayName').textContent = data.data.name;
                        if (document.getElementById('cardNumberDisplay')) document.getElementById('cardNumberDisplay').textContent = data.data.member_code;
                        if (document.getElementById('cardPointsDisplay')) document.getElementById('cardPointsDisplay').textContent = data.data.points || '0';
                    }
                    Swal.fire({
                        icon: 'success',
                        title: dict.success,
                        text: data.message,
                        confirmButtonColor: '#0d9488'
                    });
                    document.getElementById('memberRegisterForm').reset();
                    
                    const previewBox = document.getElementById('luxuryCardPreviewBox');
                    if (previewBox) previewBox.scrollIntoView({ behavior: 'smooth' });
                } else {
                    Swal.fire({
                        icon: 'error',
                        title: dict.error,
                        text: data.message || 'Gagal mendaftarkan member.',
                        confirmButtonColor: '#0f172a'
                    });
                }
            } catch (err) {
                console.error('Member register error:', err);
                Swal.fire({ icon: 'error', title: dict.error, text: dict.conn_error });
            } finally {
                btn.disabled = false;
                btn.innerHTML = `<i data-lucide="user-plus" style="width:18px; height:18px;"></i> <span>${dict.submit}</span>`;
                lucide.createIcons();
            }
        }

        // Handle Member Card Check
        async function handleMemberCheck(e) {
            e.preventDefault();
            const dict = i18n[currentLang] || i18n.id;
            const phone = document.getElementById('check_phone').value.trim();
            const btn = document.getElementById('btnMemberCheck');
            btn.disabled = true;
            btn.innerHTML = `...`;

            try {
                const fetchUrl = `${routes.memberCheck}?phone=${encodeURIComponent(phone)}`;

                const res = await fetch(fetchUrl, {
                    headers: { 
                        'Accept': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                });

                let data;
                try {
                    data = await res.json();
                } catch(parseErr) {
                    console.error('Non-JSON response:', parseErr);
                    Swal.fire({ icon: 'error', title: dict.error, text: dict.conn_error });
                    return;
                }

                if (res.ok && data.data) {
                    const m = data.data;
                    if (document.getElementById('cardDisplayName')) document.getElementById('cardDisplayName').textContent = m.name || '-';
                    if (document.getElementById('cardNumberDisplay')) document.getElementById('cardNumberDisplay').textContent = m.member_code || 'MB-0000';
                    if (document.getElementById('cardPointsDisplay')) document.getElementById('cardPointsDisplay').textContent = (m.points || 0).toLocaleString('id-ID');
                    if (document.getElementById('cardDiscountDisplay')) document.getElementById('cardDiscountDisplay').textContent = (m.custom_discount_percent || (data.company ? data.company.default_discount : 0) || 0) + '%';
                    if (document.getElementById('cardTxDisplay')) document.getElementById('cardTxDisplay').textContent = (m.total_transactions || 0) + 'x';
                    
                    Swal.fire({
                        toast: true,
                        position: 'top',
                        icon: 'success',
                        title: 'Kartu Member Ditemukan! 🎉',
                        showConfirmButton: false,
                        timer: 2500
                    });

                    const previewBox = document.getElementById('luxuryCardPreviewBox');
                    if (previewBox) previewBox.scrollIntoView({ behavior: 'smooth' });
                } else {
                    Swal.fire({
                        icon: 'info',
                        title: 'Member Belum Terdaftar',
                        text: data.message || 'Nomor WhatsApp belum terdaftar sebagai member di toko ini.',
                        confirmButtonColor: '#0d9488'
                    });
                }
            } catch (err) {
                console.error('Member check error:', err);
                Swal.fire({ icon: 'error', title: dict.error, text: dict.conn_error });
            } finally {
                btn.disabled = false;
                btn.innerHTML = `<span>${dict.btn_check}</span>`;
            }
        }

        // Handle Reservation Submit
        async function handleReservationSubmit(e) {
            e.preventDefault();
            const dict = i18n[currentLang] || i18n.id;
            const btn = document.getElementById('btnReservationSubmit');
            btn.disabled = true;
            btn.innerHTML = `<i data-lucide="loader-2" class="spin" style="width:18px; height:18px;"></i> ${dict.sending}`;
            lucide.createIcons();

            const branchEl = document.getElementById('r_branch_id');
            const payload = {
                customer_name: document.getElementById('r_name').value.trim(),
                customer_phone: document.getElementById('r_phone').value.trim(),
                reservation_date: document.getElementById('r_date').value,
                reservation_time: document.getElementById('r_time').value,
                number_of_people: parseInt(document.getElementById('r_people').value) || 1,
                service_names: document.getElementById('r_service_names').value.trim() || null,
                notes: document.getElementById('r_notes').value.trim() || null,
                branch_id: branchEl ? branchEl.value : null,
            };

            try {
                const res = await fetch(routes.reservationSubmit, {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json', 
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}'
                    },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();

                if (res.ok) {
                    Swal.fire({
                        icon: 'success',
                        title: dict.success,
                        text: data.message || 'Reservasi Anda telah berhasil dikirim!',
                        confirmButtonColor: '#0d9488'
                    });
                    document.getElementById('reservationSubmitForm').reset();
                    setGuestPreset(1, document.querySelector('.preset-pill-btn'));
                } else {
                    Swal.fire({
                        icon: 'error',
                        title: dict.error,
                        text: data.message || 'Gagal mengirim reservasi.',
                        confirmButtonColor: '#0f172a'
                    });
                }
            } catch (err) {
                Swal.fire({ icon: 'error', title: dict.error, text: dict.conn_error });
            } finally {
                btn.disabled = false;
                btn.innerHTML = `<i data-lucide="calendar-check" style="width:18px; height:18px;"></i> <span>${dict.submit}</span>`;
                lucide.createIcons();
            }
        }
    </script>
    @endif
</body>
</html>
