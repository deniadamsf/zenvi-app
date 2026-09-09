<?php

namespace Tests\Unit;

use App\Support\ShiftSchedule;
use Carbon\Carbon;
use Tests\TestCase;

class ShiftScheduleTest extends TestCase
{
    private const PAGI = ['name' => 'Shift Pagi', 'start' => '08:00', 'end' => '16:00'];
    private const SORE = ['name' => 'Shift Sore', 'start' => '16:00', 'end' => '23:00'];
    private const MALAM = ['name' => 'Shift Malam', 'start' => '22:00', 'end' => '06:00'];

    /** Absen masuk pada jam dinding WIB, disimpan sebagaimana aslinya: UTC. */
    private function absen(string $wib): Carbon
    {
        return Carbon::parse($wib, 'Asia/Jakarta')->setTimezone('UTC');
    }

    public function test_jam_wib_dibandingkan_sebagai_jam_wib_bukan_utc(): void
    {
        // Inti bugnya: `start_time` tersimpan UTC, sedangkan "08:00" yang
        // diketik owner adalah WIB. Dibandingkan mentah-mentah, absen 08:30 WIB
        // terbaca 01:30 UTC dan tidak pernah dianggap telat - itulah kenapa
        // seluruh baris di laporan absensi tertulis "tepat waktu".
        $match = ShiftSchedule::match($this->absen('2026-09-09 08:30'), [self::PAGI], 0);

        $this->assertTrue($match['is_late']);
        $this->assertSame(30, $match['late_minutes']);
        $this->assertSame('Shift Pagi', $match['name']);
    }

    public function test_datang_sebelum_jadwal_tidak_telat(): void
    {
        $match = ShiftSchedule::match($this->absen('2026-09-09 07:50'), [self::PAGI], 0);

        $this->assertFalse($match['is_late']);
        $this->assertSame(0, $match['late_minutes']);
    }

    public function test_toleransi_keterlambatan_dihormati(): void
    {
        $schedules = [self::PAGI];

        $masihToleransi = ShiftSchedule::match($this->absen('2026-09-09 08:10'), $schedules, 15);
        $this->assertFalse($masihToleransi['is_late']);

        $lewatToleransi = ShiftSchedule::match($this->absen('2026-09-09 08:20'), $schedules, 15);
        $this->assertTrue($lewatToleransi['is_late']);
        // Menitnya dihitung dari jadwal, bukan dari batas toleransi: telat 20
        // menit tetap 20 menit walau 15 menit pertamanya dimaafkan.
        $this->assertSame(20, $lewatToleransi['late_minutes']);
    }

    public function test_telat_parah_shift_pagi_tidak_dianggap_datang_awal_shift_sore(): void
    {
        // Dulu jadwal dipilih berdasar selisih jam terkecil secara mutlak, jadi
        // absen 12:30 lebih dekat ke 16:00 (210 menit) daripada ke 08:00 (270
        // menit) - dan orang yang telat 4,5 jam tercatat "tepat waktu".
        $match = ShiftSchedule::match($this->absen('2026-09-09 12:30'), [self::PAGI, self::SORE], 0);

        $this->assertSame('Shift Pagi', $match['name']);
        $this->assertTrue($match['is_late']);
        $this->assertSame(270, $match['late_minutes']);
    }

    public function test_datang_sedikit_lebih_awal_untuk_shift_sore_masuk_shift_sore(): void
    {
        // Sisi sebaliknya, dan sama pentingnya: yang datang 10 menit sebelum
        // shift sore tidak boleh dihukum sebagai telat 7 jam 50 menit untuk
        // shift pagi.
        $match = ShiftSchedule::match($this->absen('2026-09-09 15:50'), [self::PAGI, self::SORE], 0);

        $this->assertSame('Shift Sore', $match['name']);
        $this->assertFalse($match['is_late']);
    }

    public function test_telat_pada_shift_sore_dihitung_terhadap_shift_sore(): void
    {
        $match = ShiftSchedule::match($this->absen('2026-09-09 16:25'), [self::PAGI, self::SORE], 0);

        $this->assertSame('Shift Sore', $match['name']);
        $this->assertTrue($match['is_late']);
        $this->assertSame(25, $match['late_minutes']);
    }

    public function test_urutan_jadwal_tidak_mempengaruhi_hasil(): void
    {
        $a = ShiftSchedule::match($this->absen('2026-09-09 16:25'), [self::PAGI, self::SORE], 0);
        $b = ShiftSchedule::match($this->absen('2026-09-09 16:25'), [self::SORE, self::PAGI], 0);

        $this->assertSame($a['name'], $b['name']);
        $this->assertSame($a['late_minutes'], $b['late_minutes']);
    }

    public function test_shift_lewat_tengah_malam_dinilai_terhadap_jadwal_kemarin(): void
    {
        // Absen 01:00 untuk shift 22:00 adalah telat 3 jam, bukan datang 7 jam
        // lebih awal untuk shift pagi.
        $match = ShiftSchedule::match($this->absen('2026-09-10 01:00'), [self::PAGI, self::MALAM], 0);

        $this->assertSame('Shift Malam', $match['name']);
        $this->assertTrue($match['is_late']);
        $this->assertSame(180, $match['late_minutes']);
    }

    public function test_jam_selesai_shift_lewat_tengah_malam_jatuh_di_hari_berikutnya(): void
    {
        $match = ShiftSchedule::match($this->absen('2026-09-09 22:05'), [self::MALAM], 0);

        $this->assertSame('Shift Malam', $match['name']);
        $this->assertSame('2026-09-09 22:00', $match['scheduled_start']->format('Y-m-d H:i'));
        $this->assertSame('2026-09-10 06:00', $match['scheduled_end']->format('Y-m-d H:i'));
    }

    public function test_datang_jauh_sebelum_shift_paling_pagi_tidak_dianggap_telat(): void
    {
        // Di luar jangkauan toleransi awal mana pun. Yang jelas, orang yang
        // datang kepagian bukan orang yang telat.
        $match = ShiftSchedule::match($this->absen('2026-09-09 04:00'), [self::PAGI, self::SORE], 0);

        $this->assertSame('Shift Pagi', $match['name']);
        $this->assertFalse($match['is_late']);
    }

    public function test_tanpa_jadwal_tidak_ada_penilaian_keterlambatan(): void
    {
        foreach ([[], null, 'bukan array'] as $kosong) {
            $match = ShiftSchedule::match($this->absen('2026-09-09 10:00'), $kosong, 0);

            $this->assertFalse($match['is_late']);
            $this->assertNull($match['name']);
            $this->assertNull($match['scheduled_start']);
        }
    }

    public function test_jadwal_cacat_dilewati_bukan_menggagalkan_seluruh_penilaian(): void
    {
        $schedules = [['name' => 'Tanpa Jam'], self::PAGI, 'bukan array'];

        $match = ShiftSchedule::match($this->absen('2026-09-09 08:30'), $schedules, 0);

        $this->assertSame('Shift Pagi', $match['name']);
        $this->assertSame(30, $match['late_minutes']);
    }

    public function test_keterlambatan_kurang_dari_semenit_tetap_tercatat_telat(): void
    {
        $match = ShiftSchedule::match($this->absen('2026-09-09 08:00:40'), [self::PAGI], 0);

        $this->assertTrue($match['is_late']);
        $this->assertSame(1, $match['late_minutes']);
    }
}
