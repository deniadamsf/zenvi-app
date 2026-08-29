<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // $schedule->command('inspire')->hourly();
        $schedule->command('shift:delete-old-selfies')->daily();

        // Penanda scheduler hidup.
        //
        // Cron di Hostinger hanya bisa diatur lewat hPanel dan pernah gagal
        // diam-diam (perintah `cd ... &&` yang batal tanpa jejak), sehingga
        // seluruh task terjadwal mati tanpa ada yang tahu. File ini ditulis
        // tiap menit; kesegarannya bisa dicek kapan saja:
        //
        //   stat -c '%y' storage/framework/scheduler_last_run
        //
        // Basi lebih dari beberapa menit = cron mati.
        $schedule->call(function () {
            file_put_contents(
                storage_path('framework/scheduler_last_run'),
                now()->toDateTimeString() . PHP_EOL
            );
        })->everyMinute();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
