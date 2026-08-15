# Flutter UI & Design System Guidelines for Zenvi

Panduan ini wajib diikuti oleh seluruh agen (termasuk agen *frontend* maupun sub-agen) saat membuat atau merombak UI di proyek Flutter Zenvi. Panduan ini dibuat untuk memastikan konsistensi desain yang modern, bersih, dan premium di seluruh aplikasi.

## 1. Tipografi & Warna (Design System)
- **Font Utama**: Wajib menggunakan **Outfit** (via `google_fonts`). Jangan gunakan font *default* sistem atau Roboto.
- **Hierarki Teks**:
  - `Display/Headline`: Gunakan font dengan *weight* tebal (`FontWeight.w800` atau `w900`) dan *letter-spacing* sedikit negatif (misal: `-0.5` hingga `-1.0`) untuk memberi kesan premium dan padat.
  - `Body/Label`: Gunakan `colorScheme.onSurface` atau `colorScheme.onSurfaceVariant` dengan ukuran yang wajar (11px - 14px) dan *weight* medium/semi-bold (`w500` - `w600`).
- **Skema Warna**:
  - Hindari penggunaan warna "pelangi" atau terlalu banyak warna kustom secara *hardcoded* (seperti `Colors.red`, `Colors.green`, `Colors.amber` yang bercampur aduk).
  - Sebagai gantinya, wajib gunakan **`theme.colorScheme.primary`** untuk elemen aktif, ikon navigasi, *quick actions*, dan metrik.
  - Untuk aksen positif/negatif (seperti Keuntungan vs Pengeluaran), gunakan *opacity* atau warna turunan dari `colorScheme` alih-alih warna neon yang mencolok.

## 2. Layout & Ruang (Spacing)
- **Hindari Horizontal Scroll Berlebih**: Komponen seperti filter, menu, atau metrik tidak boleh memakan ruang horizontal yang memicu *scroll* tak terhingga.
  - *Solusi*: Gunakan tata letak **Grid** (`Wrap` atau `GridView`) agar semua elemen dapat terlihat langsung di layar.
- **White-space (Napas Layout)**: Berikan `padding` dan `margin` yang cukup besar (16px, 20px, atau 24px) antar komponen. Jangan biarkan elemen UI terlihat padat atau "berantakan".
- **Glassmorphism & Shadows**:
  - Kartu (*Cards*) wajib memiliki bayangan super halus: `BoxShadow(color: theme.shadowColor.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))`.
  - Gunakan `borderRadius` yang melengkung elegan (misalnya `16` atau `24`).
  - Untuk *container* ikon, beri latar belakang tembus pandang dari warna ikon tersebut (contoh: `color.withValues(alpha: 0.12)`).

## 3. Komponen Spesifik
- **Bottom Navigation**: Wajib berbentuk *Floating Pill / Glassmorphism* (melayang di atas layar, tidak menempel penuh di tepi bawah) dengan efek animasi pergantian (menggunakan `AnimatedSwitcher` atau `flutter_animate`).
- **KPI / Metric Cards**: Harus menggunakan desain kartu yang bersih. Angka utama harus menjadi fokus (ukuran besar, tebal), didampingi *badge* kecil berlatar transparan untuk detail sekunder. Hindari *border* tebal.
- **Analytics / Chart**: Jangan sembunyikan informasi penting di dalam *slider* (*PageView*) jika tidak perlu. Gunakan tata letak vertikal (Mobile) atau Grid (Desktop) agar semua data metrik terbaca tanpa interaksi ekstra.

## 4. Efek Layout Lanjutan (Advanced Layouts)
- **Background Utama Bersih**: Jangan gunakan warna gradasi (`LinearGradient`) yang kompleks pada latar belakang (background utama) aplikasi. Gunakan warna solid bawaan (misal `theme.scaffoldBackgroundColor` atau `theme.colorScheme.surface`) agar tampilan terlihat profesional, tidak terlalu *ramai*, dan menonjolkan konten di atasnya.
- **Sticky Header (Glassmorphism)**: 
  - Header utama di *dashboard* harus bersifat *sticky* (menempel di atas saat discroll).
  - Gunakan arsitektur `CustomScrollView` dengan `SliverPersistentHeader` atau `SliverAppBar`.
  - Berikan efek tembus pandang (*glassmorphism*) pada header: `ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(color: theme.colorScheme.surface.withValues(alpha: 0.8))))`.
- **Scroll Menembus Navigasi Bawah**:
  - Saat menggunakan navigasi bawah yang melayang (menggunakan `extendBody: true` pada `Scaffold`), pastikan daftar konten (*ListView* atau *CustomScrollView*) bisa digulir (*scroll*) menembus ke bagian belakang dari navigasi tersebut.
  - Caranya: matikan proteksi batas bawah dengan membungkus daftar menggunakan `SafeArea(bottom: false, child: ...)`, dan berikan _padding_ bawah statis yang cukup besar pada daftar (contoh: `bottom: 120`) agar item terakhir tetap bisa dijangkau/diklik dengan baik.
