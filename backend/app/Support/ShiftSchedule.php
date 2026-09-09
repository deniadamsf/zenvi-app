<?php

namespace App\Support;

use Carbon\Carbon;
use Carbon\CarbonInterface;

/**
 * Mencocokkan jam absen masuk dengan jadwal shift yang disetel owner.
 *
 * Dulu logika ini ditulis dua kali - di ShiftController (badge telat pada Log
 * Shift) dan di EmployeePerformanceController (performa & absensi) - dengan
 * hasil yang bisa berbeda untuk shift yang sama. Disatukan di sini supaya satu
 * shift tidak pernah dinilai dua macam.
 */
class ShiftSchedule
{
    /**
     * Seberapa awal seseorang boleh dianggap sedang masuk untuk sebuah shift.
     *
     * Datang 10 menit sebelum shift sore jelas masuk untuk shift sore. Datang 6
     * jam sebelumnya bukan - itu orang yang telat parah untuk shift pagi.
     * Batas inilah yang memisahkan keduanya.
     */
    public const EARLY_GRACE_MINUTES = 120;

    public static function businessTimezone(): string
    {
        return config('zenvi.business_timezone', 'Asia/Jakarta');
    }

    /**
     * Tentukan shift mana yang sedang dimasuki, dan seberapa telat.
     *
     * @param  mixed  $schedules  Isi Company::shift_schedules — array of
     *                            ['name' => ?string, 'start' => 'HH:MM', 'end' => 'HH:MM'].
     * @return array{
     *     name: ?string,
     *     is_late: bool,
     *     late_minutes: int,
     *     scheduled_start: ?Carbon,
     *     scheduled_end: ?Carbon
     * }
     */
    public static function match(CarbonInterface $startedAt, $schedules, int $toleranceMinutes): array
    {
        $none = [
            'name' => null,
            'is_late' => false,
            'late_minutes' => 0,
            'scheduled_start' => null,
            'scheduled_end' => null,
        ];

        if (!is_array($schedules) || empty($schedules)) {
            return $none;
        }

        $tz = self::businessTimezone();

        // Jam absen dibaca sebagai jam dinding setempat dulu. Tanggal untuk
        // menyusun jadwal harus datang dari sini, bukan dari timestamp UTC-nya:
        // absen 00:30 WIB masih tanggal kemarin kalau dilihat dalam UTC.
        $local = $startedAt->copy()->setTimezone($tz);

        /** @var array<int, array{start: Carbon, schedule: array}> $candidates */
        $candidates = [];
        $earliestToday = null;

        foreach ($schedules as $schedule) {
            if (!is_array($schedule) || empty($schedule['start'])) {
                continue;
            }

            // Hari kemarin ikut dipertimbangkan demi shift yang melewati tengah
            // malam: absen 01:00 untuk shift 22:00 adalah telat 3 jam, bukan
            // datang kepagian untuk shift pagi.
            foreach ([0, -1] as $dayOffset) {
                $schedStart = self::atDate($local, $schedule['start'], $tz)->addDays($dayOffset);

                if ($dayOffset === 0 && ($earliestToday === null || $schedStart->lessThan($earliestToday['start']))) {
                    $earliestToday = ['start' => $schedStart->copy(), 'schedule' => $schedule];
                }

                // Jadwal kemarin hanya masuk hitungan kalau shiftnya memang
                // BELUM berakhir. Tanpa syarat ini, shift sore kemarin yang
                // sudah tutup jam 23:00 ikut menangkap absen jam 4 pagi ini
                // dan mencatatnya telat 12 jam.
                if ($dayOffset === -1) {
                    $schedEnd = self::scheduledEnd($schedStart, $schedule, $tz);
                    if ($schedEnd === null || $local->greaterThanOrEqualTo($schedEnd)) {
                        continue;
                    }
                }

                if ($local->greaterThanOrEqualTo($schedStart->copy()->subMinutes(self::EARLY_GRACE_MINUTES))) {
                    $candidates[] = ['start' => $schedStart, 'schedule' => $schedule];
                }
            }
        }

        // Di antara shift yang masuk akal sedang dia mulai, ambil yang PALING
        // BARU. Dulu yang diambil adalah jadwal dengan selisih jam terkecil
        // secara mutlak, sehingga jadwal yang belum datang pun ikut dipilih:
        // absen 12:30 untuk shift 08:00 & 16:00 dinilai "datang 3,5 jam lebih
        // awal untuk shift sore", padahal itu telat 4,5 jam untuk shift pagi.
        $best = null;
        foreach ($candidates as $candidate) {
            if ($best === null || $candidate['start']->greaterThan($best['start'])) {
                $best = $candidate;
            }
        }

        // Datang jauh sebelum shift paling pagi: tidak ada yang cocok, dan itu
        // bukan keterlambatan. Disandarkan ke jadwal paling pagi hari itu.
        $best ??= $earliestToday;

        if ($best === null) {
            return $none;
        }

        $schedStart = $best['start'];
        $isLate = $local->greaterThan($schedStart->copy()->addMinutes($toleranceMinutes));

        return [
            'name' => isset($best['schedule']['name']) && $best['schedule']['name'] !== ''
                ? (string) $best['schedule']['name']
                : null,
            'is_late' => $isLate,
            // max(1) supaya keterlambatan yang dibulatkan ke bawah jadi 0 menit
            // tidak tampil sebagai "telat 0 menit" yang membingungkan.
            'late_minutes' => $isLate ? max(1, (int) $local->diffInMinutes($schedStart)) : 0,
            'scheduled_start' => $schedStart,
            'scheduled_end' => self::scheduledEnd($schedStart, $best['schedule'], $tz),
        ];
    }

    private static function atDate(CarbonInterface $local, string $clock, string $tz): Carbon
    {
        return Carbon::parse($local->format('Y-m-d') . ' ' . $clock, $tz);
    }

    private static function scheduledEnd(Carbon $schedStart, array $schedule, string $tz): ?Carbon
    {
        if (empty($schedule['end'])) {
            return null;
        }

        $end = Carbon::parse($schedStart->format('Y-m-d') . ' ' . $schedule['end'], $tz);

        // Shift yang melewati tengah malam (mis. 22:00 - 06:00) berakhir besok.
        if ($end->lessThanOrEqualTo($schedStart)) {
            $end->addDay();
        }

        return $end;
    }
}
