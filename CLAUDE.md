# Zenvi — Aturan Pengembangan

Seluruh isi aturan ada di **[AGENTS.md](AGENTS.md)**.

Berkas ini sengaja dibuat pendek. `AGENTS.md` adalah nama yang dibaca agent
coding di luar Claude Code (Gemini Antigravity, Gemini CLI, Codex, Cursor,
dsb), sedangkan `CLAUDE.md` dibaca Claude Code. Isinya disatukan di satu
berkas supaya tidak ada beberapa salinan aturan yang bisa melenceng
diam-diam — kalau ada beberapa, salah satu pasti basi dan tidak ada yang
memberi tahu.

@AGENTS.md

> **Kalau baris `@AGENTS.md` di atas tidak otomatis memuat isinya, buka dan
> baca `AGENTS.md` sekarang juga sebelum menulis kode apa pun di repo ini.**
> Di sana ada aturan yang tidak boleh ditebak: deploy wajib ke Hostinger
> beserta jebakan `config:cache`/`route:cache` (§1), larangan teks hardcoded
> & sinkronisasi kunci i18n (§3), commit otomatis (§4), dan aturan delegasi
> agent beserta pembagian modelnya (§5).

**Semua perubahan aturan ditulis di `AGENTS.md`, bukan di berkas ini.**

Berkas pendamping:

- `RENCANA_LANGGANAN.md` — desain paket langganan & gating.
- `zenvi-antigravity-blueprint.md` — blueprint arsitektur.
- `.agents/rules/flutter_ui_guidelines.md` — panduan UI Flutter.
